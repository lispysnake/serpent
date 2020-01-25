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

module serpent.core.component;

public import serpent.core.entity;

import std.traits : hasUDA;
import std.format : format;
import std.algorithm.setops : setIntersection;

/**
 * Simple UDA decorator. May be used in future for runtime introspection,
 * but is an explicit requiremenet to ensure we don't add random objects
 * and instances to entities.
 */
final struct serpentComponent
{
}

/**
 * The ComponentManager is responsible for assigning and removing components
 * (tags + data) from specific entities. In future it will evolve to have
 * improved memory management, with Region allocation and entity sorting.
 *
 * For now, it will be simple to get us to demo stages.
 */
final class ComponentManager
{

private:
    ComponentStore[TypeInfo] store;
    void*[TypeInfo] blob;

package:

    this()
    {

    }

    /**
     * Adds a component (tag) to the given entity ID.
     */
    final void addComponent(C)(EntityID id) @trusted
    {
        static assert(hasUDA!(C, serpentComponent),
                "'%s' is not a valid serpentComponent".format(C.stringof));
        assert(typeid(C) in store, "'%s' is not a registered component".format(C.stringof));

        /* Update membership */
        store[typeid(C)].set(id);
        auto bl = cast(ComponentBlob!C) blob[typeid(C)];
        bl.set(id, new C());
    }

    /**
     * Removes a component (and any data) from the given entity ID
     */
    final void removeComponent(C)(EntityID id) @safe @nogc nothrow
    {
        static assert(hasUDA!(C, serpentComponent),
                "'%s' is not a valid serpentComponent".format(C.stringof));
        assert(typeid(C) in store, "'%s' is not a registered component".format(C.stringof));

        /* Update membership */
        store[typeid(C)].unset(id);
        auto bl = cast(ComponentBlob!C) blob[typeid(C)];
        bl.unset(id);
    }

    /**
     * Returns read-write access to component data.
     *
     * This is only compiler-level enforced. Derpy programming will
     * always find a way around it.
     */
    final pure C* dataRW(C)(EntityID id) @trusted
    {
        static assert(hasUDA!(C, serpentComponent),
                "'%s' is not a valid serpentComponent".format(C.stringof));
        assert(typeid(C) in store, "'%s' is not a registered component".format(C.stringof));
        auto bl = cast(ComponentBlob!C) blob[typeid(C)];
        return bl.get(id);
    }

    /**
     * Returns read-only access to component data.
     *
     * This is only compiler-level enforced. Derpy programming will
     * always find a way around it.
     */
    final pure immutable(C*) dataRO(C)(EntityID id) @trusted @nogc nothrow
    {
        static assert(hasUDA!(C, serpentComponent),
                "'%s' is not a valid serpentComponent".format(C.stringof));
        auto bl = cast(ComponentBlob!C) blob[typeid(C)];
        return bl.get(id);
    }

public:
    /**
     * Register a component with the system.
     * This will also allocate any storage for the component
     */
    final void registerComponent(C)() @trusted
    {
        static assert(hasUDA!(C, serpentComponent),
                "'%s' is not a valid serpentComponent".format(C.stringof));
        assert(typeid(C) !in store, "'%s' is already a registered component".format(C.stringof));

        /* TODO: Improve allocator here. */
        store[typeid(C)] = new ComponentStore();
        blob[typeid(C)] = cast(void*) new ComponentBlob!C();
    }

    final auto withComponent(C)()
    {
        static assert(hasUDA!(C, serpentComponent),
                "'%s' is not a valid serpentComponent".format(C.stringof));
        assert(typeid(C) in store, "'%s' is not a registered component".format(C.stringof));
        return store[typeid(C)].mapping.byKey();
    }

    /**
     * Return all entities that have both components C & D
     */
    final auto withComponents(C, D)()
    {
        return setIntersection(withComponent!C(), withComponent!D());
    }

    /**
     * Return all entities that have components C, D and E
     */
    final auto withComponents(C, D, E)()
    {
        return setIntersection(withComponent!C(), withComponent!D(), withComponent!E());
    }
}

/**
 * The component store is constructed per component as a means for storing
 * component membership.
 *
 * Right now it's just a fancy map wrapper. Eventually we'll want better
 * allocators and sparse integer sets.
 */
final class ComponentStore
{

private:
    bool[EntityID] mapping;

package:
    this()
    {
    }

    /**
     * Set the entity as belonging to this component
     */
    final void set(EntityID id) @safe nothrow
    {
        mapping[id] = true;
    }

    final void unset(EntityID id) @safe nothrow
    {
        mapping.remove(id);
    }
}

/**
 * The component blob stores a map per component from entityID to the
 * actual component storage type.
 */
final class ComponentBlob(C)
{

private:
    C*[EntityID] mapping;

package:
    this()
    {
    }

    /**
     * Set the associated datum with the enttity ID
     */
    final void set(EntityID id, C* datum) @safe nothrow
    {
        mapping[id] = datum;
    }

    /**
     * Unset the associated datum from the entity ID
     */
    final void unset(EntityID id) @safe nothrow
    {
        mapping.remove(id);
    }

    final C* get(EntityID id) @safe
    {
        assert(id in mapping, "Entity '%d' does not have component '%s'".format(id, C.stringof));
        return mapping[id];
    }
}
