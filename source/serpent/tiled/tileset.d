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

/**
 * A TileSet describes the images, or drawable regions, of a Map.
 * Internally this can be achieved with a collection of images, or by
 * splitting a single image into many subregions.
 */
final class TileSet
{

private:

    string _name = "";
    int _tileWidth;
    int _tileHeight;
    int _tileCount;
    int _columns;

public:

    @disable this();

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
}
