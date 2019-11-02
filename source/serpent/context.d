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
import std.file;
import std.path;

public import serpent.graphics.display;
public import serpent.app;
public import serpent.info;
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
    App _app;
    Display _display;
    Info _info;
    bool _running = false;

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

            /* Likewise, see if the display consumes it */
            if (_display.process(&event))
            {
                continue;
            }

            switch (event.type)
            {
            case SDL_QUIT:
                _running = false;
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
        _display = new Display(this, 640, 480);
        _resource = new ResourceManager(this, dirName(thisExePath()));
        _info = new Info();
    }

    /**
     * Run the App within the context
     */
    int run(App a = null)
    {
        if (a !is null)
        {
            app = a;
        }

        enforce(app !is null, "Cannot run context without a valid App");

        _display.prepare();

        if (!app.init())
        {
            return 1;
        }

        scope (exit)
        {
            _app.shutdown();
        }

        _info.update();

        enforce(info.driverType != DriverType.Unsupported,
                "Unsupported underlying driver. Please report this.");

        import std.stdio;
        import std.conv : to;

        display.title = display.title ~ " (" ~ to!string(info.driverType) ~ ")";

        _running = true;
        display.show();

        while (_running)
        {
            processEvents();

            _app.update();

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
    pure @property final App app() @nogc @safe nothrow
    {
        return _app;
    }

    /**
     * Return the Display associated with this Context
     */
    pure @property final Display display() @nogc @safe nothrow
    {
        return _display;
    }

    /**
     * Return the Info object associated with this Context
     */
    pure @property final Info info() @nogc @safe nothrow
    {
        return _info;
    }

    /**
     * Return true if currently running
     */
    pure @property final bool running() @nogc @safe nothrow
    {
        return _running;
    }

    /**
     * Set the Game for this Context to run.
     */
    @property final Context app(App a) @safe
    {
        enforce(a !is null, "App canot be null");
        enforce(_app is null, "Cannot change App while running");
        _app = a;
        _app.context = this;
        return this;
    }
}
