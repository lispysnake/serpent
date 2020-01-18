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

public import serpent.graphics.display;
public import serpent.graphics.renderer;

import bindbc.bgfx;

/**
 * The pipeline abstraction allows us to split our rendering logic from
 * our display/input management logic. Rendering is implemented internally
 * through Renderer instances.
 *
 * Internally implementations just use bgfx and render through them.
 */
final class Pipeline
{

private:
    Display _display;
    Renderer[] _renderers;
    Context _context;
    bool didInit = false;

package:

    this(Display display)
    {
        /* Just try to optimise startup. */
        _renderers.reserve(3);
        this._display = display;
    }

public:
    /**
     * Clear any drawing
     */
    final void clear() @nogc @system nothrow
    {
        /* Set up sizing for view0  */
        bgfx_set_view_rect(0, 0, 0, cast(ushort) display.width, cast(ushort) display.height);

        /* Make sure view0 is drawn. */
        bgfx_touch(0);
    }

    /**
     * Perform any real rendering logic through our Renderer instances
     */
    final void render() @system
    {
        auto camera = display.scene.camera;
        if (camera !is null)
        {
            camera.apply();
        }

        foreach (ref r; _renderers)
        {
            r.render();
        }
    }

    /**
     * Flush any drawing.
     */
    final void flush() @nogc @system nothrow
    {
        /* Skip frame now */
        bgfx_frame(false);
    }

    /**
     * Add a renderer to the pipeline
     * At this point we'll attempt to init the renderer.
     */
    final void addRenderer(Renderer r) @system
    {
        r.pipeline = this;
        this._renderers ~= r;
    }

    /**
     * Begin init of all renderers
     */
    final void init() @system
    {
        if (didInit)
        {
            return;
        }
        didInit = true;
        foreach (ren; _renderers)
        {
            ren.init();
        }
    }

    /**
     * Return the associated display
     */
    pure @property final Display display() @safe @nogc nothrow
    {
        return _display;
    }

}
