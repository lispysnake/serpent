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
            return processMouseMove(&event.motion);
        case SDL_MOUSEBUTTONDOWN:
            return processMousePress(&event.button, true);
        case SDL_MOUSEBUTTONUP:
            return processMousePress(&event.button, false);
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
        mouseMoved.emit(MouseEvent(event));
        return false;
    }

    /**
     * Process mouse click
     */
    final bool processMousePress(SDL_MouseButtonEvent* event, bool pressed) @system
    {
        if (pressed)
        {
            mousePressed.emit(MouseEvent(event));
        }
        else
        {
            mouseReleased.emit(MouseEvent(event));
        }
        return false;
    }

public:

    /* mouse signals */

    /**
     * mouseMoved is emitted whenever the mouse has moved position
     */
    mixin Signal!(MouseEvent) mouseMoved;

    /**
     * mousePressed is emitted whenever a mouse button has been pressed
     */
    mixin Signal!(MouseEvent) mousePressed;

    /**
     * mouseReleased is emitted whenever a mouse button has been released
     */
    mixin Signal!(MouseEvent) mouseReleased;

    /**
     * Return the associated display.
     */
    pure @property final Display display() @nogc @safe nothrow
    {
        return _display;
    }
}

/**
 * MouseEvent encapsulates an SDL_MouseMotionEvent and SDL_MouseButtonEvent
 */
final struct MouseEvent
{

private:
    double _x, _y = 0;
    uint _button = 0;

package:

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

public:
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
