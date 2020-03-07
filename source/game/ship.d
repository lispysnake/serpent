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

module game.ship;

import serpent;

import game.animation;
import game.physics;
import std.datetime;
import std.format;

/**
 * Create the bug animation
 */
SpriteAnimation createShipAnimation()
{
    SpriteAnimation ret = SpriteAnimation(dur!"msecs"(50));
    auto rootTexture = new Texture(
            "assets/SciFi/Sprites/spaceship-unit/PNG/ship-unit-with-thrusts.png");
    auto frameSize = rootTexture.width / 8.0f;
    foreach (i; 0 .. 8)
    {
        auto frame = rootTexture.subtexture(rectanglef(i * frameSize, 0.0f,
                frameSize, rootTexture.height));
        ret.addTexture(frame);
    }
    return ret;
}

EntityID createShip(View!ReadWrite initView, SpriteAnimation* anim)
{
    auto ship = initView.createEntity();
    auto transform = TransformComponent();
    auto physics = PhysicsComponent();
    auto sprite = SpriteComponent();
    sprite.texture = anim.textures[0];
    sprite.flip = FlipMode.Horizontal;

    /* Update movement */
    transform.position.x = 500.0f;
    transform.position.y = 60.0f;
    physics.velocityX = (meterSize * -1.2) / 1000.0f;
    physics.velocityY = (meterSize * -0.1) / 1000.0f;

    auto spriteAnim = SpriteAnimationComponent();
    spriteAnim.animation = anim;

    initView.addComponentDeferred(ship, transform);
    initView.addComponentDeferred(ship, physics);
    initView.addComponentDeferred(ship, sprite);
    initView.addComponentDeferred(ship, spriteAnim);

    return ship;
}
