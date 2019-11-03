/*
 * This file is part of serpent.
 *
 * Copyright © 2019 Lispy Snake, Ltd.
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

module serpent.graphics.renderer.sprite;

import bindbc.bgfx;
import gfm.math;

import serpent.entity;
import serpent.graphics.pipeline;
import serpent.graphics.shader;
import serpent.graphics.texture;

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
 * A Sprite is currently considered anything that is an Entity2D.
 * This will change in future to tag various base types.
 *
 * TODO: Optimise this into a batching sprite renderer. For now we're
 * going to be ugly and draw a quad at a time.
 */
final class SpriteRenderer : Renderer
{
    Program shader = null;
    Texture texture = null;

    final override void init()
    {
        auto vp = context.resource.substitutePath(
                context.resource.root ~ "/shaders/${shaderModel}/sprite_2d_vertex.bin");
        auto fp = context.resource.substitutePath(
                context.resource.root ~ "/shaders/${shaderModel}/sprite_2d_fragment.bin");
        auto vertex = new Shader(vp);
        auto fragment = new Shader(fp);
        shader = new Program(vertex, fragment);
        texture = new Texture("titlescreen.png");
    }

    final override void render() @system
    {
        import std.stdio;
        import std.stdint;

        auto ents = pipeline.display.scene.visibleEntities();
        foreach (ent; ents)
        {
            uint max = 32 << 10;
            bgfx_transient_index_buffer_t tib;
            bgfx_transient_vertex_buffer_t tvb;

            /* Just prove to ourselves camera offsets now kinda work. */
            auto x = 100.0f;
            auto y = 100.0f;

            auto model = mat4x4f.identity();
            auto translation = mat4x4f.translation(vec3f(-x, y, 0.0f));
            model = model.rotateX(radians(0.0f));
            model = model.rotateY(radians(0.0f));
            model = model.rotateZ(radians(180.0f));
            model = translation * model;

            // Scale to correct size
            model.scale(vec3f(pipeline.display.width, pipeline.display.height, 1.0f));
            model = model.transposed();

            /* Sort out the index buffer */
            bgfx_alloc_transient_index_buffer(&tib, 6);
            auto indexData = cast(uint16_t*) tib.data;
            indexData[0] = 0;
            indexData[1] = 1;
            indexData[2] = 2;
            indexData[3] = 2;
            indexData[4] = 3;
            indexData[5] = 0;

            /* Sort out the vertex buffer */
            bgfx_alloc_transient_vertex_buffer(&tvb, max, &PosUVVertex.layout);
            auto vertexData = cast(PosUVVertex*) tvb.data;
            vertexData[0] = PosUVVertex(vec3f(-1.0f, 1.0f, 0.0f), vec2f(0.0f, 0.0f));
            vertexData[1] = PosUVVertex(vec3f(-1.0f, -1.0f, 0.0f), vec2f(0.0f, 1.0f));
            vertexData[2] = PosUVVertex(vec3f(1.0f, -1.0f, 0.0f), vec2f(1.0f, 1.0f));
            vertexData[3] = PosUVVertex(vec3f(1.0f, 1.0f, 0.0f), vec2f(1.0f, 0.0f));

            bgfx_set_transform(model.ptr, 1);

            /* Set the stage */
            bgfx_set_transient_vertex_buffer(0, &tvb, 0, 4);
            bgfx_set_transient_index_buffer(&tib, 0, 6);
            auto flags = BGFX_SAMPLER_U_CLAMP | BGFX_SAMPLER_V_CLAMP;
            bgfx_set_texture(0, cast(bgfx_uniform_handle_t) 0, texture.handle, flags);

            /* Submit draw call */
            bgfx_set_state(BGFX_STATE_DEFAULT, 0);
            bgfx_submit(0, shader.handle, 0, false);
            break;
        }
        /* TODO: Something useful */
        return;
    }
}
