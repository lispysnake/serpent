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

module serpent.core.page;

import serpent.core.archetype;
import serpent.core.component;
import serpent.core.entity;
import serpent.core.storage.chunk;
import serpent.core.entityrange;

/**
 * A page is one logical unit of storage within an Archetype. It contains
 * a set of pointers to the allocated StorageChunk!T for the component
 * in a generic fashion.
 *
 * It is pretty much unusable by itself, which is why the EntityRange
 * is provided for iteration.
 */
package final struct Page
{

    alias chunkPtr = void*;
    ulong len = 0;
    ulong max = 0;

package:

    /* Page consists of chunks for all components. Its just a set of
     * void* pointers really.
     */

    chunkPtr[] chunks;

public:

    /**
     * Construct a new Page with the given number of components
     */
    this(ulong numComponents) @safe nothrow
    {
        chunks.reserve(numComponents);
        chunks.length = numComponents;
    }

    /**
     * Set the chunk.
     */
    void setChunk(ulong index, chunkPtr chunk) @safe @nogc nothrow
    {
        chunks[index] = chunk;
    }

    /**
     * Get the shunk
     */
    StorageChunk!C* getChunk(C)(ulong index) @trusted @nogc nothrow
    {
        return cast(StorageChunk!C*) chunks[index];
    }

    /**
     * Return a read-write range for this page with the given components
     */
    final auto rangedRW(C...)(Archetype* archetype) @safe nothrow
    {
        return entityRangeRW!(C)(archetype, &this);
    }

    /**
     * Return a read-only range for this page with the given components
     */
    final auto rangedRO(C...)(Archetype* archetype) @safe nothrow
    {
        return entityRangeRO!(C)(archetype, &this);
    }

    /**
     * Scan the page to find the entity. This is quite slow
     */
    final bool findEntity(Archetype* archetype, EntityID id, out ulong index) @safe nothrow
    {
        ulong localIndex = 0;
        ulong chunkIndex = archetype.reverseIndex!EntityIdentifier;
        foreach (ref ent; getChunk!EntityIdentifier(chunkIndex).buffer)
        {
            if (ent.id == id)
            {
                index = localIndex;
                return true;
            }
            ++localIndex;
        }
        return false;
    }

    /**
     * True if we hit maximum capacity
     */
    pure final @property const bool full() @safe @nogc nothrow
    {
        return len >= max;
    }

    /**
     * True if the page has been marked empty
     */
    pure final @property const bool empty() @safe @nogc nothrow
    {
        return len == 0;
    }

    @disable this();
}
