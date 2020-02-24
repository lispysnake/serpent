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

module serpent.core.view;

public import serpent.core.component;
public import serpent.core.entity;
public import serpent.core.entitymanager;
public import serpent.core.policy;

/**
 * A view controls access to the underlying EntityManager and ensures
 * we remain as thread-safe as possible.
 */
final struct View(T : DataPolicy)
{

private:
    EntityManager _manager;

package:
    this(EntityManager ent)
    {
        this._manager = ent;
    }

public:

    @disable this();

    static if (is(T : ReadOnly))
    {

        /* READ-ONLY APIs */

        /**
         * Return data for the given entity ID
         */
        pragma(inline, true) final const(C*) data(C)(EntityID id) @safe
        {
            return _manager.dataRO!C(id);
        }

        /**
         * Iterate all entities with the matching components
         */
        pragma(inline, true) final auto withComponents(C...)() @safe
        {
            return _manager.withComponentsRO!C;
        }

        /**
         * Iterate all entities with matching components in
         * chunked ranges.
         */
        pragma(inline, true) final auto withComponentsChunked(C...)() @safe
        {
            return _manager.withComponentsChunkedRO!C;
        }

    }
    else
    {

        /* READ-WRITE APIs */

        /**
         * Request data for an entity that was created before this
         * frame tick.
         */
        pragma(inline, true) final C* data(C)(EntityID id) @safe
        {
            return _manager.dataRW!C(id);
        }

        /**
         * Request a new entity construction to happen immediately.
         * This is a blocking call as an entity identifier needs
         * to be allocated.
         */
        pragma(inline, true) final EntityID createEntity() @safe
        {
            return _manager.create();
        }

        /**
         * Immediately create a new entity with the given components. Note it
         * is not possible to use this in conjunction with the deferred APIs
         *
         * Care should be taken when used with threading.
         *
         * If creating entities in dense loops + threading, then the create()
         * function should be used instead in conjunction with addComponentDeferred
         */
        pragma(inline, true) final EntityID createEntityWithComponents(C...)() @safe
        {
            return _manager.createWithComponents!C();
        }

        /**
         * Immediately add a component to the entity. Care must be taken
         * when used with threading.
         */
        pragma(inline, true) final C* addComponent(C)(EntityID id) @safe
        {
            return addComponent!C(id, C.init);
        }

        /**
         * Immediately add component to entity by value. Care must be taken
         * when used with threading.
         */
        pragma(inline, true) final C* addComponent(C)(EntityID id, C datum) @safe
        {
            return addComponent!C(id, datum);
        }

        /**
         * Immediately add component to entity by reference. Care must be taken
         * when used with threading.
         */
        pragma(inline, true) final C* addComponent(C)(EntityID id, ref C datum) @safe
        {
            return _manager.addComponent!C(id, datum);
        }

        /**
         * Schedule addition of a component to the entity
         */
        pragma(inline, true) final void addComponentDeferred(C)(EntityID) @safe
        {
            addComponentDeferred!C(id, C.init);
        }

        /**
         * Schedule addition of component to entity by value
         */
        pragma(inline, true) final void addComponentDeferred(C)(EntityID id, C datum) @safe
        {
            addComponentDeferred!C(id, datum);
        }

        /**
         * Schedule addition of component to entity by reference
         */
        pragma(inline, true) final void addComponentDeferred(C)(EntityID id, ref C datum) @safe
        {
            _manager.stageComponentAssignment!C(id, datum);
        }

        /**
         * Immediately remove the of component. Care must be taken
         * when used with threading.
         */
        pragma(inline, true) final void removeComponent(C)(EntityID id) @safe
        {
            _manager.removeComponent!C(id);
        }

        /**
         * Schedule removal of the component from the entity.
         */
        pragma(inline, true) final void removeComponentDeferred(C)(EntityID id) @safe
        {
            _manager.pushComponentRemoval(ComponentRemoval.fromComponent!C(id));
        }

        /**
         *  Schedule killing of the entity
         */
        pragma(inline, true) final void killEntity(EntityID id) @safe
        {
            _manager.kill(id);
        }

        /**
         * Iterate all entities with the matching components
         */
        pragma(inline, true) final auto withComponents(C...)() @safe
        {
            return _manager.withComponentsRW!C;
        }

        /**
         * Iterate all entities with matching components in
         * chunked ranges.
         */
        pragma(inline, true) final auto withComponentsChunked(C...)() @safe
        {
            return _manager.withComponentsChunkedRW!C;
        }
    }

    /**
     * Returns true if we have the given component
     */
    pragma(inline, true) final bool hasComponent(C)(EntityID id) @safe
    {
        return _manager.hasComponent!C(id);
    }
}

/**
 * A ComponentRemoval is created by the view to push removals back
 * to the engine to process.
 */
final package struct ComponentRemoval
{
    EntityID entityID;
    ulong componentID;

    this(EntityID entityID, ulong componentID) @trusted nothrow
    {
        this.entityID = entityID;
        this.componentID = componentID;
    }

    /**
     * Create a new ComponentRemoval request for the given component static type
     */
    package final static ComponentRemoval fromComponent(C)(EntityID id) @trusted nothrow
    {
        static assert(isValidComponent!C);
        return ComponentRemoval(id, getComponentID!C);
    }
};
