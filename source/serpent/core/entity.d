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

import std.container : Array;

public import std.typecons;

/**
 * EntityID is the underlying handle to an entity
 */
alias EntityID = Typedef!(uint32_t);

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
    EntityID lastID = 0;
    uint32_t allocatedEntities = 0;

    /* Asked to kill. */
    Array!EntityID deadEntities;
    Array!EntityID killEntities;

package:

    /**
     * Construct a new EntityManager. An instance of the EntityManager should
     * be obtained from the Context.
     */
    this(ComponentManager comp)
    {
        _component = comp;

        /* In future consider greedy_realloc style behaviour. */
        deadEntities.reserve(100);
        killEntities.reserve(100);
    }

    /**
     * Protected function that will cause the EntityManager to step through
     * updates for one cycle. Any entities marked dead in previous frames will
     * now be scheduled for reclaiming.
     */
    final void step() @safe @nogc nothrow
    {

    }

private:

    /**
     * Helper to clean up any killing.
     * Note: If creating boatloads of IDs and then deleting them all,
     * this list becomes very large. We'll improve this in future.
     */
    final void processKills() @system
    {
        /* Typical entity killage. */
        foreach (i; 0 .. killEntities.length)
        {
            deadEntities.insertBack(killEntities[i]);
            /* TODO: Clear component storage */
            --allocatedEntities;
        }

        killEntities.clear();
    }

    /**
     * Attempt to recycle a previously allocated ID.
     */
    final Entity recycle() @safe
    {
        if (deadEntities.length < 1)
        {
            return Entity(cast(EntityID) 0);
        }
        auto ent = deadEntities.back();
        deadEntities.removeBack();
        return Entity(ent);
    }

package:

    /**
     * Create a new Entity
     */
    final Entity create() @safe
    {
        /* Try recycling first. */
        auto ent = recycle();
        if (ent.isValid())
        {
            ++allocatedEntities;
            return ent;
        }

        /* New entity. */
        ++lastID;
        ++allocatedEntities;

        return Entity(lastID);
    }

public:

    /**
     * Return the underlying component manager
     */
    pure @property final ComponentManager component() @safe @nogc nothrow
    {
        return _component;
    }
}
