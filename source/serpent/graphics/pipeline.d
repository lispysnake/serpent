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

public import serpent.core.context;
public import serpent.graphics.display;

import bindbc.bgfx;

/**
 * The Pipeline is responsible for managing the underlying graphical context,
 * such as OpenGL (or through an abstraction like bgfx) and actually getting
 * entities on screen.
 *
 * It will precompute visible entities from the global entity cache and then
 * sort them prior to rendering.
 *
 * All rendering is done via Renderer implementations.
 */
final class Pipeline
{
    Context _context = null;
    Display _display = null;

package:

    this(Context context, Display display)
    {
        this._display = display;
        this._context = context;
    }

private:

    /**
     * Perform any pre-rendering we need to do, such as clearing the
     * display.
     *
     * TODO: Render everything to one framebuffer by default, and scale that framenbuffer
     * so that the QuadBatch doesn't know about scale factors. It will also help us to
     * solve the glitchy black bars when using non-aspect ratios.
     */
    final void prerender() @system @nogc nothrow
    {
        /* Set clearing of view0 background. */
        clear(0);

        /* Set up auto scaling: http://www.david-amador.com/2013/04/opengl-2d-independent-resolution-rendering/ */
        auto aspectRatio = cast(float) display.logicalWidth / cast(float) display.logicalHeight;
        int w = display.width;
        int h = cast(int)(w / aspectRatio + 0.5f);

        /* Letter box it */
        if (h > display.height)
        {
            h = display.height;
            w = cast(int)(h * aspectRatio + 0.5f);
        }

        int vpX = (display.width / 2) - (w / 2);
        int vpY = (display.height / 2) - (h / 2);

        bgfx_set_view_rect(0, cast(ushort) vpX, cast(ushort) vpY, cast(ushort) w, cast(ushort) h);

        /* Make sure view0 is drawn. */
        bgfx_touch(0);

        auto camera = display.scene.camera;
        if (camera !is null)
        {
            camera.apply();
        }
    }

    /**
     * Perform any required rendering
     */
    final void postrender() @system @nogc nothrow
    {
        /* Skip frame now */
        bgfx_frame(false);
    }

public:

    /**
     * Clear the view
     */
    final void clear(ushort viewIndex = 0) @system @nogc nothrow
    {
        bgfx_set_view_clear(viewIndex, BGFX_CLEAR_COLOR | BGFX_CLEAR_DEPTH,
                display.backgroundColor, 1.0f, 0);
    }

    /**
     * Perform one full render tick
     */
    final void render() @system @nogc nothrow
    {
        prerender();
        postrender();
    }

    /**
     * Return the underlying context
     */
    final @property Context context() @safe @nogc nothrow
    {
        return _context;
    }

    /**
     * Return the underlying display
     */
    final @property Display display() @safe @nogc nothrow
    {
        return _display;
    }
}
