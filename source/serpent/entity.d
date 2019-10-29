/*
 * This file is part of serpent.
 *
 * Copyright © 2019 Lispy Snake, Ltd.
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

module serpent.entity;

import gfm.math;
import std.exception;

/**
 * Logically a world (or scene graph) is composed of entities. However
 * in a bid for optimisation we avoid graph behaviours in entity composition,
 * and instead rely on expression of entities as data, leaving the renderer
 * to do its job.
 *
 * In order to optimise for your application, it is recommended that
 * you derive your individual Entity definitions from this class and
 * add any specific data blocks required. For example, you may want
 * to add health aspects.
 *
 * You should mark any overridden methods as *final* as a hint to the
 * D compiler to ensure optimisation.
 *
 */
class Entity(T, int n)
{

private:

    /**
     * A set of positions - indexed for each entity.
     */

    static if (n == 2)
    {
        Vector!(T, 2)[] positions;
    }
    static if (n == 3)
    {
        Vector!(T, 3)[] positions;
    }
    else
    {
        static assert("Entity should be constructed with 2 or 3 axes only");
    }

    alias _vecType = Vector!(T, n);

    /* TextureHandle[] texture; */

public:
    @disable this();

    /**
     * Add a new entity.
     */
    void add()
    {
        static if (n == 2)
        {
            positions ~= _vecType(0, 0);
        }
        else
        {
            positions ~= _vecType(0, 0, 0);
        }
    }

    /**
     * Update the position for the entity at the given index
     */
    final void setPosition(ulong index, _vecType pos) @safe
    {
        enforce(index > 0 && index < positions.length, "Invalid position index");
        positions[index] = pos;
    }

    /**
     * Retrieve a position for modification
     */
    _vecType getPosition(ulong index) @safe
    {
        enforce(index > 0 && index < positions.length, "Invalid position index");
        return positions[index];
    }

    /**
     * This implementation and any subclasses should now enforce reservation on
     * the underlying storage to prevent unnecessary reallocation.
     */
    void reserve(uint many)
    {
        this.positions.reserve(many);
    }
}

/**
 * 2D Entities expressed with 2 axes (x, y)
 */
alias Entity2D = Entity!(float, 2);

/**
 * 3D Entities expressed with 3 axes (x, y, z)
 */
alias Entity3D = Entity!(float, 3);
