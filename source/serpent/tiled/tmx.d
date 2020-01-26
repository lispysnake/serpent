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

module serpent.tiled.tmx;

public import serpent.tiled.map;

import std.file;
import std.xml;
import std.exception : enforce;
import std.conv : to;

/**
 * The TMXParser exists solely as a utility class to load TMX files.
 * Currently this is a janky utility class until such point as we have
 * a proper loader mechanism in place.
 */
final class TMXParser
{

private:

    /**
     * Begin parsing the actual XML document.
     */
    static final Map parseMap(Document doc) @safe
    {
        enforce(doc.tag.name == "map", "First element should be <map>");
        auto map = new Map();

        /* Grab our basic map attributes */
        foreach (attr, attrValue; doc.tag.attr)
        {
            switch (attr)
            {
            case "tileheight":
                map.tileHeight = to!int(attrValue);
                break;
            case "tilewidth":
                map.tileWidth = to!int(attrValue);
                break;
            case "width":
                map.width = to!int(attrValue);
                break;
            case "height":
                map.height = to!int(attrValue);
                break;
            case "orientation":
                switch (attrValue)
                {
                case "orthogonal":
                    map.orientation = MapOrientation.Orthogonal;
                    break;
                case "isometric":
                    map.orientation = MapOrientation.Isometric;
                    break;
                case "staggered":
                    map.orientation = MapOrientation.Staggered;
                    break;
                case "hexagonal":
                    map.orientation = MapOrientation.Hexagonal;
                    break;
                default:
                    enforce("Unknown orientation in Map");
                    break;
                }
                break;
            default:
                break;
            }
        }

        map.validate();

        return map;
    }

public:

    /**
     * As a static utility class, there is no point in constructing us.
     */
    @disable this();

    /**
     * Load a map from the given path.
     * In future we need to use crossplatform path + loading capabilities.
     */
    static final Map loadTMX(string path) @trusted
    {
        auto r = cast(string) std.file.read(path);
        std.xml.check(r);

        auto doc = new Document(r);
        return parseMap(doc);
    }
}
