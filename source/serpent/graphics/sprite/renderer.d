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

import serpent.graphics : FlipMode;
import serpent.graphics.sprite : SpriteComponent;
import serpent.core.transform;

/**
 * The SpriteRenderer collects all entities with the SpriteComponent,
 * and submits them for batch rendering, if they're within the visible
 * viewport.
 */
final class SpriteRenderer : Renderer
{

public:

    /**
     * Find all sprites. We should add camera culling here but meh.
     */
    final override void queryVisibles(View!ReadOnly queryView, ref FramePacket packet) @trusted
    {
        /* Computed visible viewport */
        auto position = context.display.scene.camera.position;
        auto viewport = rectanglef(position.x, position.y,
                context.display.logicalWidth(), context.display.logicalHeight());

        foreach (entity; queryView.withComponent!SpriteComponent)
        {
            auto transform = queryView.data!TransformComponent(entity);
            auto sprite = queryView.data!SpriteComponent(entity);

            /* Bounding box for the entity */
            auto bounds = rectanglef(transform.position.x, transform.position.y,
                    sprite.texture.width, sprite.texture.height);
            auto intersection = viewport.intersection(bounds);

            /* Only push visibles */
            if (intersection.isSorted() && !intersection.empty())
            {
                packet.pushVisibleEntity(entity, this, transform.position);
            }
        }
    }

    /**
     * Draw the visible on screen now.
     */
    final override void submit(View!ReadOnly queryView, ref QuadBatch batch, EntityID entity) @safe
    {
        auto transform = queryView.data!TransformComponent(entity);
        auto sprite = queryView.data!SpriteComponent(entity);
        UVCoordinates uv = sprite.texture.uv;
        if ((sprite.flip & FlipMode.Horizontal) == FlipMode.Horizontal)
        {
            uv.flipHorizontal();
        }
        if ((sprite.flip & FlipMode.Vertical) == FlipMode.Vertical)
        {
            uv.flipVertical();
        }

        batch.drawTexturedQuad(encoder, sprite.texture, transform.position,
                transform.scale, sprite.texture.width, sprite.texture.height, uv);
    }
}
