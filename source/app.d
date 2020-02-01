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
import std.stdio : writeln, writefln;

import serpent.tiled;

/**
 * Fairly typical entry-point code for a Serpent game.
 * Some CLI optons, set up the context, and ask it to run our
 * Game instance.
 */
int main(string[] args)
{
    bool vulkan = false;
    auto argp = getopt(args, std.getopt.config.bundling, "v|vulkan",
            "Use Vulkan instead of OpenGL", &vulkan);

    if (argp.helpWanted)
    {
        defaultGetoptPrinter("serpent demonstration\n", argp.options);
        return 0;
    }

    /* Context is essential to *all* Serpent usage. */
    auto context = new Context();
    context.display.title("#serpent demo").size(1366, 768);
    context.display.logicalSize(480, 270);

    /* We want OpenGL or Vulkan? */
    if (vulkan)
    {
        writeln("Requesting Vulkan display mode");
        context.display.driverType = DriverType.Vulkan;
    }
    else
    {
        writeln("Requesting OpenGL display mode");
        context.display.driverType = DriverType.OpenGL;
    }

    /* Set our root directory up */
    context.resource.root = context.resource.root ~ "/assets/built";

    /* Without a SpriteRenderer, nothing will be drawn. */
    context.renderGroup.add(new MapRenderer);
    context.renderGroup.add(new SpriteRenderer);

    /* Run the game now. */
    return context.run(new DemoGame());
}
