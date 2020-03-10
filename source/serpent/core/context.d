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

module serpent.core.context;

import std.exception : enforce;
import bindbc.bgfx;
import bindbc.sdl;
import std.file;
import std.path;
import std.parallelism;

import serpent.core.builtin;
import serpent.core.entity;
import serpent.core.group;
import serpent.core.policy;
import serpent.core.transform;
import core.time : MonoTime;

public import serpent.graphics.display;
public import serpent.app;
public import serpent.input;

public import core.time : Duration;

/**
 * Wrap groups with RW attribute to protect insertion order and
 * class size to prevent ugly casts
 */
final struct GroupRunner
{
    bool rw;
    string name;
    GroupLayer layer;
}

/**
 * Can contain only a Read-Only or Read-Write group.
 * Luckily, they're basically the same size. This just handles
 * type preservation for us.
 */
final union GroupLayer
{
    Group!ReadOnly ro_group;
    Group!ReadWrite rw_group;
}

/**
 * The Context is the main entry point into Serpent. It initialises
 * various subsystems and owns input and resource management.
 * A Context is also responsible for running the main game instance.
 */
final class Context
{

private:

    InputManager _input;
    EntityManager _entity;
    App _app;
    Display _display;
    __gshared bool _running = false;

    /* Scheduling cruft */
    GroupRunner[] groups;
    TaskPool tp;
    Group!ReadWrite _systemGroup;
    Group!ReadOnly _renderGroup;

    Duration _ticks;
    float _frameTime;

    /**
     * Bootstrap (sequentially) all processor groups before
     * we begin displaying anything.
     */
    final void bootstrapGroups() @system
    {
        foreach (ref g; groups)
        {
            if (g.rw)
            {
                g.layer.rw_group.bootstrap();
            }
            else
            {
                g.layer.ro_group.bootstrap();
            }
        }
    }

    /**
     * Step through groups for scheduled executions
     */
    final void scheduledExecution() @system
    {
        foreach (ref g; groups)
        {
            if (g.rw)
            {
                g.layer.rw_group.run(this.tp);
            }
            else
            {
                g.layer.ro_group.run(this.tp);
            }
        }
    }

    /**
     * Tell all groups to finish up while the context is valid.
     */
    final void finishGroups() @system
    {
        foreach (ref g; groups)
        {
            if (g.rw)
            {
                g.layer.rw_group.finish();
            }
            else
            {
                g.layer.ro_group.finish();
            }
        }
    }

public:

    /**
     * Construct a new Context.
     */
    this()
    {
        /* Sort out the scheduling cruft */
        tp = new TaskPool();
        tp.isDaemon = false;

        /* Core ECS */
        _entity = new EntityManager();

        /* Configure must-have storage */
        _entity.registerComponent!TransformComponent;

        _systemGroup = new Group!ReadWrite("system").add(new InputProcessor)
            .add(new AppUpdateProcessor());
        addGroup(_systemGroup);

        /* Create a display with the default size */
        _input = new InputManager(this);
        _display = new Display(this, 640, 480);
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

        /* Bootstrap processor groups before app loads anything */
        bootstrapGroups();

        auto view = View!ReadWrite(this.entity);
        if (!app.bootstrap(view))
        {
            return 1;
        }

        /* Ensure EntityManager is always built */
        if (!_entity.built)
        {
            _entity.build();
        }

        /* Get the basics in */
        _entity.step();

        scope (exit)
        {
            tp.finish(true);
            _app.shutdown();
        }

        enforce(display.scene !is null, "Must have a scene to run");
        enforce(display.scene.camera !is null, "Need at least one camera");

        _running = true;
        display.visible = true;

        /* Time prior to first tick */
        auto timeStart = MonoTime.currTime();

        /**
         * Main run loop
         */
        while (_running)
        {
            auto timeNow = MonoTime.currTime();
            _ticks = timeNow - timeStart;
            long timeNS;
            _ticks.split!("nsecs")(timeNS);
            _frameTime = timeNS / 1_000_000.0f;

            /* Force stepping through the Entity system */
            _entity.step();
            scheduledExecution();
            _display.pipeline.render(View!ReadOnly(entity));

            timeStart = timeNow;
        }

        _entity.clear();
        finishGroups();
        _display.pipeline.shutdown();

        return 0;
    }

    /**
     * Add a group to the execution context. The original insertion
     * order is preserved.
     */
    final void addGroup(Group!ReadWrite rw) @trusted
    {
        enforce(!running, "Cannot add a Group to a running Context");
        auto gr = GroupRunner(true);
        gr.name = rw.name;
        gr.layer.rw_group = rw;
        rw.context = this;
        groups ~= gr;
    }

    /**
     * Add a group to the execution context. The original insertion
     * order is preserved.
     */
    final void addGroup(Group!ReadOnly ro) @trusted
    {
        enforce(!running, "Cannot add a Group to a running Context");
        auto gr = GroupRunner(false);
        gr.name = ro.name;
        gr.layer.ro_group = ro;
        ro.context = this;
        groups ~= gr;
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
     * Return true if currently running
     */
    @property final bool running() @nogc @trusted nothrow
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

    /**
     * Returns the Group used within the first stage of frame-execution.
     * Internally this is the core 'system' group.
     */
    pure @property final Group!ReadWrite systemGroup() @safe @nogc nothrow
    {
        return _systemGroup;
    }

    /**
     * Return the EntityManager instance.
     */
    pure @property final ref EntityManager entity() @safe @nogc nothrow
    {
        return _entity;
    }

    /**
     * Return the tick count for the current frame
     */
    pure @property final Duration deltaTime() @safe @nogc nothrow
    {
        return _ticks;
    }

    /**
     * Return the frame time
     */
    pure @property final float frameTime() @safe @nogc nothrow
    {
        return _frameTime;
    }

    /**
     * Force the main loop to end
     */
    final void quit() @trusted @nogc nothrow
    {
        _running = false;
    }
}
