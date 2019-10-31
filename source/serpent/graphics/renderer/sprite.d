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

struct PosVertex
{

    vec3f pos;

    static bgfx_vertex_layout_t layout;

    static this()
    {
        bgfx_vertex_layout_begin(&layout, bgfx_renderer_type_t.BGFX_RENDERER_TYPE_NOOP);

        /* Position */
        bgfx_vertex_layout_add(&layout, bgfx_attrib_t.BGFX_ATTRIB_POSITION, 3,
                bgfx_attrib_type_t.BGFX_ATTRIB_TYPE_FLOAT, false, false);

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

    this()
    {
        auto vertex = new Shader("assets/built/shaders/spirv/sprite_2d_vertex.bin");
        auto fragment = new Shader("assets/built/shaders/spirv/sprite_2d_fragment.bin");
        shader = new Program(vertex, fragment);
    }

    final override void render() @system
    {
        import std.stdio;

        float x_offset = 0.0f;
        float y_offset = 0.0f;

        auto ents = pipeline.display.scene.visibleEntities();
        foreach (ent; ents)
        {
            /* Set up our transient buffer. */
            auto maxV = 32 << 10;
            bgfx_transient_vertex_buffer_t tvb;
            bgfx_alloc_transient_vertex_buffer(&tvb, maxV, &PosVertex.layout);

            PosVertex* vertex = cast(PosVertex*) tvb.data;
            /* bottom triangle */
            vertex[0].pos = vec3f(0.5f + x_offset, 0.5f + y_offset, 0.0f);
            vertex[1].pos = vec3f(-0.5f + x_offset, -0.5f + y_offset, 0.0f);
            vertex[2].pos = vec3f(0.5f + x_offset, -0.5f + y_offset, 0.0f);
            vertex[3].pos = vec3f(0.5f + x_offset, 0.5f + y_offset, 0.0f);
            vertex[4].pos = vec3f(-0.5f + x_offset, 0.5f + y_offset, 0.0f);
            vertex[5].pos = vec3f(-0.5f + x_offset, -0.5f + y_offset, 0.0f);

            /* Try to draw it */
            bgfx_set_transient_vertex_buffer(0, &tvb, 0, maxV);
            bgfx_set_state(BGFX_STATE_DEFAULT, 0);
            bgfx_submit(0, shader.handle, 0, false);

            x_offset += 0.10;
            y_offset += 0.15;
        }
        /* TODO: Something useful */
        return;
    }
}
