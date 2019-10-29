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

module serpent.scene;

import std.exception;

enum SceneMode
{
    TwoDimensional = 2,
    ThreeDimensional = 3,
};

/**
 * A Game is composed of multiple scenes which in turn contain entities.
 * This is to provide a parallel programming experience to the typical
 * scene-graph driven Entity Component System seen in other frameworks
 * or engines.
 *
 * In our case a Scene maintains the list of entities in their total
 * state along with a set of *renderable* entities for display.
 */
final class Scene
{

private:
    string _name;

public:

    @disable this();

    /**
     * Construct a new scene with the given name
     */
    this(string name) @safe
    {
        enforce(name !is null, "Name must be valid");
        _name = name;
    }

    /**
     * Return the scene name. It cannot be modified after creation
     */
    @property final string name() @nogc @safe nothrow
    {
        return _name;
    }
}
