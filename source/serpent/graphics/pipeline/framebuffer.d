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

module serpent.graphics.pipeline.framebuffer;

public import serpent.graphics.pipeline : Pipeline;

import std.exception : enforce;

/**
 * The FrameBuffer type is used to wrap up the internal differences in
 * framebuffer objects. It provides a rendering target which can be
 * applied to make all rendering redirect to the framebuffer.
 *
 * Additionally it may be applied to the screen using a fullscreen
 * quad.
 */
abstract class FrameBuffer
{

private:

    Pipeline _pipeline = null;

    /**
     * Set the pipeline associated with this framebuffer
     */
    pure final @property void pipeline(Pipeline pipeline) @safe
    {
        enforce(pipeline !is null, "Pipeline cannot be null");
    }

public:

    /**
     * Provide a parent constructor to set basic properties
     */
    this(Pipeline pipeline) @safe
    {
        this.pipeline = pipeline;
    }

    /**
     * Return the underlying pipeline
     */
    pure final @property Pipeline pipeline() @safe @nogc nothrow
    {
        return _pipeline;
    }

    /**
     * Require the framebuffer object be bound.
     * All rendering will now happen within the framebuffer
     */
    abstract void bind() @system @nogc nothrow;

    /**
     * Unbind the framebuffer, no further rendering will happen here
     * All rendering calls will now go to the backbuffer
     */
    abstract void unbind() @system @nogc nothrow;
}
