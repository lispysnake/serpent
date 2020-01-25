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

public import serpent.graphics.display;
public import serpent.app;
public import serpent.info;
public import serpent.input;
public import serpent.resource;

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

    ResourceManager _resource;
    InputManager _input;
    EntityManager _entity;
    ComponentManager _component;
    App _app;
    Display _display;
    Info _info;
    __gshared bool _running = false;

    /* Scheduling cruft */
    GroupRunner[] groups;
    TaskPool tp;
    Group!ReadWrite _systemGroup;
    Group!ReadOnly _prerenderGroup;
    Group!ReadOnly _postrenderGroup;
    Group!ReadOnly _renderGroup;

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
        _component = new ComponentManager();
        _entity = new EntityManager(_component);

        _systemGroup = new Group!ReadWrite("system").add(new InputProcessor)
            .add(new AppUpdateProcessor());
        addGroup(_systemGroup);

        /* Begin frame kick, etc. */
        _prerenderGroup = new Group!ReadOnly("pre-render");
        _prerenderGroup.add(new PreRenderProcessor);
        addGroup(_prerenderGroup);

        /* Do actual rendering. Eventually, make this parallel. */
        _renderGroup = new Group!ReadOnly("render");
        addGroup(_renderGroup);

        /* Finish the rendering. */
        _postrenderGroup = new Group!ReadOnly("post-render");
        _postrenderGroup.add(new PostRenderProcessor);
        addGroup(_postrenderGroup);

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
        _info.update();

        enforce(info.driverType != DriverType.Unsupported,
                "Unsupported underlying driver. Please report this.");

        /* Bootstrap processor groups before app loads anything */
        bootstrapGroups();

        auto view = View!ReadWrite(this.entity, this.component);
        if (!app.bootstrap(view))
        {
            return 1;
        }

        scope (exit)
        {
            tp.finish(true);
            _app.shutdown();
        }

        _running = true;
        display.visible = true;

        /**
         * Main run loop
         */
        while (_running)
        {
            /* Force stepping through the Entity system */
            _entity.step();
            scheduledExecution();
        }

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
     * Returns the Group used within the rendering stage of frame-execution.
     * Internally this is the core 'render' group.
     */
    pure @property final Group!ReadOnly renderGroup() @safe @nogc nothrow
    {
        return _renderGroup;
    }

    /**
     * Return the EntityManager instance.
     */
    pure @property final EntityManager entity() @safe @nogc nothrow
    {
        return _entity;
    }

    /**
     * Return the ComponentManager instance
     */
    pure @property final ComponentManager component() @safe @nogc nothrow
    {
        return _component;
    }

    /**
     * Force the main loop to end
     */
    final void quit() @trusted @nogc nothrow
    {
        _running = false;
    }
}
