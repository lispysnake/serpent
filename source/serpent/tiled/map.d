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

module serpent.tiled.map;

import std.exception : enforce;
public import std.container.array;

public import serpent.tiled.layer;
public import serpent.tiled.tileset;

/**
 * A Tiled map can have numerous orientations.
 * Orthogonal is the most commonly seen (top-down/side-on)
 */
final enum MapOrientation
{
    Orthogonal = 0,
    Isometric,
    Staggered,
    Hexagonal,
    Unknown,
};

/**
 * A Map is any kind of game map that is internally represented as a
 * sequence of tiles in 2D space.
 */
final class Map
{

private:
    int _tileHeight = 0;
    int _tileWidth = 0;
    int _width = 0;
    int _height = 0;
    Array!MapLayer _layers;
    Array!TileSet _tilesets;
    string _baseDir = ".";
    MapOrientation _orientation = MapOrientation.Unknown;

package:

    /**
     * Set the orientation
     */
    pure final @property void orientation(MapOrientation o) @safe @nogc nothrow
    {
        _orientation = o;
    }

    /**
     * Set the width
     */
    pure final @property void width(uint w) @safe @nogc nothrow
    {
        _width = w;
    }

    /**
     * Set the height
     */
    pure final @property void height(uint h) @safe @nogc nothrow
    {
        _height = h;
    }

    /**
     * Set the tileWidth
     */
    pure final @property void tileWidth(uint w) @safe @nogc nothrow
    {
        _tileWidth = w;
    }

    /**
     * Set the tileHeight
     */
    pure final @property void tileHeight(uint h) @safe @nogc nothrow
    {
        _tileHeight = h;
    }

    /**
     * Set the base directory for the map
     */
    pure final @property void baseDir(string dir) @safe @nogc nothrow
    {
        _baseDir = dir;
    }

    this() @safe @nogc nothrow
    {
        tileWidth = 0;
        tileHeight = 0;
        width = 0;
        height = 0;
    }

public:

    this(uint tw, uint th, uint w, uint h) @safe @nogc nothrow
    {
        tileWidth = tw;
        tileHeight = th;
        width = w;
        height = h;
    }

    /**
     * Get the tileHeight
     */
    pure const final @property uint tileHeight() @safe @nogc nothrow
    {
        return _tileHeight;
    }

    /**
     * Get the tileWidth
     */
    pure const final @property uint tileWidth() @safe @nogc nothrow
    {
        return _tileWidth;
    }

    /**
     * Get the height
     */
    pure const final @property uint height() @safe @nogc nothrow
    {
        return _height;
    }

    /**
     * Get the width
     */
    pure const final @property uint width() @safe @nogc nothrow
    {
        return _width;
    }

    /**
     * Get the orientation
     */
    pure const final @property MapOrientation orientation() @safe @nogc nothrow
    {
        return _orientation;
    }

    /**
     * Append a map layer
     */
    final void appendLayer(MapLayer layer) @trusted
    {
        _layers.insert(layer);
    }

    /**
     * Add a tileset to this map
     */
    final void appendTileSet(TileSet set) @trusted
    {
        _tilesets.insert(set);
    }

    /**
     * Validate the map configuration
     */
    final void validate() @safe
    {
        enforce(tileHeight > 0, "Map tileheight should be more than 0");
        enforce(tileWidth > 0, "Map tilewidth should be more than 0");
        enforce(height > 0, "Map height should be more than 0");
        enforce(width > 0, "Map width should be more than 0");
        enforce(orientation != MapOrientation.Unknown, "Uknknown Map orientation");
    }

    /**
     * Read-only access to underlying layers.
     */
    pure const final @property immutable(Array!MapLayer) layers() @trusted
    {
        return cast(immutable(Array!MapLayer)) _layers;
    }

    /**
     * Return base directory for the map to load relative assets
     */
    pure const final @property string baseDir() @safe @nogc nothrow
    {
        return _baseDir;
    }

    /**
     * Find the relevant tileset for the given gid
     */
    const final immutable(TileSet) findTileSet(uint32_t gid) @trusted
    {
        if (gid < 1)
        {
            return null;
        }

        foreach (ref set; _tilesets)
        {
            if (gid >= set.firstGID)
            {
                return cast(immutable(TileSet)) set;
            }
        }
        return null;
    }
}
