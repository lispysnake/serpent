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

import serpent.core.entity;

/**
 * The function should deal with freeing the given component.
 */
alias componentDeallocateFunc = void function(void* v);

/**
 * The component User Defined Attribute is an essential part of the
 * serpent architecture. Like any other ECS, it provides a data tagging
 * facility which is also used to query and filter. Think of a component
 * as a column, which when joined with other columns and a primary key
 * like EntityIdentifier, you have a row within a table.
 *
 * The archetype is the table implementation which stores in chunks to
 * help with efficiency. All archetypes together compose our world
 * database.
 *
 * Yep, relational DBs reinvented.
 */
final struct serpentComponent
{
    public componentDeallocateFunc deallocate = null;
}

/**
 * We need this guy to help us trick the template system into incrementing
 * a base index per component.
 */
package struct BaseID
{
    static uint numeric = 0;

    static final @property uint maxComponents() @safe @nogc nothrow
    {
        return numeric;
    }
}

/**
 * Each ComponentID is templated to a component *type* which gives us
 * a nice numberical index for every registered component.
 */
package struct ComponentID(C)
{
    static uint numeric = 0;

    /**
     * Increment per component at compile time as needed.
     */
    static this()
    {
        numeric = ++BaseID.numeric;
    }
}

/**
 * Helper to ensure we have a valid component.
 */
package auto isValidComponent(C)()
{
    import std.string;
    import std.traits : hasUDA;

    static assert(is(C == struct), "Component is not a struct: %s".format(C.stringof));
    static assert(hasUDA!(C, serpentComponent),
            "Component missing @serpentComponent UDA tag: %s".format(C.stringof));
    return true;
}

/**
 * Helper to return the component ID for a valid component.
 */
pragma(inline, true) package auto getComponentID(C)()
{
    static assert(isValidComponent!C);
    return ComponentID!C.numeric;
}

/**
 * Return the component UDA, handling @serpentComponent and @serpentComponent() cases.
 *
 * We specify helper metadata sometimes in the serpentComponent so that we can
 * integrate stuff like the deallocate function.
 */
pragma(inline, true) package auto getComponentUDA(C)()
{
    import std.string;
    import std.traits : getUDAs;

    /* If its actually a component() struct, return it. */
    static if (is(typeof(getUDAs!(C, serpentComponent)[0]) == serpentComponent))
    {
        return getUDAs!(C, serpentComponent)[0];
    }
    else
    {
        /* Otherwise its an empty tag, return default component */
        return serpentComponent();
    }
}

/**
 * Every archetype contains the EntityIdentifier by default, so that
 * we can correctly track each component row in the table.
 */
package @serpentComponent final struct EntityIdentifier
{
    EntityID id;

    pure final string toString() @safe
    {
        import std.conv : to;

        return to!string(id);
    }
}
