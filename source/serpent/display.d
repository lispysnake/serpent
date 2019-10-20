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

module serpent.display;

import bindbc.sdl;
import bindbc.bgfx;
import std.string : toStringz, format;

import serpent : SystemException;

/**
 * The Display handler
 *
 * The Display class is responsible for the main lifecycle of the game.
 * As a core part of the framework, it is the main entry point into
 * running and developing games.
 *
 * It will initialise dependent subsystems and prepare the window for
 * construction within the run routine.
 */
final class Display
{

private:
    int height;
    int width;
    SDL_Window* window;
    bool running = false;
    string _title = "serpent";
    bgfx_init_t b_init;

private:

    /**
     * Helper to initialise our dependent systems.
     */
    final void init() @system
    {
        const auto init_flags = SDL_INIT_VIDEO | SDL_INIT_GAMECONTROLLER | SDL_INIT_HAPTIC;
        if (SDL_Init(init_flags) != 0)
        {
            throw new SystemException("Failed to initialise SDL: %s".format(SDL_GetError()));
        }
        bgfx_init_ctor(&b_init);
    }

    /**
     * Helper to shutdown our dependent systems.
     */
    final void shutdown() @system @nogc nothrow
    {
        bgfx_shutdown();
        SDL_Quit();
    }

public:

    /** Must have window attributes to construct */
    @disable this();

    /**
     * Construct a new Display
     *
     * This will construct a new display with the given width and height.
     */
    final this(int width, int height) @system
    {
        init();
        this.width = width;
        this.height = height;
    }

    final ~this() @system @nogc nothrow
    {
        if (window)
        {
            SDL_DestroyWindow(window);
        }
        shutdown();
    }

    /**
     * Bring up windowing resources and start the main game loop.
     */
    final int run() @system
    {
        auto flags = SDL_WINDOW_SHOWN;

        window = SDL_CreateWindow(toStringz(_title), SDL_WINDOWPOS_UNDEFINED,
                SDL_WINDOWPOS_UNDEFINED, width, height, flags);
        if (!window)
        {
            throw new SystemException("Couldn't create Window: %s".format(SDL_GetError()));
        }
        return 0;
    }

    /**
     * Return the currently set window title
     */
    @property string title() @nogc @safe nothrow
    {
        return _title;
    }

    /**
     * Set the window title.
     */
    @property void title(string title) @system nothrow
    {
        this._title = title;
        if (!running)
        {
            return;
        }
        SDL_SetWindowTitle(window, toStringz(_title));
    }
}
