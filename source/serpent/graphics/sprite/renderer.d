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

import bindbc.bgfx;
import gfm.math;
import std.stdint;

public import serpent.graphics.sprite;
public import serpent.core.entity;
public import serpent.core.processor;
public import serpent.core.view;

/**
 * The PosUVVertex type simply contains coordinates for the position
 * of a Thing (3f), along with the texture coordinates (2f)
 *
 * It is currently only used for Sprite quads.
 */
final struct PosUVVertex
{

    vec3f pos;
    vec2f tex;

    static bgfx_vertex_layout_t layout;

    this(vec3f pos, vec2f tex)
    {
        this.pos = pos;
        this.tex = tex;
    }

    static this()
    {
        bgfx_vertex_layout_begin(&layout, bgfx_renderer_type_t.BGFX_RENDERER_TYPE_NOOP);

        /* Position */
        bgfx_vertex_layout_add(&layout, bgfx_attrib_t.BGFX_ATTRIB_POSITION, 3,
                bgfx_attrib_type_t.BGFX_ATTRIB_TYPE_FLOAT, false, false);
        bgfx_vertex_layout_add(&layout, bgfx_attrib_t.BGFX_ATTRIB_TEXCOORD0,
                2, bgfx_attrib_type_t.BGFX_ATTRIB_TYPE_FLOAT, false, false);

        bgfx_vertex_layout_end(&layout);
    }
}

/**
 * The SpriteRenderer will collect and draw all visible sprites within
 * the current scene.
 *
 * A Sprite is currently considered anything that is an Enity.
 * This will change in future to tag various base types.
 *
 * TODO: Optimise this into a batching sprite renderer. For now we're
 * going to be ugly and draw a quad at a time. This results in multiple
 * draw calls per frame, and is hella inefficient.
 */
final class SpriteRenderer : Processor!ReadOnly
{

    final override void run(View!ReadOnly dataView)
    {
        foreach (entity; dataView.withComponent!SpriteComponent)
        {
            drawOne(dataView, entity);
        }
    }

private:

    /**
     * Extremely inefficient, we submit a VB/IB pair for every
     * single sprite. However, we can optimise this at a later
     * time into a batching renderer.
     *
     * We have other priorities to sort through first.
     */
    final void drawOne(View!ReadOnly dataView, EntityID entity)
    {
    }
}
