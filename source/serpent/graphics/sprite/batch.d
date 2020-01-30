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

module serpent.graphics.sprite.batch;

import bindbc.bgfx;
import std.stdint;

import serpent.camera : WorldOrigin;
import serpent.graphics.shader;
import serpent.graphics.blend;
import serpent.graphics.vertex;

public import serpent.core.context;
public import serpent.graphics.texture;
public import gfm.math;

/**
 * Eventually this will become a batching Sprite renderer, that is, something
 * that is a textured quad.
 *
 * Right now it just blits a texture with no regard for optimisation or
 * ordering.
 *
 * TODO: Make suck less.
 */

final class SpriteBatch
{

private:

    Program shader = null;
    Context _context = null;

    /**
     * Update the current Context
     */
    pure @property final void context(Context context) @safe @nogc nothrow
    {
        _context = context;
    }

public:

    /**
     * Construct a new SpriteBatch helper
     */
    this(Context context)
    {
        this.context = context;
        auto vp = context.resource.substitutePath(
                context.resource.root ~ "/shaders/${shaderModel}/sprite_2d_vertex.bin");
        auto fp = context.resource.substitutePath(
                context.resource.root ~ "/shaders/${shaderModel}/sprite_2d_fragment.bin");
        auto vertex = new Shader(vp);
        auto fragment = new Shader(fp);
        shader = new Program(vertex, fragment);
    }

    ~this()
    {
        shader.destroy();
        shader = null;
    }

    /**
     * Draw a sprite with the given texture and transform. The default clip region
     * is assumed as are the width and height
     */
    final void drawSprite(immutable(Texture) texture, vec3f transformPosition, vec3f transformScale) @trusted
    {
        drawSprite(texture, transformPosition, transformScale, texture.width,
                texture.height, texture.clip());
    }

    /**
     * Draw a sprite with the given width and height, texture and transform.
     * The default clip region is assumed.
     */
    final void drawSprite(immutable(Texture) texture, vec3f transformPosition,
            vec3f transformScale, float width, float height) @trusted
    {
        drawSprite(texture, transformPosition, transformScale, width, height, texture.clip());
    }

    /**
     * Draw the sprite texture using the given transform, width, height and clip region.
     */
    final void drawSprite(immutable(Texture) texture, vec3f transformPosition,
            vec3f transformScale, float width, float height, box2f clip) @trusted
    {
        bgfx_transient_index_buffer_t tib;
        bgfx_transient_vertex_buffer_t tvb;
        uint32_t max = 6; /* 6 vertices */

        /* Really need precomputed CameraTransform. */
        auto position = context.display.scene.camera.unproject(transformPosition);

        /* TODO: Have camera stuff cached + anchors */
        position.x += width;
        if (context.display.scene.camera.worldOrigin == WorldOrigin.BottomLeft)
        {
            position.y += height;
        }
        else
        {
            position.y -= height;
        }

        auto translation = mat4x4f.translation(position);
        auto scale = mat4x4f.scaling(vec3f(width * transformScale.x,
                height * transformScale.y, 1.0f));
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

        /* Sort out the vertex buffer */
        bgfx_alloc_transient_vertex_buffer(&tvb, max, &PosUVVertex.layout);
        auto vertexData = cast(PosUVVertex*) tvb.data;
        vertexData[0] = PosUVVertex(vec3f(1.0f, 1.0f, 0.0f), vec2f(clip.max.x, clip.min.y)); // Top right
        vertexData[1] = PosUVVertex(vec3f(1.0f, -1.0f, 0.0f), vec2f(clip.max.x, clip.max.y)); // Bottom right
        vertexData[2] = PosUVVertex(vec3f(-1.0f, -1.0f, 0.0f), vec2f(clip.min.x, clip.max.y)); // Bottom Left
        vertexData[3] = PosUVVertex(vec3f(-1.0f, 1.0f, 0.0f), vec2f(clip.min.x, clip.min.y)); // Top Left

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

    /**
     * Return the underlying Context for this SpriteBatch instance
     */
    pure @property final Context context() @safe @nogc nothrow
    {
        return _context;
    }
}
