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
 * Each layer may be encoded in a number of ways.
 */
enum LayerEncoding
{
    CSV = 1, /**< Comma-separated-values */
    Base64, /**< Base64 encoded binary data */
    XML, /**< Hella inefficient. */



};

/**
 * Additionally, each layer may be compressed in one of multiple
 * ways.
 */
enum LayerCompression
{
    None = 1,
    ZLib, /**<Compressed using zlib */
    GZip, /**<Compressed using gzip */



};

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
    string _id = "";
    string _name = "";

package:

    /**
     * private constructor
     */
    this() @safe @nogc nothrow
    {
    }

    /**
     * Allocate underlying storage
     */
    void allocateBlob() @safe
    {
        this._data = new uint32_t[width * height];
    }

    /**
     * Set the layer width
     */
    pure final @property void width(int width) @safe @nogc nothrow
    {
        this._width = width;
    }

    /**
     * Set the layer height
     */
    pure final @property void height(int height) @safe @nogc nothrow
    {
        this._height = height;
    }

public:

    /**
     * Construct a new MapLayer with the given width and height
     */
    this(uint width, uint height) @safe
    {
        this._width = width;
        this._height = height;
        allocateBlob();
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

    /**
     * Return the ID for this layer
     */
    pure @property final const string id() @safe @nogc nothrow
    {
        return _id;
    }

    /**
     * Set the ID for this layer
     */
    pure final @property void id(string id) @safe @nogc nothrow
    {
        this._id = id;
    }

    /**
     * Return the name for this layer
     */
    pure @property final const string name() @safe @nogc nothrow
    {
        return _name;
    }

    /**
     * Set the name of this layer
     */
    pure final @property void name(string name) @safe @nogc nothrow
    {
        this._name = name;
    }

}
