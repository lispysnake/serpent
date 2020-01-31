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

module serpent.graphics.batch;

import bindbc.bgfx;
import std.stdint;
import std.container.array;
import std.container.binaryheap;

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
 * A batched sprite renderer (textured quads) for 2D perspectives.
 * Draws are ordered based on the textures to minimise expensive
 * texture switches, thus it is far cheaper to use a QuadBatch
 * in conjunction with spritesheets.
 */

final class QuadBatch
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
    ulong quadIndex = 0;

    uint _maxQuads = 3000; /**<Default to caching 3000 sprites before implicit flush */
    uint _maxQuadsPerDraw = 1000; /**<Default to 1000 quads per call */

    Array!TexturedQuad drawOps;

    /**
     * Update the current Context
     */
    pure @property final void context(Context context) @safe @nogc nothrow
    {
        _context = context;
    }

public:

    /**
     * Construct a new QuadBatch helper
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
        drawOps.reserve(maxQuads);
        drawOps.length = maxQuads;
        maxVertices = numVertices * maxQuadsPerDraw;
        maxIndices = numIndices * maxQuadsPerDraw;
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
    final void drawTexturedQuad(bgfx_encoder_t* encoder,
            immutable(Texture) texture, vec3f transformPosition, vec3f transformScale) @trusted
    {
        drawTexturedQuad(encoder, texture, transformPosition, transformScale,
                texture.width, texture.height, texture.clip());
    }

    /**
     * Draw a sprite with the given width and height, texture and transform.
     * The default clip region is assumed.
     */
    final void drawTexturedQuad(bgfx_encoder_t* encoder, immutable(Texture) texture,
            vec3f transformPosition, vec3f transformScale, float width, float height) @trusted
    {
        drawTexturedQuad(encoder, texture, transformPosition, transformScale,
                width, height, texture.clip());
    }

    /**
     * Begin a frame step. At this point we'll simply allocate necessary resources
     * to complete a whole frame.
     */
    final void begin() @trusted
    {

        bgfx_alloc_transient_index_buffer(&tib, maxIndices);
        bgfx_alloc_transient_vertex_buffer(&tvb, maxVertices, &PosUVVertex.layout);
    }

    /**
     * Draw the sprite texture using the given transform, width, height and clip region.
     */
    final void drawTexturedQuad(bgfx_encoder_t* encoder, immutable(Texture) texture,
            vec3f transformPosition, vec3f transformScale, float width, float height, box2f clip) @trusted
    {
        /* Straight up copy it into the draw queue */
        drawOps[quadIndex].texture = cast(Texture) texture;
        drawOps[quadIndex].transformPosition = transformPosition;
        drawOps[quadIndex].transformScale = transformScale;
        drawOps[quadIndex].width = width;
        drawOps[quadIndex].height = height;
        drawOps[quadIndex].clip = clip;

        ++quadIndex;

        /* When too many quads are added, force a flush */
        if (quadIndex >= maxQuads)
        {
            flush(encoder);
            quadIndex = 0;
        }
    }

    /**
     * Finish our batch encoding for the current texture
     */
    final void flush(bgfx_encoder_t* encoder) @trusted
    {
        if (quadIndex < 1)
        {
            return;
        }

        auto heap = heapify!("a.texture.path < b.texture.path")(drawOps[0 .. quadIndex]);
        uint drawIndex = 0;
        Texture lastTexture = null;
        foreach (ref item; heap)
        {
            if (drawIndex >= maxQuadsPerDraw)
            {
                blitQuads(encoder, drawIndex + 1, lastTexture);
                drawIndex = 0;
            }
            if (lastTexture != item.texture)
            {
                if (lastTexture !is null)
                {
                    blitQuads(encoder, drawIndex + 1, lastTexture);
                    drawIndex = 0;
                }
                lastTexture = item.texture;
            }

            renderQuad(encoder, drawIndex, item);
            ++drawIndex;
        }
        heap.release();
        blitQuads(encoder, drawIndex + 1, lastTexture);

        /* Finished now, set the quadIndex. */
        quadIndex = 0;
    }

    final void renderQuad(bgfx_encoder_t* encoder, uint drawIndex, ref TexturedQuad quad) @trusted
    {
        auto invWidth = 1.0f / quad.texture.width;
        auto invHeight = 1.0f / quad.texture.height;
        auto u1 = quad.clip.min.x * invWidth;
        auto v1 = quad.clip.min.y * invHeight;
        auto u2 = (quad.clip.min.x + quad.width) * invWidth;
        auto v2 = (quad.clip.min.y + quad.height) * invHeight;

        auto transformPosition = quad.transformPosition;
        transformPosition.x -= (context.display.width / 2.0f);
        transformPosition.y -= (context.display.height / 2.0f);

        /* index position */
        auto i = drawIndex * numIndices;

        /* vertex position */
        auto v = drawIndex * numVertices;
        auto indexData = cast(uint16_t*) tib.data;

        /* update indices */
        indexData[i] = cast(ushort)(v);
        indexData[i + 1] = cast(ushort)(v + 1);
        indexData[i + 2] = cast(ushort)(v + 2);
        indexData[i + 3] = cast(ushort)(v + 2);
        indexData[i + 4] = cast(ushort)(v + 3);
        indexData[i + 5] = cast(ushort)(v);

        /* update vertices */
        auto vertexData = cast(PosUVVertex*) tvb.data;
        vertexData[v] = PosUVVertex(vec3f(transformPosition.x,
                transformPosition.y, 0.0f), vec2f(u1, v1));
        vertexData[v + 1] = PosUVVertex(vec3f(transformPosition.x + quad.width,
                transformPosition.y, 0.0f), vec2f(u2, v1));
        vertexData[v + 2] = PosUVVertex(vec3f(transformPosition.x + quad.width,
                transformPosition.y + quad.height, 0.0f), vec2f(u2, v2));
        vertexData[v + 3] = PosUVVertex(vec3f(transformPosition.x,
                transformPosition.y + quad.height, 0.0f), vec2f(u1, v2));
    }

    final void blitQuads(bgfx_encoder_t* encoder, uint numQuads, Texture texture) @trusted
    {
        if (numQuads < 1 || texture is null)
        {
            return;
        }

        auto model = mat4x4f.identity();
        bgfx_encoder_set_transform(encoder, model.ptr, 1);

        bgfx_encoder_set_transient_vertex_buffer(encoder, 0, &tvb, 0,
                numVertices * numQuads, tvb.layoutHandle);
        bgfx_encoder_set_transient_index_buffer(encoder, &tib, 0, numIndices * numQuads);
        bgfx_encoder_set_texture(encoder, 0, cast(bgfx_uniform_handle_t) 0,
                texture.handle, BGFX_SAMPLER_U_CLAMP | BGFX_SAMPLER_V_CLAMP);

        bgfx_encoder_set_state(encoder,
                0UL | BGFX_STATE_WRITE_RGB | BGFX_STATE_WRITE_A | BlendState.Alpha, 0);
        bgfx_encoder_submit(encoder, 0, shader.handle, 0, false);

        /* Allocate a new VB/IB pair */
        begin();
    }
    /**
     * Return the underlying Context for this QuadBatch instance
     */
    pure @property final Context context() @safe @nogc nothrow
    {
        return _context;
    }

    /**
     * The absolute top number of quads we'll cache before attempting to
     * batch.
     */
    pure @property final const uint maxQuads() @safe @nogc nothrow
    {
        return _maxQuads;
    }

    /**
     * The maximum number of quads to attempt in any draw call. Note this
     * does not directly control the maximum calls per frame, but it certainly
     * ooes influence it.
     */
    pure @property final const uint maxQuadsPerDraw() @safe @nogc nothrow
    {
        return _maxQuadsPerDraw;
    }
}
