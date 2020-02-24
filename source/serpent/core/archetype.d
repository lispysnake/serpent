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

module serpent.core.archetype;

import std.algorithm.mutation : copy;
import serpent.core.component;
import serpent.core.componentmanifest;
import serpent.core.greedyarray;
import serpent.core.entity;
import serpent.core.storage;
import serpent.core.page;

public import serpent.core.signature;

/**
 * Used to cache entity lookups. Until invalidated, we keep a
 * mapping of an entity ID to a Page + row. Anytime we invalidate
 * through destruction, we drop the cache.
 *
 * This means that an insert will create a binding, which can then be
 * used to quickly find an entity prior to invalidation. Subsequent
 * lookups will check if the binding is in the map and use it.
 *
 * If the binding is not present, we'll manually find the entity and
 * reassign the binding.
 *
 * Each time an entity is deleted, we must invalidate the whole cache
 * as indices may have moved.
 */
package final struct EntityLocation
{
    ulong rowIndex = 0; /* Index within page */
    Page* page; /* Page of storage */
}

/**
 * An archetype is a logical grouping of entities through their components.
 * This allows us to perform queries on entities through group matching,
 * as we know all entities in each archetype have exactly the same set
 * of components.
 *
 * An archetype can be considered a table in the relational database
 * design. Internally it is composed of pages (abstraction around
 * chunks) that all have the same 'columns' (component datums)
 *
 * An entity may only live in one archetype, but components may exist
 * in multiple archetypes. This means matching on the EntityManager
 * may return ranges across multiple page chunks and archetypes to
 * ensure a valid full set for the world state.
 */
final struct Archetype
{
private:

    ulong[] matchComponents;
    ulong[ulong] componentReverse;
    ulong numEntities = 0;
    GreedyBitArray entities;
    ComponentManifest*[] manifests;
    EntityLocation[EntityID] locations;

    Page* _page = null;

    /* We need pages.*/
    Page*[] pages;

package:

    /**
     * Construct a new Archetype from the given ComponentManifest
     * indices.
     */
    this(ulong[] indices, ComponentManifest*[] manifests) @safe
    {
        matchComponents = indices;

        entities = GreedyBitArray(0, 0);
        this.manifests = manifests;
        assert(manifests !is null);
        assert(manifests.length > 0);

        /* Reverse lookup of component IDs to our buckets. Uses memory but optimises lookups. */
        foreach (i, ref m; manifests)
        {
            componentReverse[m.index] = i;
        }
    }

    this(Signature signature, ComponentManifest*[] manifests) @safe
    {
        this(signature.components, manifests);
    }

    @disable this();

    /**
     * Returns true if the signature is satisfied by this archetype
     */
    pure final bool satisfies(in Signature s) @safe @nogc nothrow
    {
        for (size_t i = 0; i < s.length; i++)
        {

            bool found = false;

            ulong their = s.components[i];
            if (their == 0)
            {
                continue;
            }
            for (size_t j = 0; j < matchComponents.length; j++)
            {
                if (their == matchComponents[j])
                {
                    found = true;
                    break;
                }
            }
            if (!found)
            {
                return false;
            }
        }
        return true;
    }

    /**
     * The component signature must exactly match this archetype, as
     * we only do 1:1 mapping across many archetypes.
     */
    pure final bool satisfiesEntity(in Signature s) @safe @nogc nothrow
    {
        return matchComponents == s.components;
    }

    /**
     * Return true if we own the given entity.
     */
    final bool hasEntity(EntityID id) @trusted nothrow
    {
        if (id >= entities.count)
        {
            return false;
        }
        return entities[id];
    }

    /**
     * Take ownership of an entity and copy all of the chunked
     * component data
     */
    final void takeEntity(EntityID id, Archetype* originalArchetype) @trusted
    {
        ++numEntities;
        entities[id] = true;

        ulong ourIndex = 0;

        /*Page full? new page. */
        if (_page is null || _page.full())
        {
            _page = createPage();
            pages ~= _page;
        }

        assert(!_page.full(), "Page is full");

        /* Construction of new archetype */
        foreach (ref manifest; manifests)
        {
            /* Insert a row for this entity, cloning the entity ID */
            auto blob = manifest.insertRow(_page.chunks[componentReverse[manifest.index]],
                    ourIndex);
            if (manifest.index() == getComponentID!EntityIdentifier)
            {
                auto blobID = cast(EntityIdentifier*) blob;
                blobID.id = id;
            }
        }

        _page.len++;

        /* Now cache this into the lookup cache */
        locations[id] = EntityLocation(ourIndex, _page);

        if (originalArchetype is null)
        {
            return;
        }

        /* Begin clone operations */
        import std.algorithm;

        auto similarManifests = originalArchetype.manifests.filter!(
                (a) => this.manifests.canFind(a));

        ulong oldIndex = 0;
        Page* oldPage = null;
        assert((oldPage = originalArchetype.findEntity(id, oldIndex)) !is null, "EPIC FAIL");
        /* For each in the same-manifest-set, we need to clone it in */
        foreach (ref manifest; similarManifests)
        {
            auto sourceChunk = oldPage.chunks[originalArchetype.componentReverse[manifest.index]];
            auto targetChunk = _page.chunks[componentReverse[manifest.index]];
            manifest.cloneRow(sourceChunk, oldIndex, targetChunk, ourIndex);
        }
    }

    /**
     * Drop an entity from this archetype and remove all chunked data
     * for it.
     */
    final void dropEntity(EntityID id) @trusted
    {
        --numEntities;
        entities[id] = false;

        /* Need to invalidate the caches */
        invalidateCache();

        ulong oldIndex = 0;

        Page* oldPage = findEntity(id, oldIndex);
        assert(oldPage !is null, "CANNOT DELETE MISSING ENTITY");

        oldPage.len--;
        foreach (ref manifest; manifests)
        {
            auto oldChunk = oldPage.chunks[componentReverse[manifest.index]];
            manifest.removeRow(oldChunk, oldIndex);
        }

        /* Release old page */
        if (oldPage.empty() && oldPage != _page)
        {
            foreach (ref manifest; manifests)
            {
                auto chunk = oldPage.chunks[componentReverse[manifest.index]];
                manifest.deallocateChunk(chunk);
            }

            import std.algorithm.mutation : remove;

            pages = pages.remove!(a => a == oldPage);
            oldPage.destroy();
        }
    }

    /**
     * Return true if this archetype has become empty and is in need
     * of disposal.
     */
    final bool empty() @safe nothrow
    {
        if (manifests.length == 1 && manifests[0].index == getComponentID!EntityIdentifier)
        {
            return false;
        }
        return numEntities == 0;
    }

    /**
     * Return the reverse index for a given component
     */
    pragma(inline, true) ulong reverseIndex(C)() @safe nothrow
    {
        return componentReverse[getComponentID!C];
    }

    /**
     * Update the entity data
     */
    final void setChunkedComponentData(C)(ref ComponentManifest manifest, EntityID id, ref C data) @safe
    {

        ulong idx = 0;
        auto page = findEntity(id, idx);
        assert(page !is null, "FAILED TO FIND ENTITY");
        auto chunk = page.getChunk!C(componentReverse[manifest.index]);
        chunk.buffer[idx] = data;
    }

    /**
     * Return a write-access pointer to the chunked component
     * data.
     */
    final C* getChunkedComponentData(C)(ref ComponentManifest manifest, EntityID id) @safe
    {
        ulong idx = 0;
        auto page = findEntity(id, idx);
        assert(page !is null, "FAILED TO FIND ENTITY");
        auto chunk = page.getChunk!C(componentReverse[manifest.index]);

        return &chunk.buffer[idx];
    }

    /**
     * Create a new storage page
     */
    final Page* createPage() @safe nothrow
    {
        auto page = new Page(manifests.length);

        ulong len = manifests[0].maxElements;
        foreach (i, m; manifests)
        {
            auto chunk = m.allocateChunk();
            page.setChunk(i, chunk);
            if (len > m.maxElements)
            {
                len = m.maxElements;
            }
        }
        page.max = len - 1;
        return page;
    }

    /**
     * Read-write range for components in this archetype
     */
    final auto rangedRW(C...)() @safe nothrow
    {
        import std.algorithm;
        import std.range;

        return pages.map!((a) => a.rangedRW!C(&this)).joiner;
    }

    /**
     * Read-only range for components in this archetype
     */
    final auto rangedRO(C...)() @safe nothrow
    {
        import std.algorithm;
        import std.range;

        return pages.map!((a) => a.rangedRO!C(&this)).joiner;
    }

    /**
     * Read-write chunked range for components in this archetype
     */
    final auto chunkRangedRW(C...)() @safe nothrow
    {
        import std.algorithm;
        import std.range;

        return pages.map!((a) => a.rangedRW!C(&this)).chain;
    }

    /**
     * Read-only chunked range for components in this archetype
     */
    final auto chunkRangedRO(C...)() @safe nothrow
    {
        import std.algorithm;
        import std.range;

        return pages.map!((a) => a.rangedRO!C(&this)).chain;
    }

    /**
     * Attempt to find the entity.
     */
    final Page* findEntity(EntityID id, out ulong index) @safe nothrow
    {
        /* Check the cache first */
        if (id in locations)
        {
            auto loc = locations[id];
            index = loc.rowIndex;
            return loc.page;
        }

        foreach (page; pages)
        {
            if (page.findEntity(&this, id, index))
            {
                /* Cache for subsequent lookups */
                locations[id] = EntityLocation(index, page);
                return page;
            }
        }
        return null;
    }

    /**
     * Return any internal resources.
     */
    final void close() @safe nothrow
    {
        foreach (ref page; pages)
        {
            foreach (ref manifest; manifests)
            {
                auto chunk = page.chunks[componentReverse[manifest.index]];
                manifest.deallocateChunk(chunk);
            }
        }
    }

    /**
     * Clear out all of our cached locations
     */
    final void invalidateCache() @trusted nothrow
    {
        locations.clear();
    }
}
