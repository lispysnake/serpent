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

module game.physics;

import serpent;

const auto meterSize = 70;

/**
 * We apply a PhysicsComponent when there is some position manipulation
 * to be had.
 */
@serpentComponent final struct PhysicsComponent
{
    float velocityX = 0.0f;
    float velocityY = 0.0f;
}

/**
 * Demo physics - if have velocity, go.
 */
final class BasicPhysics : Processor!ReadWrite
{
    final override void run(View!ReadWrite view)
    {
        import std.parallelism : parallel;

        foreach (chunk; parallel(view.withComponentsChunked!(TransformComponent, PhysicsComponent)))
        {
            /* Find all physics entities */
            foreach (ent, transform, physics; chunk)
            {
                auto frameTime = context.frameTime();

                transform.position.x += physics.velocityX * frameTime;
                transform.position.y += physics.velocityY * frameTime;
            }
        }
    }
}
