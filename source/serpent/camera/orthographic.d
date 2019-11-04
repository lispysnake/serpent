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

module serpent.camera.orthographic;

import serpent.camera;

import gfm.math;

/**
 * An implementation of the Camera using Orthographic Perspective.
 * This may be used for 2D and 3D games, but is highly recommended
 * for 2D games.
 *
 * Largely inspired by fragworks/frag camera implementation
 */
class OrthographicCamera : Camera
{

private:
    float _zoomLevel = 1.0f;
    float _nearPlane = 0.0f;
    float _farPlane = 1.0f;

    bool _invertedY = false;

    /**
     * Camera position within 3D space
     */
    static const vec3f position = vec3f(0.0f, 0.0f, 0.0f);

    /**
     * Direction of camera (straight forward)
     */
    vec3f direction = vec3f(0.0f, 0.0f, 1.0f);

    /**
     * Change up for X,Y world coordinates
     */
    vec3f up = vec3f(0.0f, 1.0f, 0.0f);

public:

    /**
     * Construct a new OrthographicCamera with an optional name.
     */
    this(string name = "default")
    {
        this.name = name;
    }

    /**
     * Update our matrix based on the display
     */
    final override void update() @nogc @safe nothrow
    {
        if (invertedY)
        {
            up.y = -1.0;
            direction.z = 1.0f;
        }
        else
        {
            up.y = 1.0f;
            direction.z = 1.0f;
        }

        vec3f eyes = position + direction;

        projection = mat4x4f.orthographic(zoomLevel * scene.display.width,
                zoomLevel * -scene.display.width, zoomLevel * -scene.display.height,
                zoomLevel * scene.display.height, nearPlane, farPlane);
        view = mat4x4f.lookAt(position, eyes, up);

        combined = projection * view;
        inverse = combined.inverse();
    }

    /**
     * Return the camera zoomLevel
     */
    pure @property final float zoomLevel() @nogc @safe nothrow
    {
        return _zoomLevel;
    }

    /**
     * Set the camera zoomLevel
     */
    @property final void zoomLevel(float z) @nogc @safe nothrow
    {
        if (_zoomLevel == z)
        {
            return;
        }
        _zoomLevel = z;
        update();
    }

    /**
     * Return the nearPlane level
     */
    pure @property final float nearPlane() @nogc @safe nothrow
    {
        return _nearPlane;
    }

    /**
     * Set the nearPlane level
     */
    @property final void nearPlane(float p) @nogc @safe nothrow
    {
        if (_nearPlane == p)
        {
            return;
        }
        _nearPlane = p;
        update();
    }

    /**
     * Return the farPlane level
     */
    pure @property final float farPlane() @nogc @safe nothrow
    {
        return _farPlane;
    }

    /**
     * Set the farPlane level
     */
    @property final void farPlane(float p) @nogc @safe nothrow
    {
        if (_farPlane == p)
        {
            return;
        }
        _farPlane = p;
        update();
    }

    /**
     * Returns whether invertedY is set
     */
    pure @property final bool invertedY() @nogc @safe nothrow
    {
        return _invertedY;
    }

    /**
     * Set the invertedY property.
     */
    @property final void invertedY(bool b) @nogc @safe nothrow
    {
        if (_invertedY == b)
        {
            return;
        }
        _invertedY = b;
        update();
    }
}
