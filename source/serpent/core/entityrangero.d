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

module serpent.core.entityrangero;

import serpent.core.archetype;
import serpent.core.page;
import serpent.core.storage;
import std.string;
import std.conv : to;
import std.typecons;
import std.meta;
import std.traits : moduleName;

/**
 * Convert C into a pointer to C. 
 */
static template ConstPtrToC(C)
{
    alias ConstPtrToC = const(C*);
}

static template PtrToC(C)
{
    alias PtrToC = C*;
}

/**
 * Create a field to link to the underlying storage
 */
static template linkField(alias C)
{
    const char[] linkField = "private StorageChunk!" ~ C.stringof ~ " * chunk"
        ~ C.stringof.capitalize ~ ";";
}

/**
 * This hack is required to reverse import the type to make it buildable.
 * Without this, you're getting undefined identifier issues.
 */
static template pushImportLocal(alias C)
{
    const char[] pushImportLocal = "import " ~ moduleName!C ~ ";";
}

/**
 * Assignment to new ID in the underlying buffer.
 */
static template updateField(ulong T, alias C)
{
    const char[] updateField = "curTuple[" ~ to!string(
            T) ~ "] = &chunk" ~ C.stringof.capitalize ~ ".buffer[index];";
}

/**
 * Requested a single field update for non tuple mode,
 * i.e. single component.
 */
static template updateSingularField(alias C)
{
    const char[] updateSingularField = "curTuple =  &chunk"
        ~ C.stringof.capitalize ~ ".buffer[index];";
}

/**
 * Ensure that our storage has been correctly set.
 */
static template nullEnforcementField(alias C)
{
    const char[] nullEnforcementField = "assert(chunk" ~ C.stringof.capitalize
        ~ " !is null, \"FATAL ERROR\");";
}

/* Point the chunk to the right place */
static template initField(alias C)
{
    const char[] initField = "chunk" ~ C.stringof.capitalize ~ " = _page.getChunk!"
        ~ C.stringof ~ "(_archetype.reverseIndex!" ~ C.stringof ~ ");";
}

/**
 * EntityRangeRW is used to iterate through an individual chunk within
 * an archetype. Multiple EntityRanges may be chained together to give
 * the complete set of chunks.
 *
 * Additionally, multiple archetypes may have entities matching the input
 * query, so all matching archetypes will be chained together into one
 * super range.
 */
package struct EntityRangeRO(C...)
{
private:

    static if (C.length == 1)
    {
        alias ComponentSet = PtrToC!C;
        alias ComponentSetCast = ComponentSet;
    }
    else
    {
        alias ComponentSet = Tuple!(staticMap!(PtrToC, C));
        alias ComponentSetCast = Tuple!(staticMap!(ConstPtrToC, C));
    }

    ulong index = 0;
    ulong max = 0;
    Page* _page = null;
    Archetype* _archetype = null;

    ComponentSet curTuple;

    /**
     * Construct a chunk pointer for each component type.
     */
    static foreach (c; C)
    {
        mixin(pushImportLocal!c);
        mixin(linkField!(c));
    }

    /**
     * Private method to set the next iteration
     */
    final void setNext() @safe @nogc nothrow
    {
        static foreach (i, c; C)
        {
            mixin(nullEnforcementField!(c));
            static if (C.length == 1)
            {
                mixin(updateSingularField!(c));
            }
            else
            {
                mixin(updateField!(i, c));
            }
        }
    }

package:

    /**
     * Construct a new EntityRange from the given archetype and
     * page. At this point we initialise all member fields from
     * the archetype + page datums.
     */
    this(Archetype* archetype, Page* page) @safe nothrow
    {
        _archetype = archetype;
        _page = page;
        max = _page.len;

        static foreach (c; C)
        {
            mixin(initField!c);
        }

        setNext();
    }

public:

    /**
     * Just return a properly configured tuple
     */
    final ComponentSetCast front() @safe @nogc nothrow
    {
        static if (C.length == 1)
        {
            return cast(const(C*)) curTuple;
        }
        else
        {
            return ComponentSetCast(curTuple);
        }
    }

    /**
     * Returns true when we've reached the limit of the range
     */
    pure final bool empty() @safe @nogc nothrow
    {
        return index >= max;
    }

    /**
     * Shift the index + pointers
     */
    final void popFront() @safe @nogc nothrow
    {
        ++index;
        setNext();
    }
}
