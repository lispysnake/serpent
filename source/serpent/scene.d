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
import std.string : format;

import serpent.camera;
import serpent.display;
import serpent.entity;

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
    Entity2D[] e2d;
    Entity3D[] e3d;
    Camera[string] cameras;
    Camera _camera;
    Display _display;

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
     * Add a 2D entity to this scene.
     * It should be noted that a singular Entity2D may be composed
     * of many instances.
     */
    final void addEntity(Entity2D e) @safe
    {
        this.e2d ~= e;
    }

    /**
     * Add a 3D Entity to this scene.
     * It should be noted that a singular Entity3D may be composed
     * of many instances.
     */
    final void addEntity(Entity3D e) @safe
    {
        this.e3d ~= e;
    }

    /**
     * Add a new Camera to the scene.
     *
     * If no camera is present, the new Camera will be activated
     * as the default.
     */
    final void addCamera(Camera c) @safe
    {
        enforce(c !is null, "Camera cannot be null");
        enforce(c.name !in cameras, "Cannot add duplicate Camera: '%s'".format(c.name));
        c.scene = this;
        this.cameras[c.name] = c;
        if (_camera is null)
        {
            _camera = c;
        }
    }

    /**
     * Return the list of visible 2D entities
     */
    @property final Entity2D[] visibleEntities2D() @nogc @safe nothrow
    {
        /* TODO: Only return visible, not all. */
        return this.e2d;
    }

    /**
     * Return the list of visible 3D entities
     */
    @property final Entity3D[] visibleEntities3D() @nogc @safe nothrow
    {
        /* TODO: Only return visible, not all. */
        return this.e3d;
    }

    /**
     * Return the scene name. It cannot be modified after creation
     */
    @property final string name() @nogc @safe nothrow
    {
        return _name;
    }

    @property final Camera camera() @nogc @safe nothrow
    {
        return _camera;
    }

    @property final void camera(Camera c) @safe
    {
        enforce(c.name in cameras, "Cannot set Camera before adding it");
        enforce(c !is null, "Camera must not be null");
        _camera = c;
    }

    @property final void camera(string s) @safe
    {
        enforce(s in cameras, "Cannot set unknown camera");
        _camera = cameras[s];
    }

    /**
     * Set the Display for this Scene
     */
    @property final void display(Display d) @safe
    {
        enforce(d !is null, "Display cannot be null");
        this._display = d;
    }

    /**
     * Return the Display for this scene
     */
    @property final Display display() @safe @nogc nothrow
    {
        return _display;
    }
}
