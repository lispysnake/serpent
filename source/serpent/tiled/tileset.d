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

module serpent.tiled.tileset;

import std.exception : enforce;
import std.container.array;

public import gfm.math;

/**
 * The underlying storage defines how to actually draw a Tile
 * Each Tile is stored according to the guid (index)
 */
final struct Tile
{
    box2f region; /**<Defines the renderable region for the tile */
    /* TODO: Add some kind of texture handle..? */

    this(box2f region) @safe @nogc nothrow
    {
        this.region = region;
    }

    @disable this();
};

/**
 * A TileSet describes the images, or drawable regions, of a Map.
 * Internally this can be achieved with a collection of images, or by
 * splitting a single image into many subregions.
 */
final class TileSet
{

private:

    string _name = "";
    int _tileWidth = 0;
    int _tileHeight = 0;
    int _tileCount = 0;
    int _columns = 0;
    int _spacing = 0;
    int _margin = 0;
    bool _collection = false;

    Array!Tile _tilesGUID; /*GUID-indexed tile array */
    Tile[int] _tilesMap; /* ID-to-Tile mapping (slower) */

public:

    /**
     * Return the width of each tile, in pixels
     */
    pure @property final const int tileWidth() @safe @nogc nothrow
    {
        return _tileWidth;
    }

    /**
     * Return the height of each tile, in pixels
     */
    pure @property final const int tileHeight() @safe @nogc nothrow
    {
        return _tileHeight;
    }

    /**
     * Return the number of tiles in this tileset
     */
    pure @property final const int tileCount() @safe @nogc nothrow
    {
        return _tileCount;
    }

    /**
     * Return the number of columns in this tileset
     */
    pure @property final const int columns() @safe @nogc nothrow
    {
        return _columns;
    }

    /**
     * Return the name of this tileset
     */
    pure @property final const string name() @safe @nogc nothrow
    {
        return _name;
    }

    /**
     * Return the spacing between tiles in the tileset image
     */
    pure @property final const int spacing() @safe @nogc nothrow
    {
        return _spacing;
    }

    /**
     * Return the margin for the tileset image.
     */
    pure @property final const int margin() @safe @nogc nothrow
    {
        return _margin;
    }

    /**
     * Return true if this tileset is based on a collection of images.
     * Will return false if it is based on a tilesheet image.
     */
    pure @property final const bool collection() @safe @nogc nothrow
    {
        return _collection;
    }

    /**
     * Perform some basic sanity checking
     */
    final void validate() @safe
    {
        enforce(tileWidth > 0, "tileWidth should be more than zero");
        enforce(tileHeight > 0, "tileHeight should be more than zero");
    }

package:

    /**
     * Currently we only allow TileSet construction from the tiled package
     * but that may change in future.
     */
    this(int numTiles = 10) @trusted @nogc nothrow
    {
        _tilesGUID.reserve(numTiles);
    }

    /**
     * Set the width of each tile, in pixels
     */
    pure @property final void tileWidth(int tileWidth) @safe @nogc nothrow
    {
        _tileWidth = tileWidth;
    }

    /**
     * Set the height of each tile, in pixels
     */
    pure @property final void tileHeight(int tileHeight) @safe @nogc nothrow
    {
        _tileHeight = tileHeight;
    }

    /**
     * Set the number of tiles in this tileset
     */
    pure @property final void tileCount(int tileCount) @safe @nogc nothrow
    {
        _tileCount = tileCount;
    }

    /**
     * Set the number of columns in this tileset
     */
    pure @property final void columns(int columns) @safe @nogc nothrow
    {
        _columns = columns;
    }

    /**
     * Set the name of this tileset
     */
    pure @property final void name(string name) @safe @nogc nothrow
    {
        _name = name;
    }

    /**
     * Set the spacing between tiles in the tileset image
     */
    pure @property final void spacing(int spacing) @safe @nogc nothrow
    {
        _spacing = spacing;
    }

    /**
     * Set the margin of the tileset image
     */
    pure @property final void margin(int margin) @safe @nogc nothrow
    {
        _margin = margin;
    }

    /**
     * Set this tileset as a collection of images or simple sheet
     */
    pure @property final void collection(bool collection) @safe @nogc nothrow
    {
        _collection = collection;
    }

    /**
     * Set the tile at GID to tile T
     *
     * Note this is fully expected to happen *sequentially* by the owning
     * parser as the underlying storage is an array! This must remain
     * contiguous in memory.
     */
    pure final void setTile(uint gid, ref Tile t) @safe @nogc nothrow
    {
        _tilesGUID[gid] = t;
    }

    /**
     * Return the Tile data for the given guid
     */
    final const Tile getTile(uint guid) @trusted @nogc nothrow
    {
        if (collection)
        {
            return Tile(rectanglef(0.0f, 0.0f, 0.0f, 0.0f));
        }

        return _tilesGUID[guid];
    }

    /**
     * Ensure we have enough storage allocated ahead-of-time for all
     * tiles. Cheekily this allocates a large struct-pointer blob for
     * all of our Tile regions when not using a collection.
     */
    pure final void reserve() @trusted @nogc nothrow
    {
        if (collection)
        {
            return;
        }
        _tilesGUID.reserve(tileCount);
        _tilesGUID.length = tileCount;
    }
}
