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

module serpent.graphics.pipeline;

import std.exception : enforce;

public import serpent.core.context;
public import serpent.graphics.display;
public import serpent.core.policy;
public import serpent.graphics.pipeline.info;

enum PipelineType
{
    Bgfx = 0, /**< Use the bgfx pipeline */
    Noop, /**< Use the no-op pipeline */



}

/**
 * Pipelines may have one or more flags enabled to control rendering
 * and informative behaviour.
 */
enum PipelineFlags
{
    None = 1 << 0,
    VerticalSync = 1 << 1, /**< Enable vsync */
    Debug = 1 << 2, /**< Enable debug */
    DepthClamp = 1 << 3, /**< Enable depth clamping */



}

/**
 * The Pipeline is the main entry into the graphical system. All calls and
 * implementation specifics will be handled by a concrete implementation
 * of this Pipeline.
 */
abstract class Pipeline
{
private:

    Context _context;
    Display _display;
    PipelineFlags _flags = PipelineFlags.VerticalSync | PipelineFlags.DepthClamp;
    /* Default to Vulkan. */
    DriverType _driverType = DriverType.Vulkan;
    Info _info;

private:

    pure final @property void context(Context c) @safe
    {
        enforce(c !is null, "Cannot have a null context");
        _context = c;
    }

    pure final @property void display(Display d) @safe
    {
        enforce(d !is null, "Cannot have a null display");
        _display = d;
    }

public:

    /**
     * Abstract constructor which should be called by concrete implementations
     */
    this(Context c, Display d) @safe
    {
        context = c;
        display = d;
    }

    /**
     * Return the flags
     */
    pure @property final PipelineFlags flags() @safe @nogc nothrow
    {
        return _flags;
    }

    /**
     * Update the pipeline flags. These will be reflected on the next render
     * cycle.
     */
    @property final void flags(PipelineFlags flags) @system
    {
        _flags = flags;
        reset();
    }

    /**
     * Return underlying info type
     */
    @property Info info() @safe @nogc nothrow
    {
        return Info(DriverType.None);
    }

    /**
     * Create a new pipeline for the given pipeline type.
     *
     * This should only be called by the Display instance.
     */
    static final Pipeline create(Context context, Display display, PipelineType type) @system
    {
        switch (type)
        {
        case PipelineType.Bgfx:
            import serpent.graphics.pipeline.bgfx;

            return new BgfxPipeline(context, display);
        case PipelineType.Noop:
        default:
            import serpent.graphics.pipeline.noop;

            return new NoopPipeline(context, display);
        }
    }

    /**
     * Return the underlying context
     */
    pure final @property Context context() @safe @nogc nothrow
    {
        return _context;
    }

    pure final @property Display display() @safe @nogc nothrow
    {
        return _display;
    }

    /**
     * Return the requested driverType.
     *
     * This may not match the info.driverType!
     */
    @property final DriverType driverType() @safe @nogc nothrow
    {
        return _driverType;
    }

    /**
     * Override the default Driver to use before the pipeline is up
     * and running. This allows forcibly switching to OpenGL, Vulkan, etc.
     */
    @property final Pipeline driverType(DriverType d) @safe
    {
        _driverType = d;
        return this;
    }

    /**
     * Return true if debug mode is enabled
     */
    pragma(inline, true) pure final @property bool debugMode() @safe @nogc nothrow
    {
        return (_flags & PipelineFlags.Debug) == PipelineFlags.Debug;
    }

    /**
     * Enable/disable debug mode
     */
    final @property void debugMode(bool b) @system
    {
        _flags = b ? _flags | PipelineFlags.Debug : _flags ^ PipelineFlags.Debug;
        reset();
    }

    /**
     * Return true if vsync is enabled
     */
    pragma(inline, true) pure final @property bool verticalSync() @safe @nogc nothrow
    {
        return (_flags & PipelineFlags.VerticalSync) == PipelineFlags.VerticalSync;
    }

    /**
     * Enable/disable vertical sync (vsync)
     */
    final @property void verticalSync(bool b) @system
    {
        _flags = b ? _flags | PipelineFlags.VerticalSync : _flags ^ PipelineFlags.VerticalSync;
        reset();
    }

    /**
     * Return true if depth clamp is enabled
     */
    pragma(inline, true) pure final @property bool depthClamp() @safe @nogc nothrow
    {
        return (_flags & PipelineFlags.DepthClamp) == PipelineFlags.DepthClamp;
    }

    /**
     * Enable/disable depth clamp
     */
    final @property void depthClamp(bool b) @system
    {
        _flags = b ? _flags | PipelineFlags.DepthClamp : _flags ^ PipelineFlags.DepthClamp;
        reset();
    }

    /**
     * The implementation should now bootstrap itself
     */
    abstract void bootstrap() @system;

    /**
     * The implementation should now shutdown and clean up
     * any resources.
     */
    abstract void shutdown() @system;

    /**
     * Perform all rendering for the current frame
     */
    abstract void render(View!ReadOnly queryView) @system;

    /**
     * Require the pipeline to reset attributes relating to the
     * windowing system (height/width/etc)
     */
    abstract void reset() @system;
}
