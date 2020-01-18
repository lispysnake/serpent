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

module serpent.event.keyboard;

public import std.stdint;

import bindbc.sdl;

/**
 * KeyboardEvent encapsulates an SDL_KeyboardEvent
 */
final struct KeyboardEvent
{

private:
    SDL_Keycode _sym;
    SDL_Scancode _scan;
    uint16_t _mod;

public:

    /**
     * Construct a new KeyboardEvent from an SDL_KeyboardEvent
     */
    this(SDL_KeyboardEvent* origin)
    {
        this._sym = origin.keysym.sym;
        this._scan = origin.keysym.scancode;
        this._mod = origin.keysym.mod;
    }

    /**
     * Return read-only key/symbol for this event (virtual key)
     */
    pure @property const SDL_Keycode symbol() @safe @nogc nothrow
    {
        return _sym;
    }

    /**
     * Return read-only scancode for this event (physical mapping)
     */
    pure @property const SDL_Scancode scancode() @safe @nogc nothrow
    {
        return _scan;
    }

    pure @property const uint16_t modifiers() @safe @nogc nothrow
    {
        return _mod;
    }

}
