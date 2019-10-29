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

import bindbc.bgfx;
import gfm.math;

/**
 * An implementation of the Camera using Orthographic Perspective.
 * This may be used for 2D and 3D games, but is highly recommended
 * for 2D games.
 */
class OrthographicCamera : Camera
{

public:

    /**
     * Construct a new OrthographicCamera with an optional name.
     */
    this(string name = "default")
    {
        this.name = name;
    }

    /**
     * Apply orthographic perspective
     */
    final override void apply() @nogc @system nothrow
    {
        auto matrix = matrix();
        auto identity = identity();
        bgfx_set_view_transform(0, cast(const void*)&identity, cast(const void*)&matrix);
    }

    /**
     * Update our matrix based on the display
     */
    final override void update() @nogc @safe nothrow
    {
        // TODO: Set aspect ratio correctly from the display width / height
        auto ratio = cast(float) scene.display.width / cast(float) scene.display.height;
        matrix = matrix.orthographic(ratio, -ratio, 1.0f, -1.0f, -1.0f, 1.0f);
    }
}
