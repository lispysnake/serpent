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

import game : DemoGame;
import std.getopt;
import serpent.core;
import serpent.graphics.sprite;
import serpent.graphics.pipeline.info;
import std.stdio : writeln, writefln;

import serpent.tiled;
import std.algorithm.searching : endsWith;

/**
 * Fairly typical entry-point code for a Serpent game.
 * Some CLI optons, set up the context, and ask it to run our
 * Game instance.
 */
int main(string[] args)
{
    bool vulkan = false;
    bool fullscreen = false;
    bool debugMode = false;
    bool disableVsync = false;
    auto argp = getopt(args, std.getopt.config.bundling, "v|vulkan",
            "Use Vulkan instead of OpenGL", &vulkan, "f|fullscreen",
            "Start in fullscreen mode", &fullscreen, "d|debug", "Enable debug mode",
            &debugMode, "n|no-vsync", "Disable VSync", &disableVsync);

    if (argp.helpWanted)
    {
        defaultGetoptPrinter("serpent demonstration\n", argp.options);
        return 0;
    }

    /* Context is essential to *all* Serpent usage. */
    auto context = new Context();
    context.display.title("#serpent demo").size(1366, 768);
    context.display.logicalSize(480, 270);
    context.display.backgroundColor = 0x0f;

    if (vulkan)
    {
        context.display.title = context.display.title ~ " [Vulkan]";
    }
    else
    {
        context.display.title = context.display.title ~ " [OpenGL]";
    }

    /* We want OpenGL or Vulkan? */
    if (vulkan)
    {
        writeln("Requesting Vulkan display mode");
        context.display.pipeline.driverType = DriverType.Vulkan;
    }
    else
    {
        writeln("Requesting OpenGL display mode");
        context.display.pipeline.driverType = DriverType.OpenGL;
    }

    if (fullscreen)
    {
        writeln("Starting in fullscreen mode");
        context.display.fullscreen = true;
    }

    if (debugMode)
    {
        writeln("Starting in debug mode");
        context.display.pipeline.debugMode = true;
    }

    if (disableVsync)
    {
        writeln("Disabling vsync");
        context.display.pipeline.verticalSync = false;
    }

    /* HAX: Add bgfx specific renderer. We need to abstract renderer
     * and textures!
     */
    import serpent.graphics.pipeline.bgfx.pipeline;

    auto pipeline = cast(BgfxPipeline) context.display.pipeline;
    pipeline.addRenderer(new SpriteRenderer);

    /* Run the game now. */
    return context.run(new DemoGame());
}
