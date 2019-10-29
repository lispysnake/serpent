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

module serpent.pipeline.sprite;

import serpent.entity;
import serpent.pipeline;

/**
 * The SpriteRenderer will collect and draw all visible sprites within
 * the current scene.
 *
 * A Sprite is currently considered anything that is an Entity2D.
 * This will change in future to tag various base types.
 */
final class SpriteRenderer : Renderer
{
    final override void render() @safe
    {
        import std.stdio;

        auto ents = pipeline.display.scene.visibleEntities2D();
        foreach (ent; ents)
        {
            writefln("Draw %d entities now", ent.size());
        }
        /* TODO: Something useful */
        return;
    }
}
