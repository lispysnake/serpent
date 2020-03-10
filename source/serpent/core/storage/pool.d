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

module serpent.core.storage.pool;

public import serpent.core.storage.chunk;

import serpent.core.greedyarray;
import std.container : SList;

/**
 * PoolAllocator is typed per component. It handles allocation of pages,
 * or chunks, per component type. Each chunk is guaranteed to be within
 * a 16kb page region with correct alignment, ensuring minimal cache
 * misses within a single chunk.
 */
final struct PoolAllocator(C)
{
private:

    alias Chunk = StorageChunk!C;
    GreedyArray!Chunk chunks;
    ulong _minChunks = 0;
    ulong _maxChunks = 0;
    ulong _poolIndex = 0;

    Chunk*[] freeChunks; /* Chunks can be returned but not deallocated. */

public:

    /**
     * Construct a new PoolAllocator with the given number of minimum
     * and maximum chunks. The minimum chunk count will be used to
     * automatically reserve chunks ahead of time, potentially speeding
     * up application start.
     *
     * The maximum chunk count can be used to cap upward growth of the
     * pool allocator, restricting huge allocations.
     *
     * Wise usage of the allocator will mean unbounded growth shouldn't
     * be a real issue.
     */
    this(ulong minChunks, ulong maxChunks) @trusted
    {
        if (maxChunks > 0)
        {
            assert(minChunks < maxChunks, "maxChunks must be greater than minimum chunks, or zero.");
        }

        this._minChunks = minChunks;
        this._maxChunks = maxChunks;

        chunks = GreedyArray!Chunk(minChunks, maxChunks);
    }

    @disable this();

    /**
     * Return the minimum chunk count (reserved size) for this allocator
     */
    pure @property final const ulong minChunks() @safe @nogc nothrow
    {
        return _minChunks;
    }

    /**
     * Return the maximum number of chunks permitted for this allocator.
     * If this is zero, unbounded growth is permitted.
     */
    pure @property final const ulong maxChunks() @safe @nogc nothrow
    {
        return _maxChunks;
    }

    /**
     * Return a new chunk.
     *
     * If possible, we'll return a free chunk to reuse.
     */
    final Chunk* allocateChunk() @trusted
    {
        /* Return from the free list */
        if (freeChunks.length > 0)
        {
            /* Return oldest chunk first */
            auto chunk = freeChunks[0];
            import std.algorithm.mutation : remove;

            freeChunks = freeChunks.remove!(a => a == chunk);
            return chunk;
        }

        /* Is allocation possible? */
        if (chunks.full())
        {
            return null;
        }
        chunks[_poolIndex] = Chunk();
        ++_poolIndex;
        return &chunks[_poolIndex - 1];
    }

    /**
     * Deallocation simply puts it back in the free list
     */
    final void deallocateChunk(Chunk* chunk) @trusted nothrow
    {
        freeChunks ~= chunk;
    }
}
