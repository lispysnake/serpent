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
public import serpent.graphics.texture;

/**
 * The underlying storage defines how to actually draw a Tile
 * Each Tile is stored according to the guid (index)
 */
final struct Tile
{
    box2f region; /**<Defines the renderable region for the tile */
    Texture texture = null; /**<The texture to draw */

    this(box2f region) @safe @nogc nothrow
    {
        this.region = region;
    }

    this(Texture texture) @safe @nogc nothrow
    {
        this.texture = texture;
        this.region = texture.clip();
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
    int _firstGID = 0; /* Only relevant to maps with multiple gids */

    Array!Tile _tilesGUID; /*GUID-indexed tile array */
    Tile[int] _tilesID; /* ID-to-Tile mapping (slower) */
    string _baseDir = ".";

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
     * Return the firstGID (usually 0) for the tilemap
     */
    pure @property final const int firstGID() @safe @nogc nothrow
    {
        return _firstGID;
    }

    /**
     * Return the base directory of the tileset for loading relative
     * assets.
     */
    pure @property final const string baseDir() @safe @nogc nothrow
    {
        return _baseDir;
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
    final void setTile(uint gid, ref Tile t) @safe nothrow
    {
        if (collection)
        {
            _tilesID[gid] = t;
            return;
        }
        _tilesGUID[gid - firstGID] = t;
    }

    /**
     * Return the Tile data for the given guid
     */
    final const immutable(Tile) getTile(uint guid) @trusted
    {
        if (collection)
        {
            return cast(immutable(Tile)) _tilesID[guid - _firstGID];
        }

        return cast(immutable(Tile)) _tilesGUID[guid - _firstGID];
    }

    /**
     * Update the firstGID property
     */
    pure @property final void firstGID(int firstGID) @safe @nogc nothrow
    {
        _firstGID = firstGID;
    }

    /**
     * Update the baseDir property
     */
    pure @property final void baseDir(string dir) @safe @nogc nothrow
    {
        this._baseDir = dir;
    }

    /**
     * Ensure we have enough storage allocated ahead-of-time for all
     * tiles. Cheekily this allocates a large struct-pointer blob for
     * all of our Tile regions when not using a collection.
     */
    final void reserve() @trusted @nogc nothrow
    {
        if (collection)
        {
            return;
        }
        _tilesGUID.reserve(tileCount);
        _tilesGUID.length = tileCount;
    }
}
