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
import std.container.array;

import serpent.camera : WorldOrigin;
import serpent.graphics.shader;
import serpent.graphics.blend;
import serpent.graphics.vertex;

public import serpent.core.context;
public import serpent.graphics.texture;
public import gfm.math;

/**
 * TexturedQuad is a stacked drawing operation that helps us
 * to batch-draw multiple textured quads (i.e. sprites)
 */
static final struct TexturedQuad
{
    Texture texture;
    box2f clip;
    vec3f transformPosition;
    vec3f transformScale;
    float width;
    float height;
};

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
    uint maxVertices = 4; /* 4 vertices per quad */
    static const uint numVertices = 4;
    uint maxIndices = 6; /* 6 indices per quad */
    static const uint numIndices = 6;

    bgfx_transient_index_buffer_t tib;
    bgfx_transient_vertex_buffer_t tvb;
    ulong renderIndex = 0;

    Array!TexturedQuad drawOps;

    /**
     * Update the current Context
     */
    pure @property final void context(Context context) @safe @nogc nothrow
    {
        _context = context;
    }

    /**
     * begin the frame
     */
    final void begin() @trusted @nogc nothrow
    {
        bgfx_alloc_transient_index_buffer(&tib, numIndices);
        bgfx_alloc_transient_vertex_buffer(&tvb, numVertices, &PosUVVertex.layout);
        renderIndex = 0;
    }

    /**
     * Finish our batch encoding for the current texture
     */
    final void flush(bgfx_encoder_t* encoder, immutable(Texture) texture) @trusted @nogc nothrow
    {
        /* Ensure our model scales plane to the whole view */
        auto model = mat4x4f.identity();
        bgfx_encoder_set_transform(encoder, model.ptr, 1);

        /* Set the stage */
        bgfx_encoder_set_transient_vertex_buffer(encoder, 0, &tvb, 0,
                maxVertices, tvb.layoutHandle);
        bgfx_encoder_set_transient_index_buffer(encoder, &tib, 0, maxIndices);
        bgfx_encoder_set_texture(encoder, 0, cast(bgfx_uniform_handle_t) 0,
                texture.handle, BGFX_SAMPLER_U_CLAMP | BGFX_SAMPLER_V_CLAMP);

        /* Submit draw call */
        bgfx_encoder_set_state(encoder,
                0UL | BGFX_STATE_WRITE_RGB | BGFX_STATE_WRITE_A | BlendState.Alpha, 0);
        bgfx_encoder_submit(encoder, 0, shader.handle, 0, false);
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

        /* Allow 1000 sprites, 6000 indices, 4000 vertices */
        drawOps.reserve(1000);
        drawOps.length = 1000;
        maxVertices = numVertices * cast(uint) drawOps.length;
        maxIndices = numIndices * cast(uint) drawOps.length;
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
    final void drawSprite(bgfx_encoder_t* encoder, immutable(Texture) texture,
            vec3f transformPosition, vec3f transformScale) @trusted
    {
        drawSprite(encoder, texture, transformPosition, transformScale,
                texture.width, texture.height, texture.clip());
    }

    /**
     * Draw a sprite with the given width and height, texture and transform.
     * The default clip region is assumed.
     */
    final void drawSprite(bgfx_encoder_t* encoder, immutable(Texture) texture,
            vec3f transformPosition, vec3f transformScale, float width, float height) @trusted
    {
        drawSprite(encoder, texture, transformPosition, transformScale, width,
                height, texture.clip());
    }

    /**
     * Draw the sprite texture using the given transform, width, height and clip region.
     */
    final void drawSprite(bgfx_encoder_t* encoder, immutable(Texture) texture,
            vec3f transformPosition, vec3f transformScale, float width, float height, box2f clip) @trusted
    {
        begin();

        /* Sort out the index buffer */
        auto indexData = cast(uint16_t*) tib.data;
        indexData[renderIndex + 0] = cast(ushort)(0 + renderIndex);
        indexData[renderIndex + 1] = cast(ushort)(1 + renderIndex);
        indexData[renderIndex + 2] = cast(ushort)(2 + renderIndex);
        indexData[renderIndex + 3] = cast(ushort)(2 + renderIndex);
        indexData[renderIndex + 4] = cast(ushort)(3 + renderIndex);
        indexData[renderIndex + 5] = cast(ushort)(0 + renderIndex);

        auto invWidth = 1.0f / texture.width;
        auto invHeight = 1.0f / texture.height;
        auto u1 = clip.min.x * invWidth;
        auto v1 = clip.min.y * invHeight;
        auto u2 = (clip.min.x + width) * invWidth;
        auto v2 = (clip.min.y + height) * invHeight;

        /* Put the texture start from top left corner */
        transformPosition.x -= (context.display.width / 2.0f);
        transformPosition.y -= (context.display.height / 2.0f);

        /* Sort out the vertex buffer */
        auto vertexData = cast(PosUVVertex*) tvb.data;
        vertexData[renderIndex + 0] = PosUVVertex(vec3f(transformPosition.x,
                transformPosition.y, 0.0f), vec2f(u1, v1));
        vertexData[renderIndex + 1] = PosUVVertex(vec3f(transformPosition.x + width,
                transformPosition.y, 0.0f), vec2f(u2, v1));
        vertexData[renderIndex + 2] = PosUVVertex(vec3f(transformPosition.x + width,
                transformPosition.y + height, 0.0f), vec2f(u2, v2));
        vertexData[renderIndex + 3] = PosUVVertex(vec3f(transformPosition.x,
                transformPosition.y + height, 0.0f), vec2f(u1, v2));

        ++renderIndex;

        flush(encoder, texture);
    }

    /**
     * Return the underlying Context for this SpriteBatch instance
     */
    pure @property final Context context() @safe @nogc nothrow
    {
        return _context;
    }
}
