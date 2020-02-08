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

module serpent.graphics.pipeline.bgfx.pipeline;

public import serpent.core.context;
public import serpent.core.policy;
public import serpent.core.view;
public import serpent.graphics.display;
public import serpent.graphics.renderer;

import bindbc.bgfx;
import serpent.graphics.frame;
import std.exception : enforce;
import std.container.binaryheap;
import bindbc.sdl;

import serpent.graphics.batch;
import serpent.graphics.pipeline;
import serpent : SystemException;
import std.format;

/**
 * The BgfxPipeline is responsible for managing the underlying graphical context,
 * such as OpenGL (or through an abstraction like bgfx) and actually getting
 * entities on screen.
 *
 * It will precompute visible entities from the global entity cache and then
 * sort them prior to rendering.
 *
 * All rendering is done via Renderer implementations.
 */
final class BgfxPipeline : Pipeline
{
private:

    __gshared FramePacket packet;
    Renderer[] _renderers;
    bgfx_init_t bInit;

    /* Temporary: We need a draw operation queue we can sort! */
    QuadBatch qb;

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
        bgfx_set_view_mode(0, bgfx_view_mode_t.BGFX_VIEW_MODE_DEPTHASCENDING);

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

    /**
     * Integrate bgfx with our SDL_Window's native handles.
     *
     * We don't do any SDL rendering whether via SDL_Renderer or
     * OpenGL context. /All/ drawing is performed through the bgfx
     * library.
     */
    final void integrateWindowBgfx() @system
    {
        SDL_SysWMinfo wm;
        SDL_VERSION(&wm.version_);

        if (!SDL_GetWindowWMInfo(display.window, &wm))
        {
            throw new SystemException("Couldn't get Window Info: %s".format(SDL_GetError()));
        }

        bgfx_platform_data_t pd;
        version (Posix)
        {
            /* X11 displays. Note we need to fix OSX integration separate. */
            pd.ndt = wm.info.x11.display;
            pd.nwh = cast(void*) wm.info.x11.window;
        }
        else
        {
            throw new SystemException("Unsupported platform");
        }

        pd.context = null;
        pd.backBuffer = null;
        pd.backBufferDS = null;
        bgfx_set_platform_data(&pd);
    }

public:

    this(Context context, Display display)
    {
        super(context, display);

        /* Allow tuning this in future */
        packet = FramePacket(30_000);
    }

    final void addRenderer(Renderer r) @safe
    {
        enforce(!context.running, "Cannot add renderers to a running context");
        r.context = context;
        _renderers ~= r;
    }
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
    final override void render(View!ReadOnly queryView) @system
    {
        packet.startTick();
        prerender();
        auto encoder = bgfx_encoder_begin(true);
        qb.begin();

        /* Query visibles */
        foreach (r; _renderers)
        {
            r.encoder = encoder;
            r.queryVisibles(queryView, packet);
        }

        auto heap = heapify!("a.transformPosition.z > b.transformPosition.z")(
                packet.visibleEntities);

        /* Submission */
        foreach (s; heap)
        {
            s.renderer.encoder = encoder;
            s.renderer.submit(queryView, qb, s.id);
        }

        qb.flush(encoder);
        bgfx_encoder_end(encoder);

        postrender();
    }

    /**
     * Bootstrap the bgfx pipeline.
     */
    final override void bootstrap() @system
    {
        /* Init our constructor */
        bgfx_init_ctor(&bInit);

        /* Integrate with the window */
        integrateWindowBgfx();

        /* TODO: Init on separate render thread */
        bInit.type = context.info.convDriver(display.driverType);
        bgfx_init(&bInit);

        reset();

        qb = new QuadBatch(context);
    }

    final override void shutdown() @system nothrow
    {
        qb.destroy();
        qb = null;

        /* Shut down bgfx */
        bgfx_shutdown();
    }

    /**
     * Reset the bgfx backbuffer
     */
    final override void reset() @system nothrow
    {
        bgfx_reset(cast(ushort) display.width, cast(ushort) display.height,
                BGFX_RESET_VSYNC | BGFX_RESET_SRGB_BACKBUFFER | BGFX_RESET_DEPTH_CLAMP,
                bInit.resolution.format);
    }
}
