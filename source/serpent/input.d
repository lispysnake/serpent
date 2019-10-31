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

module serpent.input;

import serpent.display;

import bindbc.sdl;

public import std.signals;

/**
 * The InputManager is managed by a Display and provides a way to access
 * input events. Internally it is seeded by events from the SDL event
 * queue.
 */
final class InputManager
{

private:

    Display _display;

package:

    /**
     * Construct a new InputManager. Only a display can do this.
     */
    this(Display display)
    {
        _display = display;
    }

    /**
     * Feed the InputManager an SDL_Event.
     * From here, we'll perform the appropriate dispatches.
     */
    final bool process(SDL_Event* event) @system
    {
        switch (event.type)
        {
        case SDL_KEYUP:
        case SDL_KEYDOWN:
            return processKey(event);
        case SDL_MOUSEMOTION:
            return processMouseMove(cast(SDL_MouseMotionEvent*) event);
        case SDL_MOUSEBUTTONDOWN:
            return processMousePress(cast(SDL_MouseButtonEvent*) event, true);
        case SDL_MOUSEBUTTONUP:
            return processMousePress(cast(SDL_MouseButtonEvent*) event, false);
        default:
            return false;
        }
    }

private:

    /**
     * Process a key event
     */
    final bool processKey(SDL_Event* event) @system
    {
        return false;
    }

    /**
     * Process mouse motion
     */
    final bool processMouseMove(SDL_MouseMotionEvent* event) @system
    {
        mouseMoved.emit(event.x, event.y);
        return false;
    }

    /**
     * Process mouse click
     */
    final bool processMousePress(SDL_MouseButtonEvent* event, bool pressed) @system
    {
        if (pressed)
        {
            mousePressed.emit(event.button, event.x, event.y);
        }
        else
        {
            mouseReleased.emit(event.button, event.x, event.y);
        }
        return false;
    }

public:

    mixin Signal!(double, double) mouseMoved;
    mixin Signal!(uint, double, double) mousePressed;
    mixin Signal!(uint, double, double) mouseReleased;

    /**
     * Return the associated display.
     */
    pure @property final Display display() @nogc @safe nothrow
    {
        return _display;
    }
}
