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

public import gfm.math;
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
 * Note: All entities, whether 2D or 3D, have at least 3 axes.
 * These determine the X,Y, and Z coordinates. It is up to the
 * individual renderers and cameras to respect these properties.
 *
 */
class Entity
{

private:

    /**
     * A set of positions - indexed for each entity.
     */
    vec3f[] positions;

    /* TextureHandle[] texture; */

public:

    /**
     * Add a new entity. Interested implementations should override this
     * function when adding new behaviours. This also adds an interesting
     * default-spawn mechanic.
     */
    void add() @safe
    {
        positions ~= vec3f(0.0, 0.0, 0.0);
    }

    /**
     * Update the position for the entity at the given index
     */
    final void setPosition(ulong index, vec3f pos) @safe
    {
        enforce(index >= 0 && index < positions.length, "Invalid position index");
        positions[index] = pos;
    }

    /**
     * Retrieve a position for modification
     */
    pure final vec3f getPosition(ulong index) @safe
    {
        enforce(index >= 0 && index < positions.length, "Invalid position index");
        return positions[index];
    }

    /**
     * This implementation and any subclasses should now enforce reservation on
     * the underlying storage to prevent unnecessary reallocation.
     */
    void reserve(uint many) @safe nothrow
    {
        this.positions.reserve(many);
    }

    /**
     * Return the current size of the entity list.
     */
    pure @property final const ulong size() @nogc @safe nothrow
    {
        return this.positions.length;
    }
}
