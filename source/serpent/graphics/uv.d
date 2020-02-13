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

module serpent.graphics.uv;

public import gfm.math;

/**
 * UV Coordinates
 */
final struct UVCoordinates
{
package:

    vec2f u; /* u1 + u2 */
    vec2f v; /* v1 + v2 */
    float width;
    float height;

public:

    /*
     * Construct UVCoordinates from the given size (2D dimensions) and
     * clipping box.
     */
    this(float width, float height, box2f clip)
    {
        auto invWidth = 1.0f / width;
        auto invHeight = 1.0f / height;
        auto v2 = (clip.min.y + height) * invHeight;

        auto texWidth = clip.max.x - clip.min.x;
        auto texHeight = clip.max.y - clip.min.y;

        u = vec2f(clip.min.x * invWidth, (clip.min.x + texWidth) * invWidth);
        v = vec2f(clip.min.y * invHeight, (clip.min.y + texHeight) * invHeight);

    }

    /**
     * Return u1 coordinate
     */
    pragma(inline, true) pure @property final const float u1() @safe @nogc nothrow
    {
        return u.x;
    }

    /**
     * Return u2 coordinate
     */
    pragma(inline, true) pure @property final const float u2() @safe @nogc nothrow
    {
        return u.y;
    }

    /**
     * Return v1 coordinate
     */
    pragma(inline, true) pure @property final const float v1() @safe @nogc nothrow
    {
        return v.x;
    }

    /**
     * Return v2 coordinate
     */
    pragma(inline, true) pure @property final const float v2() @safe @nogc nothrow
    {
        return v.y;
    }

    /**
     * Flip the UVs vertically.
     */
    pragma(inline, true) final void flipVertical() @safe @nogc nothrow
    {
        v = vec2f(v2, v1);
    }

    /**
     * Flip the UVs horizontally
     */
    pragma(inline, true) final void flipHorizontal() @safe @nogc nothrow
    {
        u = vec2f(u2, u1);
    }
}
