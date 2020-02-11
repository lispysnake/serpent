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

import std.algorithm.mutation : copy;
import core.stdc.string : memcpy;

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
    ulong sizeVertices = 0;
    ulong sizeIndices = 0;

    ulong verticesIndex = 0;
    ulong indicesIndex = 0;

package:

    /**
     * Check if we need to resize the vertices
     */
    pragma(inline, true) final bool checkResizeVertices()
    {
        /* No need to resize, back we go */
        if (verticesIndex + numVertices < sizeVertices)
        {
            return false;
        }

        return true;
    }

    /**
     * Greedily resize the vertices if we can.
     */
    final bool performResizeVertices()
    {
        auto maxSize = _numVertices * _maxQuads;

        /* Resize not possible */
        if (verticesIndex + numVertices > maxSize - 1)
        {
            return false;
        }

        auto newSize = verticesIndex * 2;
        if (newSize > maxSize)
        {
            newSize = maxSize;
        }
        sizeVertices = newSize;
        vertices.reserve(sizeVertices);
        vertices.length = sizeVertices;

        return true;
    }

    /**
     * Check if we need to resize indices
     */
    pragma(inline, true) final bool checkResizeIndices()
    {
        /* No need to resize, back we go */
        if (indicesIndex + numIndices < sizeIndices)
        {
            return false;
        }

        return true;
    }

    /**
     * Resize the indices
     */
    final bool performResizeIndices()
    {
        import std.stdio;

        auto maxSize = _numIndices * _maxQuads;

        /* Resize not possible */
        if (indicesIndex + numIndices > maxSize - 1)
        {
            return false;
        }

        auto newSize = indicesIndex * 2;
        if (newSize > maxSize)
        {
            newSize = maxSize;
        }

        sizeIndices = newSize;
        indices.reserve(sizeIndices);
        indices.length = sizeIndices;

        return true;
    }

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

        vertices = Array!V();
        indices = Array!I();
        vertices.reserve(minQuads * numVertices);
        vertices.length = minQuads * numVertices;
        indices.reserve(minQuads * numIndices);
        indices.length = minQuads * numIndices;
        sizeIndices = indices.length;
        sizeVertices = vertices.length;
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

    /**
     * Push vertices into the vertex data buffer.
     */
    pragma(inline, true) final void pushVertices(V[] vertexData) @trusted
    {
        if (checkResizeVertices())
        {
            if (!performResizeVertices())
            {
                return;
            }
        }

        vertexData.copy(vertices[verticesIndex .. $]);
        verticesIndex += numVertices;
    }

    /**
     * Push indices into the indices data buffer
     */
    pragma(inline, true) final void pushIndices(I[] indexData) @trusted
    {
        if (checkResizeIndices())
        {
            if (!performResizeIndices())
            {
                return;
            }
        }
        indexData.copy(indices[indicesIndex .. $]);
        indicesIndex += numIndices;

    }

    pragma(inline, true) final void reset() @trusted @nogc nothrow
    {
        indicesIndex = 0;
        verticesIndex = 0;
    }

    /**
     * Return the number of indices
     */
    pragma(inline, true) pure @property final ulong indicesCount() @safe @nogc nothrow
    {
        return indicesIndex;
    }

    /**
     * Return the number of vertices
     */
    pragma(inline, true) pure @property final ulong verticesCount() @safe @nogc nothrow
    {
        return verticesIndex;
    }

    pragma(inline, true) final void copyIndices(I* target) @trusted
    {
        memcpy(cast(void*) target, cast(void*)&indices.front(), I.sizeof * indicesIndex);
    }

    pragma(inline, true) final void copyVertices(V* target) @trusted
    {
        memcpy(cast(void*) target, cast(void*)&vertices.front(), V.sizeof * verticesIndex);
    }

    /**
     * Return true if the buffer is full
     */
    pragma(inline, true) pure @property final bool full() @safe @nogc nothrow
    {
        return indicesIndex + numIndices >= (_maxQuads * numIndices);
    }
}
