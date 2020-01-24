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

module serpent.core.entity;

public import serpent.core.component;
public import std.stdint;

/**
 * EntityID is the underlying handle to an entity
 */
alias EntityID = uint32_t;

/**
 * Entity wraps an ID and gives it fancy functions. No overhead.
 * Eventually we'll want to make this a bit more advanced and have
 * version fields to Entity ID, etc.
 *
 * For now, keep it simple.
 */
final struct Entity
{

private:
    EntityID _id;

protected:

    /**
     * Construct a new Entity from the given ID.
     * Should not be retained as IDs can and will change.
     */
    this(EntityID id) @safe @nogc nothrow
    {
        _id = id;
    }

public:
    @disable this();

    /**
     * Return true if the entity is valid.
     */
    public final bool isValid() @safe @nogc nothrow
    {
        return _id != 0;
    }

    /**
     * Return the ID field of this Entity.
     */
    pragma(inline, true) pure @property const final EntityID id() @safe @nogc nothrow
    {
        return _id;
    }
}

/**
 * The EntityManager is responsible for the lifecycle management of all
 * entities (_things_) within the playable world. This takes an ECS-inspired
 * approached of using compositional building blocks, i.e. assigning tags and
 * data to entities via _components_.
 *
 * The EntityManager should be used via the Context and Processor instances
 * to maintain thread-safety through data mutability promises.
 */
final class EntityManager
{

private:
    ComponentManager _component;

package:

    /**
     * Construct a new EntityManager. An instance of the EntityManager should
     * be obtained from the Context.
     */
    this()
    {
        _component = new ComponentManager();
    }

    /**
     * Protected function that will cause the EntityManager to step through
     * updates for one cycle. Any entities marked dead in previous frames will
     * now be scheduled for reclaiming.
     */
    final void step() @safe @nogc nothrow
    {

    }

public:
    pure @property final ComponentManager component() @safe @nogc nothrow
    {
        return _component;
    }
}
