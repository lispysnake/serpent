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

import serpent.tiled : TileFlipMode;
import serpent.graphics.batch;

import serpent.graphics.renderer;
import serpent.core.transform;

/**
 * The MapOffsets lets us calculate exactly which part of the tilemap
 * we need to render. Even though we can scissor most stuff out there
 * is very little point in wasting CPU time submitting invisible
 * quads.
 */
final struct MapOffsets
{
    float startX = 0;
    float startY = 0;
    int visibleColumns = 0;
    int visibleRows = 0;
    int firstColumn = 0;
    int firstRow = 0;
    int maxRow = 0;
    int maxColumn = 0;
};

/**
 * MapRenderer walks through a tilemap and dispatches relevant drawing
 * of quads through Sprite APIs.
 *
 * TODO: Split renderer to work on MapLayer entities. This will massively
 * improve approach to layering sprites.
 */
final class MapRenderer : Renderer
{

public:

    final override void queryVisibles(View!ReadOnly queryView, ref FramePacket packet)
    {
        foreach (entity, transform, map; queryView.withComponents!(TransformComponent,
                MapComponent))
        {
            packet.pushVisibleEntity(entity.id, this, transform.position);
        }
    }

    final override void submit(View!ReadOnly queryView, ref QuadBatch batch, EntityID id)
    {
        drawMap(queryView, batch, id);
    }

    /**
     * Return the renderable offsets + constraints for a tiled map to prevent
     * drawing more than we actually need to.
     */
    final MapOffsets calcOffsets(in TransformComponent* transform, in MapComponent* map)
    {
        import std.math : ceil, floor;

        /* Base offsets */
        MapOffsets offsets = {
            startX: transform.position.x, startY: transform.position.y,
            firstColumn: 0, firstRow: 0, visibleRows: cast(int) ceil(
                        cast(float) context.display.logicalHeight / map.map.tileHeight), visibleColumns: cast(int) ceil(cast(float) context.display.logicalWidth / map.map.tileWidth),
            maxColumn: map.map.width, maxRow: map.map.height,
        };

        /* Need camera for offsets to work properly. */
        if (context.display.scene.camera is null)
        {
            return offsets;
        }

        /* Compute first row + column */
        vec3f cameraPos = context.display.scene.camera.position;
        offsets.firstRow = cast(int) floor(cameraPos.y / map.map.tileHeight);
        offsets.firstColumn = cast(int) floor(cameraPos.x / map.map.tileWidth);

        /* Offset start X + Y (skipped) */
        offsets.startX += offsets.firstColumn * map.map.tileWidth;
        offsets.startY += offsets.firstRow * map.map.tileHeight;

        /* Compute maximum column */
        offsets.maxColumn = offsets.firstColumn + offsets.visibleColumns + 1;
        if (offsets.maxColumn >= map.map.width)
        {
            offsets.maxColumn = map.map.width;
        }

        /* Compute maximum row */
        offsets.maxRow = offsets.firstRow + offsets.visibleRows + 1;
        if (offsets.maxRow >= map.map.height)
        {
            offsets.maxRow = map.map.height;
        }

        return offsets;
    }

    /**
     * Begin drawing of a map.
     */
    final void drawMap(View!ReadOnly dataView, ref QuadBatch qb, EntityID entity)
    {
        auto mapComponent = dataView.data!MapComponent(entity);
        auto transform = dataView.data!TransformComponent(entity);

        auto offsets = calcOffsets(transform, mapComponent);

        float drawX = offsets.startX;
        float drawY = offsets.startY;
        auto transformScale = vec3f(1.0f, 1.0f, 1.0f);

        float drawZ = transform.position.z;

        foreach (layer; mapComponent.map.layers)
        {
            foreach (y; offsets.firstRow .. offsets.maxRow)
            {
                foreach (x; offsets.firstColumn .. offsets.maxColumn)
                {
                    auto gid = layer.data[x + y * layer.width];
                    auto tile = gid & ~TileFlipMode.Mask;
                    auto tileset = mapComponent.map.findTileSet(tile);
                    if (tileset is null)
                    {
                        drawX += mapComponent.map.tileWidth;
                        continue;
                    }
                    auto t2 = tileset.getTile(tile);

                    auto transformPosition = vec3f(drawX, drawY, drawZ);

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

                    /* Currently only support horizontal + vertical flip */
                    UVCoordinates uv = t2.uv;
                    if ((gid & TileFlipMode.Horizontal) == TileFlipMode.Horizontal)
                    {
                        uv.flipHorizontal();
                    }
                    if ((gid & TileFlipMode.Vertical) == TileFlipMode.Vertical)
                    {
                        uv.flipVertical();
                    }

                    qb.drawTexturedQuad(encoder, t2.texture, transformPosition,
                            transformScale, tileWidth, tileHeight, uv);
                    drawX += mapComponent.map.tileWidth;
                }
                drawY += mapComponent.map.tileHeight;
                drawX = offsets.startX;
            }
            drawX = offsets.startX;
            drawY = offsets.startY;
            drawZ += 0.1f;
        }
    }
}
