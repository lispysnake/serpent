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

/**
 * MapRenderer walks through a tilemap and dispatches relevant drawing
 * of quads through Sprite APIs.
 */
final class MapRenderer : Processor!ReadOnly
{

private:
    QuadBatch qb = null;

public:

    /* Load shaders */
    final override void bootstrap(View!ReadOnly dataView) @system
    {

        context.component.registerComponent!MapComponent;
        qb = new QuadBatch(context);
    }

    final override void run(View!ReadOnly dataView)
    {
        foreach (entity; dataView.withComponent!MapComponent)
        {
            drawMap(dataView, entity);
        }
    }

    final override void finish(View!ReadOnly dataView) @system
    {
        qb.destroy();
        qb = null;
    }

private:

    /**
     * Begin drawing of a map.
     */
    final void drawMap(View!ReadOnly dataView, EntityID entity)
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
                    if (tile == 0)
                    {
                        drawX += mapComponent.map.tileWidth;
                        continue;
                    }
                    auto t2 = mapComponent.tileset.getTile(tile - 1);

                    auto transformPosition = vec3f(drawX, drawY, 0.0f);

                    qb.drawTexturedQuad(encoder, mapComponent.texture, transformPosition, transformScale,
                            mapComponent.map.tileWidth, mapComponent.map.tileHeight, t2.region);
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
