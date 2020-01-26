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

public import serpent.graphics.sprite;
public import serpent.core.entity;
public import serpent.core.processor;
public import serpent.core.view;

/**
 * MapRenderer walks through a tilemap and dispatches relevant drawing
 * of quads through Sprite APIs.
 */
final class MapRenderer : Processor!ReadOnly
{

public:

    /* Load shaders */
    final override void bootstrap(View!ReadOnly dataView) @system
    {

        context.component.registerComponent!MapComponent;
    }

    final override void run(View!ReadOnly dataView)
    {
        foreach (entity; dataView.withComponent!MapComponent)
        {
            drawMap(dataView, entity);
        }
    }

    /* Unload shaders while context is active  */
    final override void finish(View!ReadOnly dataView) @system
    {
    }

private:

    /**
     * Begin drawing of a map.
     */
    final void drawMap(View!ReadOnly dataView, EntityID entity)
    {
    }
}
