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

module serpent.core.lockingringbuffer;

import serpent.core.greedyarray;
import core.sync.mutex;

/**
 * The LockingRingBuffer provides a circular buffer implementation around a potentially
 * greedily-reallocated array for cache coherency. This will also help to reduce
 * the total memory usage by only sizing-up when required. While this ma result
 * in some potential initial 'stutters' for misconfigured sizes, the growths should
 * be rare enough in most game cycles as we don't shrink.
 */
final struct LockingRingBuffer(T)
{
private:

    __gshared GreedyArray!T _array;
    ulong insertIndex = 0;
    shared Mutex mtx;

public:

    /**
     * Construct a new LockingRingBuffer.
     *
     * The maximum size must be non-zero as this is a ring buffer.
     */
    this(ulong minSize, ulong maxSize) @trusted nothrow
    {
        assert(maxSize > 0);
        _array = GreedyArray!T(minSize, maxSize);
        mtx = new shared Mutex();
    }

    final void add(T datum) @trusted @nogc nothrow
    {
        mtx.lock_nothrow();
        if (insertIndex >= _array.maxSize)
        {
            insertIndex = 0;
        }
        _array[insertIndex] = datum;
        ++insertIndex;
        mtx.unlock_nothrow();
    }

    /**
     * Return underlying data
     */
    final @property auto data() @trusted @nogc nothrow
    {
        return _array.data;
    }

    /**
     * Rewind to start of buffer.
     */
    final void reset()
    {
        mtx.lock_nothrow();
        insertIndex = 0;
        _array.reset();
        mtx.unlock_nothrow();
    }

    final const @property bool full() @trusted @nogc nothrow
    {
        return insertIndex == _array.maxSize - 1;
    }
}
