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

module serpent.graphics.renderer;

public import serpent.context;
public import serpent.graphics.renderer.sprite;
public import serpent.graphics.pipeline;

/**
 * A renderer knows how to draw Things. It must be added to the
 * stages of a Pipeline for drawing to actually happen.
 */
abstract class Renderer
{

private:
    Pipeline _pipeline;

public:

    /**
     * Return the associated pipeline
     */
    @property final Pipeline pipeline() @safe @nogc nothrow
    {
        return _pipeline;
    }

    /**
     * Set the associated pipeline
     */
    pure @property final void pipeline(Pipeline p) @safe @nogc nothrow
    {
        this._pipeline = p;
    }

    /**
     * Renderers are given a single opportunity in which to load
     * all of their required resources (i.e. shaders) before startup.
     * This is the time to do so.
     */
    abstract void init();

    /**
     * This renderer must do its job now.
     */
    abstract void render();

    /**
     * Get the display associated with this Game
     */
    pure @property final Context context() @safe @nogc nothrow
    {
        return _pipeline.display.context;
    }
}
