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

private:

    /**
     * Helper to initialise our dependent systems.
     */
    void init()
    {
        import std.string : format;

        const auto init_flags = SDL_INIT_VIDEO | SDL_INIT_GAMECONTROLLER | SDL_INIT_HAPTIC;
        if (SDL_Init(init_flags) != 0)
        {
            throw new SystemException("Failed to initialise SDL: %s".format(SDL_GetError()));
        }
    }

    /**
     * Helper to shutdown our dependent systems.
     */
    void shutdown()
    {
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
    this(int width, int height)
    {
        init();
        this.width = width;
        this.height = height;
    }

    ~this()
    {
        shutdown();
    }

}
