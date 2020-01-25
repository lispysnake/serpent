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

import serpent.graphics.shader;
import serpent.graphics.blend;

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
 * TODO: Optimise this into a batching sprite renderer. For now we're
 * going to be ugly and draw a quad at a time. This results in multiple
 * draw calls per frame, and is hella inefficient.
 */
final class SpriteRenderer : Processor!ReadOnly
{

private:
    Program shader = null;

public:

    /* Load shaders */
    final override void bootstrap(View!ReadOnly dataView) @system
    {

        context.component.registerComponent!SpriteComponent;

        auto vp = context.resource.substitutePath(
                context.resource.root ~ "/shaders/${shaderModel}/sprite_2d_vertex.bin");
        auto fp = context.resource.substitutePath(
                context.resource.root ~ "/shaders/${shaderModel}/sprite_2d_fragment.bin");
        auto vertex = new Shader(vp);
        auto fragment = new Shader(fp);
        shader = new Program(vertex, fragment);
    }

    final override void run(View!ReadOnly dataView)
    {
        foreach (entity; dataView.withComponent!SpriteComponent)
        {
            drawOne(dataView, entity);
        }
    }

    /* Unload shaders while context is active  */
    final override void finish(View!ReadOnly dataView) @system
    {
        shader.destroy();
        shader = null;
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
        bgfx_transient_index_buffer_t tib;
        bgfx_transient_vertex_buffer_t tvb;
        uint32_t max = 6; /* 6 vertices */

        auto sprite = dataView.data!SpriteComponent(entity);

        auto width = sprite.texture.width;
        auto height = sprite.texture.height;

        /* Sort out the index buffer */
        bgfx_alloc_transient_index_buffer(&tib, 6);
        auto indexData = cast(uint16_t*) tib.data;
        indexData[0] = 0;
        indexData[1] = 1;
        indexData[2] = 3;
        indexData[3] = 1;
        indexData[4] = 2;
        indexData[5] = 3;

        auto clip = sprite.texture.clip();

        /* Sort out the vertex buffer */
        bgfx_alloc_transient_vertex_buffer(&tvb, max, &PosUVVertex.layout);
        auto vertexData = cast(PosUVVertex*) tvb.data;
        vertexData[0] = PosUVVertex(vec3f(1.0f, 1.0f, 0.0f), vec2f(clip.max.x, clip.min.y)); // Top right
        vertexData[1] = PosUVVertex(vec3f(1.0f, -1.0f, 0.0f), vec2f(clip.max.x, clip.max.y)); // Bottom right
        vertexData[2] = PosUVVertex(vec3f(-1.0f, -1.0f, 0.0f), vec2f(clip.min.x, clip.max.y)); // Bottom Left
        vertexData[3] = PosUVVertex(vec3f(-1.0f, 1.0f, 0.0f), vec2f(clip.min.x, clip.min.y)); // Top Left

        /* Set the stage */
        bgfx_set_transient_vertex_buffer(0, &tvb, 0, 4);
        bgfx_set_transient_index_buffer(&tib, 0, 6);
        bgfx_set_texture(0, cast(bgfx_uniform_handle_t) 0,
                sprite.texture.handle, BGFX_SAMPLER_U_CLAMP | BGFX_SAMPLER_V_CLAMP);

        /* Submit draw call */
        bgfx_set_state(0UL | BGFX_STATE_WRITE_RGB | BGFX_STATE_WRITE_A | BlendState.Alpha, 0);
        bgfx_submit(0, shader.handle, 0, false);
    }
}
