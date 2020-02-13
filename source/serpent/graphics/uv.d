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

public:

    /**
     * Construct UVCoordinates from the given size (2D dimensions)
     */
    this(box2f size)
    {
        this(size, size);
    }

    /**
     * Construct UVCoordinates from the given size (2D dimensions) and
     * clipping box.
     */
    this(box2f size, box2f clip)
    {
        auto invWidth = 1.0f / size.max.x;
        auto invHeight = 1.0f / size.max.y;
        auto v2 = (clip.min.y + size.max.y) * invHeight;

        u = vec2f(clip.min.x * invWidth, (clip.min.x + size.max.x) * invWidth);
        v = vec2f(clip.min.y * invHeight, (clip.min.y + size.max.y) * invHeight);
    }

    /**
     * Return u1 coordinate
     */
    pure @property final const float u1() @safe @nogc nothrow
    {
        return u.x;
    }

    /**
     * Return u2 coordinate
     */
    pure @property final const float u2() @safe @nogc nothrow
    {
        return u.y;
    }

    /**
     * Return v1 coordinate
     */
    pure @property final const float v1() @safe @nogc nothrow
    {
        return v.x;
    }

    /**
     * Return v2 coordinate
     */
    pure @property final const float v2() @safe @nogc nothrow
    {
        return v.y;
    }

    /**
     * Flip the UVs vertically.
     */
    final void flipVertical() @safe @nogc nothrow
    {
        v = vec2f(1.0f, 1.0f) - v;
    }

    /**
     * Flip the UVs horizontally
     */
    final void flipHorizontal() @safe @nogc nothrow
    {
        u = vec2f(1.0f, 1.0f) - u;
    }
}
