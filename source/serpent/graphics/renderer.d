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

module serpent.graphics.renderer;

public import serpent.core.policy;
public import serpent.core.view;

public import serpent.graphics.frame;

/**
 * The Renderer is implemented by specific components that wish to register
 * their visibles with the current frame for rendering. As each component
 * may have specific 'isVisible' conditions, we leave it up to the renderer
 * to decide what is actually visible.
 */
abstract class Renderer
{

    /**
     * The renderer will be called with the given queryView, if it finds
     * entities it knows it can draw, then submit them to the packet.
     */
    abstract void queryVisibles(View!ReadOnly queryView, ref FramePacket packet);
}
