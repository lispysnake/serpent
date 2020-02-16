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

module serpent.core.greedyarray;

import std.container.array : Array;

/**
 * The GreedyArray is a wrapper around std.container.array that provides
 * greedy regrowth characteristics to avoid memory fragmentation for long
 * lived processes.
 *
 * It is used extensively within serpent due to the nature of a heavy
 * cache-reliant game loop.
 */
final struct GreedyArray(T)
{

private:

    ulong _minSize = 0;
    ulong _maxSize = 0;
    ulong _realSize = 0;
    ulong _curSize = 0;
    Array!T _array;
    static auto growthFactor = 4; /* Quadruple in size */

public:

    /**
     * Construct a new GreedyArray with the given initial minimum size
     * and ceiling limit. If maxSize is 0 then the growth will be unbounded.
     */
    this(ulong minSize, ulong maxSize) @trusted nothrow
    {
        if (maxSize != 0)
        {
            assert(minSize <= maxSize, "minSize cannot exeed maxSize for bounded Array");
        }
        _array = Array!T();
        _minSize = minSize;
        _maxSize = maxSize;
        _array.reserve(minSize);
        _array.length = minSize;
        _realSize = minSize;
    }

    /**
     * Return the minimum size of the array
     */
    pure @property final const ulong minSize() @safe @nogc nothrow
    {
        return _minSize;
    }

    /**
     * Return the maximum size of the array. If this is 0, then unbounded
     * growth.
     */
    pure @property final const ulong maxSize() @safe @nogc nothrow
    {
        return _maxSize;
    }

    /**
     * Return indexing for underlying array
     */
    pure final auto opIndex(ulong i) @trusted
    {
        assert(i < _array.length);
        return _array[i];
    }

    /**
     * Provide indexing assignment to underlying array
     */
    final auto opIndexAssign(T v, ulong i) @trusted
    {
        checkResize(i);
        return _array[i] = v;
    }

    final auto opIndexAssign(ref T v, ulong i) @trusted
    {
        checkResize(i);
        return _array[i] = v;
    }

    /**
     * Return the current data slice for ranging
     */
    final @property auto data() @trusted @nogc nothrow
    {
        return _array[0 .. _curSize];
    }

    /**
     * Return true if we're full.
     */
    pragma(inline, true) pure final bool full() @safe @nogc nothrow
    {
        return willFill(0);
    }

    /**
     * Return true if adding the given number of elements would fill the
     * array completely.
     */
    pragma(inline, true) pure final bool willFill(ulong nElements) @safe @nogc nothrow
    {
        if (maxSize < 1)
        {
            return false;
        }
        return (_curSize + nElements >= _maxSize);
    }

package:

    /**
     * Rewind the array back to no-size
     */
    final void reset() @safe @nogc nothrow
    {
        _curSize = 0;
    }

private:

    /**
     * Check if a resize is needed and attempt to do so.
     */
    final void checkResize(ulong idx) @trusted @nogc nothrow
    {
        if (idx + 1 > _curSize)
        {
            _curSize = idx + 1;
        }
        if (idx + 1 < _realSize || (maxSize > 0 && _realSize == _maxSize))
        {
            return;
        }
        ulong newSize = _realSize;
        if (newSize < 1)
        {
            newSize = 1;
        }
        while (newSize < _curSize + 1)
        {
            newSize *= growthFactor;
        }
        if (newSize >= maxSize && maxSize > 0)
        {
            newSize = maxSize;
        }
        _array.reserve(newSize);
        _array.length = newSize;
        _realSize = newSize;
    }
}
