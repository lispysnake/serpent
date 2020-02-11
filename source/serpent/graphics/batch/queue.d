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

module serpent.graphics.batch.queue;

public import std.container.array;

/**
 * A BatchQueue helps us to manage the CPU-size of vertex and index buffers
 * to prepare each set for uploading to the GPU.
 */
final struct BatchQueue(V, I)
{
private:

    Array!V vertices;
    Array!I indices;

    ulong _minQuads = 0;
    ulong _maxQuads = 0;
    ulong _size = 0;
    ulong _numIndices = 0;
    ulong _numVertices = 0;

public:

    /**
     * Construct a new BatchQueue with the specified number of maximum
     * quads, number of indices per pair, 
     */
    this(ulong minQuads, ulong maxQuads, uint numIndices, uint numVertices)
    {
        this._minQuads = minQuads;
        this._maxQuads = maxQuads;
        this._numIndices = numIndices;
        this._numVertices = numVertices;
    }

    @disable this();

    /**
     * Return the preallocated size of this BatchQueue
     */
    pragma(inline, true) pure @property final ulong minQuads() @safe @nogc nothrow
    {
        return _minQuads;
    }

    /**
     * Return the maximum permitted size of this batch queue
     */
    pragma(inline, true) pure @property final ulong maxQuads() @safe @nogc nothrow
    {
        return _maxQuads;
    }

    /**
     * Return the number of indices in each set
     */
    pragma(inline, true) pure @property final ulong numIndices() @safe @nogc nothrow
    {
        return _numIndices;
    }

    /**
     * Return the number of vertices in each quad set.
     */
    pragma(inline, true) pure @property final ulong numVertices() @safe @nogc nothrow
    {
        return _numVertices;
    }
}
