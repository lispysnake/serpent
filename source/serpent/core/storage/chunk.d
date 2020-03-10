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

module serpent.core.storage.chunk;

public import serpent.core.component : isValidComponent;

import std.conv : to;

/**
 * By default we want all chunks to be 16KiB in size.
 */
const uint ChunkSize = 2 << 13;

/**
 * StorageChunks are allocated into larger pages, with each chunk providing
 * storage capacity for an explicitly typed component. We forcibly ensure
 * that all StorageChunks are exactly 16KiB in size. This design allows us
 * to fit many components (entities) within a single chunk and have multiple
 * chunks easily fit in the L1 cache.
 *
 * When we have alignment issues, padding is automatically inserted into the
 * storage chunk. When this happens it helps to review the component struct
 * definition to minimise cache misses.
 *
 * Lastly, we refuse to work with structs that aren't correctly aligned
 * as they're totally screw up memory access. Thus, ensure evenly divisable
 * struct sizes (The compiler will warn when this isn't the case)
 *
 */
final struct StorageChunk(C)
{

    static assert(isValidComponent!C);

private:

    ushort _insertIndex = 0;
    ushort _numElements = 0;

    static const uint metaSize = (_insertIndex.sizeof + _numElements.sizeof);

public:
    static const ulong maxElements = (ChunkSize - metaSize) / cast(int) C.sizeof;
    static const ulong dataSize = maxElements * C.sizeof;
    static const ulong realSize = dataSize + metaSize;

    /**
     * If needed, insert some private padding into this chunk to permit proper
     * alignment within the page. It is still very important than each struct
     * has proper alignment (2/4/8/16) to ensure we don't incur cache misses
     */
    static if (realSize < ChunkSize)
    {
        pragma(msg, "StorageChunk!" ~ C.stringof ~ ": Inserting padding of size " ~ to!string(
                ChunkSize - realSize) ~ " bytes");
        private byte[ChunkSize - realSize] padding;

        static const ulong maxSize = realSize + padding.sizeof;
    }
    else
    {
        static const ulong maxSize = realSize;
    }

    /**
     * Emit warning for non-efficient storage chunks. These will be gappy
     * and not quite fit, leading to fragmentation and jumps.
     */
    static if (C.sizeof >= 16)
    {
        static if (C.sizeof % 16 != 0)
        {
            pragma(msg,
                    "StorageChunk!" ~ C.stringof ~ ": Incorrect struct layout non divisible by 16");
        }
    }
    else static if (C.sizeof >= 8)
    {
        static if (C.sizeof % 8 != 0)
        {
            pragma(msg, "StorageChunk!" ~ C.stringof
                    ~ ": Incorrect struct layout non divisible by 8");
        }
    }
    else static if (C.sizeof >= 4)
    {
        static if (C.sizeof % 4 != 0)
        {
            pragma(msg, "StorageChunk!" ~ C.stringof
                    ~ ": Incorrect struct layout non divisible by 4");
        }
    }
    else static if (C.sizeof >= 2)
    {
        static if (C.sizeof % 2 != 0)
        {
            pragma(msg, "StorageChunk!" ~ C.stringof
                    ~ ": Incorrect struct layout non divisible by 2");
        }
    }

    /* We can't go around having 1 byte structs its just silly. */
    static assert(C.sizeof >= 2,
            "StorageChunk!" ~ C.stringof ~ ": Refusing to build for struct sizeof less than 2");

    /* Perhaps only enable on debug builds? */
    static
    {
        pragma(msg, "StorageChunk!" ~ C.stringof ~ ": maxElements: " ~ to!string(maxElements));
    }

    /**
     * Make sure we never get screwed over by a funky compiler tagging our type.
     * Additionally make sure we never introduce fields we don't want or need.
     */
    static assert(StorageChunk!C.sizeof == maxSize,
            "StorageChunk!" ~ C.stringof ~ " is " ~ to!string(StorageChunk!C.sizeof)
            ~ " bytes but we expected " ~ to!string(maxSize) ~ " bytes - Fatal Error");

    /**
     * StorageChunk is dynamically allocated and is precisely the same size
     * as the underlying raw buffer.
     *
     * Each StorageChunk is allocated from a Pool in page sizes.
     */
    C[maxElements] buffer;

    /**
     * Returns true if this chunk is now full
     */
    pure final @property const bool full() @safe @nogc nothrow
    {
        return _insertIndex == maxElements;
    }

    /**
     * Attempt to insert a data row into the chunk. If this succeeds
     * a pointer tothe datum is returned and the insert index is updated
     */
    final C* insertRow(out ulong index) @trusted @nogc nothrow
    {
        if (full())
        {
            index = 0;
            return null;
        }
        buffer[_insertIndex] = C.init;
        index = _insertIndex;
        ++_insertIndex;
        ++_numElements;
        return &buffer[index];
    }

    /**
     * Remove a row from this chunk, shiftinge everything after it
     * back one element
     */
    final void removeRow(ulong index) @trusted nothrow
    {
        assert(index < StorageChunk!C.maxElements);
        buffer[index] = C.init;
        for (auto idx = index; idx < buffer.length; idx++)
        {
            if (idx + 1 == buffer.length)
            {
                buffer[idx] = C.init;
                break;
            }
            buffer[idx] = buffer[idx + 1];
        }
        _insertIndex = cast(ushort)(_numElements - 1);
        --_numElements;
    }

    pure final @property const ushort numElements() @safe @nogc nothrow
    {
        return _numElements;
    }
}
