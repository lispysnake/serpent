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
}
