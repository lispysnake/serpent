/*
 * This file is part of serpent.
 *
 * Copyright © 2019-2020 Lispy Snake, Ltd.
 *
 * This software is provided 'as-is', without any express or implied
 * warranty. In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 */

module serpent.core.entitymanager;

import serpent.core.archetype;
import serpent.core.entity;
import serpent.core.component;
import serpent.core.componentmanifest;
import serpent.core.greedyarray;
import serpent.core.signature;
import serpent.core.storage;
import serpent.core.view;

import std.exception : enforce;
import std.string : format;

import core.sync.mutex : Mutex;

/**
 * The EntityManager is responsible for an entire 'world view'. It is where
 * all entities are created and manipulated, along with managing the component
 * and archetype storage.
 *
 * Components must be registered with the EntityManager to preallocate the
 * storage capacity. The system is flexible allowing an unspecified number
 * of components. However, it makes sense to keep component numbers lower to
 * help with more explicit taxonomy of entities through the composed
 * archetypes. This in turn helps with performance.
 *
 * To get started with the EntityManager, register some components with it
 * and then manipulate it via the View APIs.
 */
final class EntityManager
{

private:

    GreedyArray!ComponentManifest _components;
    int minSize = 0; /* Minimum entity count */
    int maxSize = 0; /* Maximum entity count */

    EntityID _lastID = 0;
    shared Mutex idMutex;

    /* We store everything into an archetype. Potentially turn into array */
    Archetype*[] archetypes;

    /* When assigning new components from a view, stage values here for copy */
    Archetype* stagingArchetype;

    /* Stash of removals */
    ComponentRemoval[] removalRequests;
    shared Mutex removalMutex;

    /* Stash of additions */
    EntityID[] assignmentRequests;
    shared Mutex assignmentMutex;
    EntityID lastStaged = 0;

    /* Freeing entities */
    EntityID[] freeIDs;
    EntityID[] killRequests;
    shared Mutex killMutex;
    bool _built = false;

private:

    /**
     * Compute archetype for the given Entity
     */
    final Signature computeSignature(EntityID id) @safe nothrow
    {
        import std.range;
        import std.algorithm;

        /* Sort by highest indexes to allow implicit grouping of similar buckets */
        auto components = _components.data.filter!(a => a.joined(id)).array()
            .sort!((a, b) => (a.index > b.index))
            .map!((a) => a.index)();

        return Signature(components.array);
    }

    /**
     * Return an array of manifest instances
     */
    final ComponentManifest*[] computeManifests(in ref Signature s) @trusted nothrow
    {
        import std.algorithm;
        import std.range;

        return s.components
            .filter!((a) => a != 0)
            .map!((a) => &_components[a - 1])
            .array();
    }

    /**
     * Construct the staging archetype where we copy from
     */
    final void constructStagingArchetype() @trusted
    {
        import std.algorithm;
        import std.range;

        auto components = _components.data.array().sort!((a, b) => (a.index > b.index))
            .map!((a) => a.index)();
        auto signature = Signature(components.array);
        import std.stdio;

        stagingArchetype = new Archetype(signature, computeManifests(signature));
    }

    /**
     * Update the archetype for the given entity.
     */
    final void updateArchetype(EntityID id, bool allowNewArchetype = true, bool killData = false) @trusted
    {
        auto newSignature = computeSignature(id);
        Archetype* oldArchetype = null;
        Archetype* newArchetype = null;

        foreach (ref archetype; archetypes)
        {
            if (archetype.hasEntity(id))
            {
                oldArchetype = archetype;
            }
            else if (allowNewArchetype && archetype.satisfiesEntity(newSignature))
            {
                newArchetype = archetype;
            }
        }

        /* Nothing to do - still compatible. */
        if (oldArchetype !is null && oldArchetype.satisfiesEntity(newSignature))
        {
            return;
        }

        /* Got a new archetype to create */
        if (newArchetype is null && allowNewArchetype)
        {
            auto manifests = computeManifests(newSignature);
            auto archetype = new Archetype(newSignature, manifests);
            archetypes ~= archetype;
            newArchetype = archetype;
        }

        /* Take across from staging, never drop staging. */
        if (stagingArchetype.hasEntity(id))
        {
            if (newArchetype !is null)
            {
                newArchetype.takeEntity(id, stagingArchetype);
            }
            stagingArchetype.dropEntity(id, killData);
            return;
        }

        /* Take on the new entity now, copying data */
        if (newArchetype !is null)
        {
            newArchetype.takeEntity(id, oldArchetype);
        }

        if (oldArchetype is null)
        {
            return;
        }

        /* Drop from old archetype, losing data */
        oldArchetype.dropEntity(id, killData);

        if (!oldArchetype.empty())
        {
            return;
        }

        import std.algorithm.mutation : remove;

        archetypes = archetypes.remove!(a => a == oldArchetype);
        oldArchetype.close();
        oldArchetype.destroy();

    }

    /**
     * Find parent archetpye of an entity
     *
     * May be NULL for new entities.
     */
    final Archetype* findArchetype(EntityID ent) @trusted
    {
        foreach (ref arche; archetypes)
        {
            if (arche.hasEntity(ent))
            {
                return arche;
            }
        }
        return null;
    }

    /**
     * Update components in batch.
     */
    final void setComponents(C...)(EntityID ent) @safe
    {
        foreach (c; C)
        {
            static assert(isValidComponent!c);
            static assert(!is(C == EntityIdentifier), "Cannot manually register EntityIdentifier");
            assert(isRegistered!c, "setComponents: Unknown component %s".format(c.stringof));
            auto idx = getComponentID!c - 1;
            _components[idx].join(ent);
            assert(_components[idx].joined(ent));
        }

        setInternalComponent(ent);
        updateArchetype(ent);
    }

    final void setInternalComponent(EntityID ent) @safe nothrow
    {
        /* Register for EntityID. The Archetype is responsible for cloning this */
        auto idx = getComponentID!EntityIdentifier - 1;
        _components[idx].join(ent);
        assert(_components[idx].joined(ent));
    }

    /**
     * Verify that a component has been registered
     */
    final bool isRegisteredInternal(ulong index) @safe nothrow
    {
        auto idx = index - 1;
        if (idx > _components.count || _components.count < 1)
        {
            return false;
        }
        return _components[idx].alive;
    }

    /**
     * Perform any component removal required.
     */
    final void processComponentRemovals() @safe
    {
        scope (exit)
        {
            removalMutex.unlock_nothrow();
        }

        removalMutex.lock_nothrow();

        import std.algorithm;

        if (removalRequests.length < 1)
        {
            return;
        }

        sort!((a, b) => a.entityID < b.entityID)(removalRequests);
        EntityID curEntity = removalRequests[0].entityID;
        EntityID lastEntity = 0;

        /**
         * This helper flushes the changes and assigns the archetype
         * only once all component removals have been completed.
         */
        void flushEntityComponentRemoval(EntityID id)
        {
            if (id == lastEntity)
            {
                return;
            }
            updateArchetype(id, true, true);
            lastEntity = id;
        }

        /* Unjoin individual components */
        void doEntityComponentRemoval(ComponentRemoval* removal)
        {
            assert(isRegisteredInternal(removal.componentID),
                    "removeComponent: Unknown component %d".format(removal.componentID));
            auto idx = removal.componentID - 1;
            assert(_components[idx].joined(removal.entityID),
                    "removeComponent: Entity not joined to %d".format(removal.componentID));
            _components[idx].unjoin(removal.entityID);
        }

        /**
         * Step through all removal requests, flush when entity ID changes
         * This help minimize the reconstruction of archetypes as much as
         * possible until fluctuations stop.
         */
        foreach (i; 0 .. removalRequests.length)
        {
            auto item = &removalRequests[i];
            if (item.entityID != curEntity)
            {
                flushEntityComponentRemoval(curEntity);
                curEntity = item.entityID;
            }
            doEntityComponentRemoval(item);
        }
        flushEntityComponentRemoval(curEntity);

        /* all done */
        removalRequests = [];
    }

    /**
     * Perform any component assignment required
     */
    final void processComponentAssignments() @safe
    {
        scope (exit)
        {
            assignmentMutex.unlock_nothrow();
        }

        assignmentMutex.lock_nothrow();

        foreach (ref id; assignmentRequests)
        {
            updateArchetype(id);
        }

        if (lastStaged != 0)
        {
            updateArchetype(lastStaged);
            lastStaged = 0;
        }

        assignmentRequests = [];
    }

    /**
     * Process any kills
     */
    final void processEntityKills() @safe
    {
        scope (exit)
        {
            killMutex.unlock_nothrow();
            idMutex.unlock_nothrow();
        }

        killMutex.lock_nothrow();
        idMutex.lock_nothrow();

        /* Remove from all archetypes + components */
        foreach (kill; killRequests)
        {
            /* Unregister from all manifests */
            foreach (ref manifest; _components.data)
            {
                manifest.unjoin(kill);
            }

            updateArchetype(kill, false, true);

            freeIDs ~= kill;
        }

        /* Reset kill list */
        killRequests = [];
    }

public:

    /**
     * Construct a new EntityManager
     */
    this()
    {
        /* Empty component array */
        _components = GreedyArray!ComponentManifest(0, 0);

        /* Reserve the EntityIdentifier */
        registerComponent!EntityIdentifier;

        /* TODO: Atomically increment the new ID? */
        idMutex = new shared Mutex();

        /* Mutability issues */
        removalMutex = new shared Mutex();
        assignmentMutex = new shared Mutex();

        /* Killing */
        killMutex = new shared Mutex();
    }

    /**
     * Destroy the engine
     */
    ~this()
    {
        clear();
    }

    /**
     * Internal factory
     */
    final EntityID createInternal() @safe
    {
        /* Ensure we're built before giving out entity IDs */
        if (!_built)
        {
            build();
        }

        /* Attempt to recycle old ID first */
        if (freeIDs.length > 0)
        {
            import std.algorithm.mutation : remove;

            auto freeID = freeIDs[0];
            freeIDs = freeIDs.remove!(a => a == freeID);
            return freeID;
        }

        return ++_lastID;
    }

    /**
     * Create a new entity with no components
     */
    final EntityID create() @safe
    {
        scope (exit)
        {
            idMutex.unlock_nothrow();
        }
        idMutex.lock_nothrow();

        auto e = createInternal();
        setInternalComponent(e);

        /* We used to allocate an EntityIdentifier archetype for
         * componentless entities but that massively impacted
         * performance.
         */
        //updateArchetype(e);
        return e;
    }

    /**
     * Create a new entity with explicit components
     * It will automatically be shifted into an appropriate archetype
     */
    final EntityID createWithComponents(C...)() @safe
    {
        scope (exit)
        {
            idMutex.unlock_nothrow();
        }
        idMutex.lock_nothrow();

        auto e = createInternal();
        setInternalComponent(e);
        setComponents!C(e);
        updateArchetype(e);
        return e;
    }

    /**
     * Kill a previously known entity
     */
    final void kill(EntityID entity) @safe nothrow
    {
        scope (exit)
        {
            killMutex.unlock_nothrow();
        }
        killMutex.lock_nothrow();

        killRequests ~= entity;
    }

    /**
     * Must be called before the EntityManager is usable, i.e. all registrations
     * have completed.
     */
    final void build() @safe
    {
        scope (exit)
        {
            removalMutex.unlock_nothrow();
            assignmentMutex.unlock_nothrow();
            idMutex.unlock_nothrow();
        }

        removalMutex.lock_nothrow();
        assignmentMutex.lock_nothrow();
        idMutex.lock_nothrow();

        if (_built)
        {
            return;
        }
        constructStagingArchetype();
        _built = true;
    }

    /**
     * Return true if this EntityManager has been built
     */
    final pure @property bool built() @safe @nogc nothrow
    {
        return _built;
    }

    /**
     * Perform one step of the engine
     */
    final void step() @safe
    {
        assert(_built == true, "Cannot use EntityManager before it is built");
        processComponentRemovals();
        processComponentAssignments();
        processEntityKills();
    }

    /**
     * Attempt to register the component if not already registered
     */
    final void tryRegisterComponent(C)() @safe
    {
        static assert(isValidComponent!C);
        if (isRegistered!C)
        {
            return;
        }
        registerComponent!C;
    }

    /**
     * Attempt to register the component
     *
     * This is important so that we have sufficient storage ahead of time
     * for entities within components.
     */
    final void registerComponent(C)() @safe
    {
        static assert(isValidComponent!C);
        assert(!isRegistered!C, "Cannot re-register component %s".format(C.stringof));
        assert(!built, "Cannot register component with built EntityManager");
        auto idx = getComponentID!C - 1;

        /* Sort out the component */
        _components[idx] = ComponentManifest(idx + 1, C.stringof, minSize, maxSize);
        auto alloc = new PoolAllocator!C(minSize, maxSize);
        _components[idx].pool!C = alloc;
        _components[idx].allocateChunk = &_components[idx].pool!C.allocateChunk;

        /**
         * Internal helper for inserting a row
         */
        void* insertHelper(void* blob, out ulong idx) @trusted nothrow
        {
            auto realBlob = cast(StorageChunk!C*) blob;
            return realBlob.insertRow(idx);
        }

        /* Clone from one archetype to another */
        void cloneHelper(void* source, ulong sourceIndex, void* target, ulong targetIndex) @trusted nothrow
        {
            StorageChunk!C* sourceBlob = cast(StorageChunk!C*) source;
            StorageChunk!C* targetBlob = cast(StorageChunk!C*) target;
            targetBlob.buffer[targetIndex] = sourceBlob.buffer[sourceIndex];
        }

        /* Remove from an archetype */
        void removeHelper(void* source, ulong index, bool killData) @trusted
        {
            StorageChunk!C* blob = cast(StorageChunk!C*) source;
            serpentComponent tag = getComponentUDA!C;
            if (killData && tag.deallocate !is null)
            {
                tag.deallocate(&blob.buffer[index]);
            }
            blob.removeRow(index);
        }

        /* Deallocate underlying data */
        void deallocateHelper(void* chunk, bool killData) @trusted
        {
            StorageChunk!C* blob = cast(StorageChunk!C*) chunk;
            serpentComponent tag = getComponentUDA!C;

            if (killData && tag.deallocate !is null)
            {
                foreach (idx; 0 .. blob.numElements)
                {
                    tag.deallocate(&blob.buffer[idx]);
                }
            }

            _components[idx].pool!C.deallocateChunk(blob);
        }

        _components[idx].deallocateChunk = &deallocateHelper;
        _components[idx].cloneRow = &cloneHelper;
        _components[idx].insertRow = &insertHelper;
        _components[idx].removeRow = &removeHelper;
        _components[idx].maxElements = StorageChunk!C.maxElements;
        _components[idx].alive = true;
    }

    /**
     * Add a component to the entity with default data
     * Return a pointer to the component
     */
    final C* addComponent(C)(EntityID ent) @safe
    {
        return addComponent!C(ent, C.init);
    }

    /**
     * Add a component to entity with data by value
     * Return a pointer to the component
     */
    final C* addComponent(C)(EntityID ent, C data) @safe
    {
        return addComponent!C(ent, data);
    }

    /**
     * Add a component to entity with data by reference
     * Return a pointer to the component
     */
    final C* addComponent(C)(EntityID ent, ref C data) @safe
    {
        static assert(isValidComponent!C);
        assert(isRegistered!C, "addComponent: Unknown component %s".format(C.stringof));

        auto idx = getComponentID!C - 1;
        _components[idx].join(ent);
        assert(_components[idx].joined(ent));

        updateArchetype(ent);

        C* datum = dataRW!C(ent);
        *datum = data;
        return datum;
    }

    /**
     * Remove a component from the given entity
     */
    final void removeComponent(C)(EntityID ent) @safe
    {
        static assert(isValidComponent!C);
        static assert(!(is(C == EntityIdentifier)), "Cannot remove EntityIdentifier component");
        assert(isRegistered!C, "removeComponent: Unknown component %s".format(C.stringof));
        assert(built, "Can only remove component from built EntityManager");

        auto idx = getComponentID!C - 1;
        _components[idx].unjoin(ent);
        updateArchetype(ent, true, true);
    }

    /**
     * Return true if the entity has the component
     */
    final bool hasComponent(C)(EntityID ent) @safe nothrow
    {
        static assert(isValidComponent!C);
        auto idx = getComponentID!C - 1;
        return _components[idx].joined(ent);
    }

    /**
     * Verify that a component has been registered
     */
    pragma(inline, true) final bool isRegistered(C)() @safe nothrow
    {
        static assert(isValidComponent!C);
        return isRegisteredInternal(getComponentID!C);
    }

    /**
     * Return all matching entities as a tuple of (ent, C...) whose
     * components contain at least all of those in C.
     *
     * This is a read-write query.
     */
    final auto withComponentsRW(C...)() @safe
    {
        static assert(C.length <= 5,
                "withComponentsRW: Maximum of 5 components supported in signature");
        static assert(C.length > 0,
                "withComponentsRW: Minimum of 1 component required in signature");
        assert(_built == true, "Cannot use EntityManager before it is built");
        ulong[C.length] indices = 0;
        static foreach (i, c; C)
        {
            static assert(isValidComponent!c);
            assert(isRegistered!c, "withComponentsRW: Unknown component %s".format(c.stringof));
            indices[i] = getComponentID!c;
        }
        auto sig = Signature(indices);
        import std.algorithm;
        import std.range : chain;

        return archetypes.filter!((a) => a.satisfies(sig))
            .map!((b) => b.rangedRW!C())
            .joiner();
    }

    /**
     * Return all matching entities as a tuple of (ent, C...) whose
     * components contain at least all of those in C.
     *
     * This is a read-only query.
     */
    final auto withComponentsRO(C...)() @safe
    {
        static assert(C.length <= 5,
                "withComponentsRO: Maximum of 5 components supported in signature");
        static assert(C.length > 0,
                "withComponentsRO: Minimum of 1 component required in signature");
        assert(_built == true, "Cannot use EntityManager before it is built");
        ulong[C.length] indices = 0;
        static foreach (i, c; C)
        {
            static assert(isValidComponent!c);
            assert(isRegistered!c, "withComponentsRO: Unknown component %s".format(c.stringof));
            indices[i] = getComponentID!c;
        }
        auto sig = Signature(indices);
        import std.algorithm;
        import std.range : chain;

        return archetypes.filter!((a) => a.satisfies(sig))
            .map!((b) => b.rangedRO!C())
            .joiner();
    }

    /**
     * Return a set of ranges across all matching chunks and archetypes
     * which internally are composed of tuples containing (ent, C...)
     *
     * This allows for parallel processing in chunks to match the internal
     * system layout.
     *
     * This is a read-write query.
     */
    final auto withComponentsChunkedRW(C...)() @safe
    {
        static assert(C.length <= 5,
                "withComponentsRW: Maximum of 5 components supported in signature");
        static assert(C.length > 0,
                "withComponentsRW: Minimum of 1 component required in signature");
        assert(_built == true, "Cannot use EntityManager before it is built");
        ulong[C.length] indices = 0;
        static foreach (i, c; C)
        {
            static assert(isValidComponent!c);
            assert(isRegistered!c, "withComponentsRW: Unknown component %s".format(c.stringof));
            indices[i] = getComponentID!c;
        }
        auto sig = Signature(indices);
        import std.algorithm;
        import std.range : chain;

        return archetypes.filter!((a) => a.satisfies(sig))
            .map!((b) => b.chunkRangedRW!C())
            .joiner();
    }

    /**
     * Return a set of ranges across all matching chunks and archetypes
     * which internally are composed of tuples containing (ent, C...)
     *
     * This allows for parallel processing in chunks to match the internal
     * system layout.
     *
     * This is a read-only query.
     */
    final auto withComponentsChunkedRO(C...)() @safe
    {
        static assert(C.length <= 5,
                "withComponentsRO: Maximum of 5 components supported in signature");
        static assert(C.length > 0,
                "withComponentsRO: Minimum of 1 component required in signature");
        assert(_built == true, "Cannot use EntityManager before it is built");
        ulong[C.length] indices = 0;
        static foreach (i, c; C)
        {
            static assert(isValidComponent!c);
            assert(isRegistered!c, "withComponentsRO: Unknown component %s".format(c.stringof));
            indices[i] = getComponentID!c;
        }
        auto sig = Signature(indices);
        import std.algorithm;
        import std.range : chain;

        return archetypes.filter!((a) => a.satisfies(sig))
            .map!((b) => b.chunkRangedRO!C())
            .joiner();
    }

    /**
     * Get read-write version of the data.
     */
    final C* dataRW(C)(EntityID id) @safe
    {
        assert(isRegistered!C, "Unknown component %s".format(C.stringof));
        assert(_built == true, "Cannot use EntityManager before it is built");

        auto idx = getComponentID!C - 1;
        auto comp = _components[idx];
        assert(hasComponent!C(id),
                "getComponentData: Entity %d not registered with %s".format(id, C.stringof));

        auto archetype = findArchetype(id);
        return archetype.getChunkedComponentData!C(comp, id);
    }

    /**
     * Return read-only copy of the data
     */
    final const(C*) dataRO(C)(EntityID id) @safe
    {
        return cast(const C*) dataRW!C(id);
    }

    /**
     * Completely reset the world, deallocating all archetypes and
     * entities.
     */
    final void clear() @safe
    {
        scope (exit)
        {
            removalMutex.unlock_nothrow();
            assignmentMutex.unlock_nothrow();
            idMutex.unlock_nothrow();
        }

        removalMutex.lock_nothrow();
        assignmentMutex.lock_nothrow();
        idMutex.lock_nothrow();

        foreach (ref archetype; archetypes)
        {
            archetype.close(true);
            archetype.destroy();
        }
        archetypes = [];
        removalRequests = [];
        assignmentRequests = [];
        killRequests = [];
        lastStaged = 0;
        _lastID = 0;
        freeIDs = [];

        stagingArchetype.close(true);
        stagingArchetype.destroy();

        constructStagingArchetype();

        foreach (ref manifest; _components.data)
        {
            manifest.clear();
        }
        _built = false;
    }

package:

    /**
     * Helpers for the View API
     */

    final void pushComponentRemoval(ComponentRemoval removal) @safe
    {
        scope (exit)
        {
            removalMutex.unlock_nothrow();
        }

        removalMutex.lock_nothrow();
        removalRequests ~= removal;
    }

    /**
     * Stage a copy of the entity into staging archetype, and assign new
     * component data to it.
     *
     * On the next execution frame, the archetype of the entity will be
     * updated.
     *
     * Due to this nature, we must lock to ensure we get the right copy.
     */
    final void stageComponentAssignment(C)(EntityID id, ref C datum) @safe
    {
        static assert(isValidComponent!C);
        assert(isRegistered!C, "addComponent: Unknown component %s".format(C.stringof));

        scope (exit)
        {
            assignmentMutex.unlock_nothrow();
        }

        assignmentMutex.lock_nothrow();

        import std.stdio;

        auto idx = getComponentID!C - 1;
        auto comp = _components[idx];
        assert(!_components[idx].joined(id),
                "Already registered to component %s".format(C.stringof));
        _components[idx].join(id);

        /* Flush last staged component assignments */
        if (id != lastStaged && lastStaged != 0)
        {
            assignmentRequests ~= lastStaged;
        }
        lastStaged = id;

        /* Put it into staging. Should probably cache archetype too */
        if (!stagingArchetype.hasEntity(id))
        {
            stagingArchetype.takeEntity(id, findArchetype(id));
        }

        stagingArchetype.setChunkedComponentData!C(comp, id, datum);
    }
}
