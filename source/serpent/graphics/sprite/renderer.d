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

module serpent.graphics.sprite.renderer;

public import serpent.graphics.renderer;

import serpent.graphics.sprite : SpriteComponent;
import serpent.core.transform;

/**
 * The SpriteRenderer will collect and draw all visible sprites within
 * the current scene.
 *
 * TODO: Optimise this into a batching sprite renderer. For now we're
 * going to be ugly and draw a quad at a time. This results in multiple
 * draw calls per frame, and is hella inefficient.
 */
final class SpriteRenderer : Renderer
{

public:

    /**
     * Find all sprites. We should add camera culling here but meh.
     */
    final override void queryVisibles(View!ReadOnly queryView, ref FramePacket packet) @safe
    {
        foreach (entity; queryView.withComponent!SpriteComponent)
        {
            auto transform = queryView.data!TransformComponent(entity);
            packet.pushVisibleEntity(entity, this, transform.position);
        }
    }

    /**
     * Draw the visible on screen now.
     */
    final override void submit(View!ReadOnly queryView, ref QuadBatch batch, EntityID entity) @safe
    {
        auto transform = queryView.data!TransformComponent(entity);
        auto sprite = queryView.data!SpriteComponent(entity);
        batch.drawTexturedQuad(encoder, sprite.texture, transform.position, transform.scale);
    }
}
