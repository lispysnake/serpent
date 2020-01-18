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

module serpent.event.mouse;

import bindbc.sdl;

/**
 * MouseEvent encapsulates an SDL_MouseMotionEvent and SDL_MouseButtonEvent
 */
final struct MouseEvent
{

private:
    double _x, _y = 0;
    uint _button = 0;

public:

    /**
     * Construct a new MouseEvent from an SDL_MouseMotionEvent
     */
    this(SDL_MouseMotionEvent* origin)
    {
        _x = origin.x;
        _y = origin.y;
    }

    /**
     * Construct a new MouseEvent from an SDL_MouseButtonEvent
     */
    this(SDL_MouseButtonEvent* origin)
    {
        _x = origin.x;
        _y = origin.y;
        _button = origin.button;
    }

    /**
     * Return read-only X property
     */
    pure @property const double x() @safe @nogc nothrow
    {
        return _x;
    }

    /**
     * Return read-only y property
     */
    pure @property const double y() @safe @nogc nothrow
    {
        return _y;
    }

    /**
     * Return read-only button property
     */
    pure @property const uint button() @safe @nogc nothrow
    {
        return _button;
    }
}
