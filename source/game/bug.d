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

module game.bug;

import serpent;

import game.animation;
import game.physics;
import std.datetime;
import std.format;

/**
 * Create the bug animation
 */
Animation createBugAnimation()
{
    Animation ret = Animation(0, dur!"msecs"(50));
    foreach (i; 0..8)
    {
        ret.addTexture(new Texture(
                "assets/SciFi/Sprites/alien-flying-enemy/sprites/alien-enemy-flying%d.png".format(i+1)));
    }
    return ret;
}

EntityID createBug(View!ReadWrite initView, ref Animation anim)
{
        auto bug = initView.createEntity();
        anim.entity = bug; /* HACK */
        auto transform = TransformComponent();
        auto physics = PhysicsComponent();
        physics.velocityX = (meterSize * 1.5) / 1000.0f;
        auto sprite = SpriteComponent();
        sprite.texture = anim.textures[0];
        sprite.flip = FlipMode.Horizontal;

        initView.addComponent(bug, transform);
        initView.addComponent(bug, physics);
        initView.addComponent(bug, sprite);

        return bug;
}
