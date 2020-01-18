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

module serpent.camera;
import serpent.scene;

public import serpent.camera.orthographic;

import gfm.math;
import std.exception : enforce;
import bindbc.bgfx;

/**
 * WorldOrigin allows us to specify a different WorldOrigin than
 * the default coordinate system, re-mapping from bottom-left to top-left
 */
enum WorldOrigin
{
    TopLeft = 0,
    BottomLeft,
};

/**
 * The Camera class is responsible for providing the correct positions
 * for an Entity to be rendered. Without a camera, the correct perpective
 * and positions will not be used.
 *
 * Typically you need to instaniate a subclass of Camera for it to be
 * effective.
 */
abstract class Camera
{

private:
    Scene _scene;
    string _name;
    mat4x4f _projection = mat4x4f.identity();
    mat4x4f _view = mat4x4f.identity();
    mat4x4f _combined = mat4x4f.identity();
    mat4x4f _inverse = mat4x4f.identity();
    WorldOrigin _worldOrigin = WorldOrigin.BottomLeft;

public:

    /**
     * Apply the Camera transformation prior to rendering.
     */
    final void apply() @system @nogc nothrow
    {
        bgfx_set_view_transform(0, view.ptr, projection.ptr);
    }

    /**
     * Update Camera for display
     *
     * Implementations should use this to set the view and projection
     * properties. As such, directly setting a view or projection
     * matrix is not recommended, as it will likely be discarded.
     */
    abstract void update() @nogc @safe nothrow;

    /**
     * Return the Scene associated with this Camera
     */
    pure @property final Scene scene() @nogc @safe nothrow
    {
        return _scene;
    }

    /**
     * Set the Scene associated with this Camera
     */
    @property final void scene(Scene s) @system
    {
        enforce(s !is null, "Should not have a null Scene");
        if (s == _scene)
        {
            return;
        }
        _scene = s;
        this.update();
    }

    /**
     * Return the name for this camera
     */
    @property final string name() @nogc @safe nothrow
    {
        return _name;
    }

    /**
     * Set the Camera name
     */
    @property final void name(string s) @safe
    {
        enforce(s !is null, "Camera name cannot be null");
        _name = s;
    }

    /**
     * Return the projection matrix for this camera
     */
    pure @property final mat4x4f projection() @safe @nogc nothrow
    {
        return _projection;
    }

    /**
     * Set the projection matrix for this camera
     */
    @property final void projection(mat4x4f p) @safe @nogc nothrow
    {
        _projection = p;
    }

    /**
     * Return the view matrix for this camera
     */
    pure @property final mat4x4f view() @safe @nogc nothrow
    {
        return _view;
    }

    /**
     * Set the view matrix for this camera
     */
    @property final void view(mat4x4f v) @safe @nogc nothrow
    {
        _view = v;
    }

    /**
     * Return the combined view/projection matrix for this camera
     */
    pure @property final mat4x4f combined() @safe @nogc nothrow
    {
        return _combined;
    }

    /**
     * Set the combined view/projection matrix for this camera
     */
    @property final void combined(mat4x4f v) @safe @nogc nothrow
    {
        _combined = v;
    }

    /**
     * Return the inverse combined view/projection matrix for this camera
     */
    pure @property final mat4x4f inverse() @safe @nogc nothrow
    {
        return _inverse;
    }

    /**
     * Set the inverse combined view/projection matrix for this camera
     */
    @property final void inverse(mat4x4f v) @safe @nogc nothrow
    {
        _inverse = v;
    }

    /**
     * Return the worldOrigin for this camera
     */
    pure @property final WorldOrigin worldOrigin() @safe @nogc nothrow
    {
        return _worldOrigin;
    }

    /**
     * Set the worldOrigin used by this camera
     */
    @property final void worldOrigin(WorldOrigin o) @safe @nogc nothrow
    {
        if (_worldOrigin == o)
        {
            return;
        }
        _worldOrigin = o;
        update();
    }

    /**
     * Unproject the inputted real-world coordinates to 3D-space
     */
    final vec3f unproject(const ref vec3f point) @safe
    {
        auto x = 0.0f; /* Viewport X */
        auto y = 0.0f; /* Viewport Y */
        auto width = cast(float) scene.display.width;
        auto height = cast(float) scene.display.height;

        float objY = point.y;
        if (_worldOrigin == WorldOrigin.TopLeft)
        {
            objY = height - objY;
        }

        vec4f normal = vec4f((point.x - x) / width * 2.0f - 1.0f,
                (objY - y) / height * 2.0f - 1.0f, point.z * 2.0f - 1.0f, 1.0f);

        vec4f coord = inverse() * normal;
        if (coord.w != 0.0f)
        {
            coord.w = 1.0f / coord.w;
        }

        return vec3f(coord.x * coord.w, coord.y * coord.w, coord.z * coord.w);
    }
}
