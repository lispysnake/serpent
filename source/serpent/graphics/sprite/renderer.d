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

import serpent.core.transform : TransformComponent;

public import serpent.graphics.batch;
public import serpent.graphics.sprite : SpriteComponent;
public import serpent.core.entity;
public import serpent.core.processor;
public import serpent.core.view;

/**
 * The SpriteRenderer will collect and draw all visible sprites within
 * the current scene.
 *
 * TODO: Optimise this into a batching sprite renderer. For now we're
 * going to be ugly and draw a quad at a time. This results in multiple
 * draw calls per frame, and is hella inefficient.
 */
final class SpriteRenderer : Processor!ReadOnly
{

private:
    QuadBatch qb;

public:

    /* Load shaders */
    final override void bootstrap(View!ReadOnly dataView) @system
    {
        context.component.registerComponent!SpriteComponent;
        qb = new QuadBatch(context);

    }

    final override void run(View!ReadOnly dataView)
    {
        qb.begin();
        foreach (entity; dataView.withComponent!SpriteComponent)
        {
            auto transform = dataView.data!TransformComponent(entity);
            qb.drawTexturedQuad(encoder, dataView.data!SpriteComponent(entity)
                    .texture, transform.position, transform.scale);
        }
        qb.flush(encoder);
    }

    /* Unload shaders while context is active  */
    final override void finish(View!ReadOnly dataView) @system
    {
        qb.destroy();
        qb = null;
    }
}
