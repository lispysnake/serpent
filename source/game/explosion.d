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

module game.explosion;

import serpent;

import game.animation;
import game.physics;
import std.datetime;
import std.format;

SpriteAnimation createExplosionAnimation()
{
    SpriteAnimation ret = SpriteAnimation(dur!"msecs"(80));
    foreach (i; 0 .. 10)
    {
        ret.addTexture(new Texture(
                "assets/SciFi/Sprites/Explosion/sprites/explosion-animation%d.png".format(i + 1)));
    }
    return ret;
}

EntityID createExplosion(View!ReadWrite initView, SpriteAnimation* anim)
{
    auto explosion = initView.createEntity();
    auto transform = TransformComponent();
    auto sprite = SpriteComponent();
    sprite.texture = anim.textures[0];
    transform.position.x = 40.0f;
    transform.position.z = 0.9f;
    transform.position.y = 120.0f;

    auto explosionAnim = SpriteAnimationComponent();
    explosionAnim.animation = anim;
    initView.addComponentDeferred(explosion, transform);
    initView.addComponentDeferred(explosion, sprite);
    initView.addComponentDeferred(explosion, explosionAnim);

    return explosion;
}
