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

module game.animation;

import serpent;
import std.datetime;

/**
 * Absurdly simple Animation helper.
 */
final struct Animation
{
    Texture[] textures;
    ulong textureIndex = 0;
    Duration passed;
    EntityID entity;
    Duration interval;

    this(EntityID entity, Duration interval)
    {
        this.entity = entity;
        this.interval = interval;
    }

    /**
     * Add a texture to our known set
     */
    void addTexture(Texture t)
    {
        textures ~= t;
    }

    /**
     * Update with the given duration
     */
    void update(View!ReadWrite view, Duration dt)
    {
        passed += dt;
        if (passed <= this.interval)
        {
            return;
        }
        passed = dt;
        textureIndex++;
        if (textureIndex >= textures.length)
        {
            textureIndex = 0;
        }
        view.data!SpriteComponent(entity).texture = textures[textureIndex];
    }
}
