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
            static PosUVVertex[] vertices = [
                {vec3f(-0.8f, 0.8f, 0.0f), vec2f(0.0f, 0.0f)},
                {vec3f(-0.8f, -0.8f, 0.0f), vec2f(0.0f, 1.0f)},
                {vec3f(0.8f, -0.8f, 0.0f), vec2f(1.0f, 1.0f)},
                {vec3f(0.8f, 0.8f, 0.0f), vec2f(1.0f, 0.0f)}
            ];
            static uint16_t[] indices = [0, 1, 2, 2, 3, 0];

            /* Make vertex buffer */
            auto sizeV = cast(uint)(vertices.length * PosUVVertex.sizeof);
            auto vb = bgfx_create_vertex_buffer(bgfx_make_ref(vertices.ptr,
                    sizeV), &PosUVVertex.layout, 0);

            /* Make index buffer */
            auto sizeI = cast(uint)(indices.length * indices.sizeof);
            auto ib = bgfx_create_index_buffer(bgfx_make_ref(indices.ptr, sizeI), 0);

            bgfx_set_vertex_buffer(0, vb, 0, cast(uint) vertices.length);
            bgfx_set_index_buffer(ib, 0, cast(uint) indices.length);
            auto flags = BGFX_SAMPLER_U_CLAMP | BGFX_SAMPLER_V_CLAMP;
            bgfx_set_texture(0, cast(bgfx_uniform_handle_t) 0, texture.handle, flags);

            /* Try to draw it */
            bgfx_set_state(BGFX_STATE_DEFAULT, 0);
            bgfx_submit(0, shader.handle, 0, false);
            break;
        }
        /* TODO: Something useful */
        return;
    }
}
