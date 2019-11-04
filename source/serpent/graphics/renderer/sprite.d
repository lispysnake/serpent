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
import std.stdint;

import serpent.entity;
import serpent.camera : WorldOrigin;
import serpent.graphics.blend;
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
 * A Sprite is currently considered anything that is an Enity.
 * This will change in future to tag various base types.
 *
 * TODO: Optimise this into a batching sprite renderer. For now we're
 * going to be ugly and draw a quad at a time. This results in multiple
 * draw calls per frame, and is hella inefficient.
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
        texture = new Texture("assets/ship.png");
    }

    final override void render() @system
    {
        auto ents = pipeline.display.scene.visibleEntities();
        foreach (ent; ents)
        {
            foreach (i; 0 .. ent.size())
            {
                drawOne(ent, i);
            }
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
    final void drawOne(Entity entitySet, ulong index)
    {
        bgfx_transient_index_buffer_t tib;
        bgfx_transient_vertex_buffer_t tvb;
        uint32_t max = 6; /* 6 vertices */

        auto width = texture.width;
        auto height = texture.height;

        auto position = entitySet.getPosition(index);
        auto position2 = pipeline.display.scene.camera.unproject(position);

        position2.x += width;
        if (pipeline.display.scene.camera.worldOrigin == WorldOrigin.BottomLeft)
        {
            position2.y += height;
        }
        else
        {
            position2.y -= height;
        }

        auto translation = mat4x4f.translation(position2);
        auto scale = mat4x4f.scaling(vec3f(width, height, 1.0f));
        //auto rotation = mat4x4f.rotation(radians(180.0f), vec3f(0.0f, 0.0f, 1.0f));
        auto model = translation * scale;
        model = model.transposed();

        /* Sort out the index buffer */
        bgfx_alloc_transient_index_buffer(&tib, 6);
        auto indexData = cast(uint16_t*) tib.data;
        indexData[0] = 0;
        indexData[1] = 1;
        indexData[2] = 3;
        indexData[3] = 1;
        indexData[4] = 2;
        indexData[5] = 3;

        static const auto tx1 = 0.0f;
        static const auto ty1 = 0.0f;
        static const auto tx2 = 1.0f;
        static const auto ty2 = 1.0f;

        /* Sort out the vertex buffer */
        bgfx_alloc_transient_vertex_buffer(&tvb, max, &PosUVVertex.layout);
        auto vertexData = cast(PosUVVertex*) tvb.data;
        vertexData[0] = PosUVVertex(vec3f(1.0f, 1.0f, 0.0f), vec2f(tx2, ty1)); // Top right
        vertexData[1] = PosUVVertex(vec3f(1.0f, -1.0f, 0.0f), vec2f(tx2, ty2)); // Bottom right
        vertexData[2] = PosUVVertex(vec3f(-1.0f, -1.0f, 0.0f), vec2f(tx1, ty2)); // Bottom Left
        vertexData[3] = PosUVVertex(vec3f(-1.0f, 1.0f, 0.0f), vec2f(tx1, ty1)); // Top Left

        bgfx_set_transform(model.ptr, 1);

        /* Set the stage */
        bgfx_set_transient_vertex_buffer(0, &tvb, 0, 4);
        bgfx_set_transient_index_buffer(&tib, 0, 6);
        bgfx_set_texture(0, cast(bgfx_uniform_handle_t) 0, texture.handle,
                BGFX_SAMPLER_U_CLAMP | BGFX_SAMPLER_V_CLAMP);

        /* Submit draw call */
        bgfx_set_state(0UL | BGFX_STATE_WRITE_RGB | BGFX_STATE_WRITE_A | BlendState.Alpha, 0);
        bgfx_submit(0, shader.handle, 0, false);
    }
}
