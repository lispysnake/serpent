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

module serpent.tiled.layer;

public import std.stdint;

/**
 * The MapLayer contains data within a visible layer.
 * Essentially it is a wrapper around the underlying tile-data.
 */
final class MapLayer
{
private:

    uint32_t[] _data;
    uint _width;
    uint _height;

public:

    /**
     * Construct a new MapLayer with the given width and height
     */
    this(uint width, uint height)
    {
        this._width = width;
        this._height = height;
        this._data = new uint32_t[width * height];
    }

    /**
     * Set tile at X, Y to D
     */
    public void set(uint x, uint y, uint32_t d)
    {
        _data[x + y * width] = d;
    }

    /**
     * Return the width for this layer
     */
    pure @property final uint width() @safe @nogc nothrow
    {
        return _width;
    }

    /**
     * Return the height for this layer
     */
    pure @property final uint height() @safe @nogc nothrow
    {
        return _height;
    }

    /**
     * Return reference-only access to underlying data
     */
    pure @property final const immutable(uint32_t[]) data() @trusted @nogc nothrow
    {
        return cast(immutable(uint32_t[])) _data;
    }
}
