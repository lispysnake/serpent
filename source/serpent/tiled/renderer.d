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

module serpent.tiled.renderer;

import serpent.tiled.component;

public import serpent.core.entity;
public import serpent.core.processor;
public import serpent.core.view;

import serpent.tiled : FlipMode;
import serpent.graphics.batch;

import serpent.graphics.renderer;
import serpent.core.transform;

/**
 * MapRenderer walks through a tilemap and dispatches relevant drawing
 * of quads through Sprite APIs.
 */
final class MapRenderer : Renderer
{

public:

    final override void queryVisibles(View!ReadOnly queryView, ref FramePacket packet)
    {
        foreach (entity; queryView.withComponent!MapComponent)
        {
            auto transform = queryView.data!TransformComponent(entity);
            packet.pushVisibleEntity(entity, this, transform.position);
        }
    }

    final override void submit(View!ReadOnly queryView, ref QuadBatch batch, EntityID id)
    {

    }

    /**
     * Begin drawing of a map.
     */
    final void drawMap(View!ReadOnly dataView, ref QuadBatch qb, EntityID entity)
    {
        auto mapComponent = dataView.data!MapComponent(entity);
        float drawX = 0.0f;
        float drawY = 0.0f;
        auto transformScale = vec3f(1.0f, 1.0f, 1.0f);

        qb.begin();
        foreach (layer; mapComponent.map.layers)
        {
            foreach (y; 0 .. layer.height)
            {
                foreach (x; 0 .. layer.width)
                {
                    auto gid = layer.data[x + y * layer.width];
                    auto tile = gid & ~FlipMode.Mask;
                    auto tileset = mapComponent.map.findTileSet(tile);
                    if (tileset is null)
                    {
                        drawX += mapComponent.map.tileWidth;
                        continue;
                    }
                    auto t2 = tileset.getTile(tile);

                    auto transformPosition = vec3f(drawX, drawY, 0.0f);

                    float tileWidth = mapComponent.map.tileWidth;
                    float tileHeight = mapComponent.map.tileHeight;

                    /* Anchor the image correctly. */
                    if (tileset.collection)
                    {
                        tileWidth = t2.texture.width;
                        tileHeight = t2.texture.height;

                        /* Account for non-regular tiles */
                        if (tileWidth != mapComponent.map.tileWidth
                                || tileHeight != mapComponent.map.tileHeight)
                        {
                            transformPosition.y += mapComponent.map.tileHeight;
                            transformPosition.y -= tileHeight;
                        }
                    }

                    qb.drawTexturedQuad(encoder, t2.texture, transformPosition,
                            transformScale, tileWidth, tileHeight, t2.region);
                    drawX += mapComponent.map.tileWidth;
                }
                drawY += mapComponent.map.tileHeight;
                drawX = 0;
            }
            drawX = 0;
            drawY = 0;

            /* Flush between layers to preserve depth. */
            qb.flush(encoder);
        }
        qb.flush(encoder);
    }
}
