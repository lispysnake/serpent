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

module serpent.context;

import std.exception : enforce;
import bindbc.bgfx;
import bindbc.sdl;

public import serpent.graphics.display;
public import serpent.game;
public import serpent.input;
public import serpent.resource;

/**
 * The Context is the main entry point into Serpent. It initialises
 * various subsystems and owns input and resource management.
 * A Context is also responsible for running the main game instance.
 */
final class Context
{

private:

    ResourceManager _resource;
    InputManager _input;
    Game _game;
    Display _display;
    bool running = false;

    /**
     * Handle any events pending in the queue and appropriately
     * dispatch them.
     */
    final void processEvents() @system
    {
        SDL_Event event;

        while (SDL_PollEvent(&event))
        {

            /* If InputManager consumes the event, don't process it here. */
            if (_input.process(&event))
            {
                continue;
            }

            switch (event.type)
            {
            case SDL_QUIT:
                running = false;
                break;
            default:
                break;
            }
        }
    }

public:

    /**
     * Construct a new Context.
     */
    this()
    {
        /* Create a display with the default size */
        _input = new InputManager(this);
        _display = new Display(640, 480);
    }

    /**
     * Run the Game within the context
     */
    int run(Game g = null)
    {
        if (g !is null)
        {
            game = g;
        }

        enforce(game !is null, "Cannot run context without a valid Game");

        if (!game.init())
        {
            return 1;
        }

        scope (exit)
        {
            _game.shutdown();
        }

        import std.stdio;

        auto renderer = bgfx_get_renderer_type();
        switch (renderer)
        {
        case bgfx_renderer_type_t.BGFX_RENDERER_TYPE_OPENGL:
            writefln("Rendering with: OpenGL");
            display.title = display.title ~ " (OpenGL)";
            break;
        case bgfx_renderer_type_t.BGFX_RENDERER_TYPE_VULKAN:
            writefln("Rendering with: Vulkan");
            display.title = display.title ~ " (Vulkan)";
            break;
        default:
            writefln("Unknown renderer");
            break;
        }

        running = true;
        display.show();

        while (running)
        {
            processEvents();
            display.render();
        }

        return 0;
    }

    /**
     * Return the context-wide ResourceManager
     */
    pure @property final ResourceManager resource() @nogc @safe nothrow
    {
        return _resource;
    }

    /**
     * Return the context-wide InputManager
     */
    pure @property final InputManager input() @nogc @safe nothrow
    {
        return _input;
    }

    /**
     * Return the Game associated with this context
     */
    pure @property final Game game() @nogc @safe nothrow
    {
        return _game;
    }

    /**
     * Return the Display associated with this Context
     */
    pure @property final Display display() @nogc @safe nothrow
    {
        return _display;
    }

    /**
     * Set the Game for this Context to run.
     */
    @property final Context game(Game g) @safe
    {
        enforce(g !is null, "Game canot be null");
        enforce(_game is null, "Cannot change Game while running");
        _game = g;
        _game.context = this;
        return this;
    }
}
