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

module serpent.core.transform;

public import gfm.math;
public import serpent.ecs.component : serpentComponent;

/**
 * A TransformComponent is used to provide position, scale and rotation
 * information for entities within a 3D space.
 *
 * Note that even 2D entities must conform to this too, as they are expressed
 * as 2D planes viewed orthographically. When using 2D APIs such as Sprites,
 * X/Y will map to game-window coordinates, with Z becoming the depth.
 */
@serpentComponent final struct TransformComponent
{
    vec3f position = vec3f(0.0f, 0.0f, 0.0f);
    vec3f scale = vec3f(1.0f, 1.0f, 1.0f);
}
