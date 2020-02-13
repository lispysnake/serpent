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

module serpent.graphics.batch.quad;

import bindbc.bgfx;
import std.stdint;
import std.container.array;

import serpent.camera : WorldOrigin;
import serpent.graphics.shader;
import serpent.graphics.blend;
import serpent.graphics.vertex;
import serpent.graphics.uv : UVCoordinates;
import serpent.graphics.batch.queue : BatchQueue;
import serpent.graphics.batch : TexturedQuad;
import serpent.core.ringbuffer;

public import serpent.core.context;
public import serpent.graphics.texture;
public import gfm.math;

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

    RingBuffer!TexturedQuad drawOps;

    BatchQueue!(PosUVVertex, uint16_t) queue;

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

        queue = BatchQueue!(PosUVVertex, uint16_t)(128, 100_000, 6, 4);

        /* Allow 100k sprites max */
        drawOps = RingBuffer!TexturedQuad(100_000);
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
        queue.reset();
    }

    /**
     * Draw the sprite texture using the given transform, width, height and clip region.
     */
    final void drawTexturedQuad(bgfx_encoder_t* encoder, immutable(Texture) texture,
            vec3f transformPosition, vec3f transformScale, float width, float height, box2f clip) @trusted
    {
        /* When too many quads are added, force a flush */
        if (drawOps.full())
        {
            flush(encoder);
        }

        /* Straight up copy it into the draw queue */
        auto quad = TexturedQuad();
        quad.texture = cast(Texture) texture;
        quad.transformPosition = transformPosition;
        quad.transformScale = transformScale;
        quad.width = width;
        quad.height = height;
        quad.clip = clip;

        drawOps.add(quad);
    }

    /**
     * Finish our batch encoding for the current texture
     */
    final void flush(bgfx_encoder_t* encoder) @trusted
    {
        uint drawIndex = 0;
        Texture lastTexture = null;
        import std.algorithm.sorting;
        import std.algorithm.mutation;

        /* Sort order is important for drawing */
        multiSort!("a.transformPosition.z < b.transformPosition.z",
                "a.texture.path < b.texture.path", SwapStrategy.unstable)(drawOps.data);
        foreach (ref item; drawOps.data)
        {
            if (queue.full())
            {
                blitQuads(encoder, drawIndex, lastTexture);
                drawIndex = 0;
            }

            if (lastTexture != item.texture)
            {
                if (lastTexture !is null)
                {
                    blitQuads(encoder, drawIndex, lastTexture);
                    drawIndex = 0;
                }
                lastTexture = item.texture;
            }

            renderQuad(encoder, drawIndex, item);
            ++drawIndex;
        }
        blitQuads(encoder, drawIndex, lastTexture);
        drawOps.reset();
    }

    final void renderQuad(bgfx_encoder_t* encoder, uint drawIndex, ref TexturedQuad quad) @trusted
    {
        auto uv = UVCoordinates(quad.texture.width, quad.texture.height, quad.clip);

        auto realWidth = context.display.logicalWidth;
        auto realHeight = context.display.logicalHeight;
        auto transformPosition = quad.transformPosition;

        /* Scale it */
        auto spriteWidth = quad.width * quad.transformScale.x;
        auto spriteHeight = quad.height * quad.transformScale.y;

        /* Anchor it */
        transformPosition.x -= (realWidth / 2.0f);
        transformPosition.y -= (realHeight / 2.0f);

        /* Remove the cameraPosition */
        transformPosition -= context.display.scene.camera.position;

        /* index position */
        auto i = drawIndex * numIndices;

        /* vertex position */
        auto v = drawIndex * numVertices;

        /* Push indices */
        uint16_t[6] idata = [
            cast(uint16_t) v, cast(uint16_t)(v + 1), cast(uint16_t)(v + 2),
            cast(uint16_t)(v + 2), cast(uint16_t)(v + 3), cast(uint16_t) v,
        ];
        queue.pushIndices(idata);

        /* Push vertices */
        PosUVVertex[4] vdata = [
            PosUVVertex(vec3f(transformPosition.x, transformPosition.y,
                    transformPosition.z), vec2f(uv.u1, uv.v1)),
            PosUVVertex(vec3f(transformPosition.x + spriteWidth,
                    transformPosition.y, transformPosition.z), vec2f(uv.u2, uv.v1)),
            PosUVVertex(vec3f(transformPosition.x + spriteWidth,
                    transformPosition.y + spriteHeight, transformPosition.z), vec2f(uv.u2, uv.v2)),
            PosUVVertex(vec3f(transformPosition.x, transformPosition.y + spriteHeight,
                    transformPosition.z), vec2f(uv.u1, uv.v2))
        ];
        queue.pushVertices(vdata);
    }

    final void blitQuads(bgfx_encoder_t* encoder, uint numQuads, Texture texture) @trusted
    {
        if (numQuads < 1 || texture is null)
        {
            return;
        }

        bgfx_alloc_transient_index_buffer(&tib, cast(uint) queue.indicesCount());
        bgfx_alloc_transient_vertex_buffer(&tvb,
                cast(uint) queue.verticesCount(), &PosUVVertex.layout);

        auto indexData = cast(uint16_t*) tib.data;
        auto vertexData = cast(PosUVVertex*) tvb.data;

        queue.copyVertices(vertexData);
        queue.copyIndices(indexData);

        auto model = mat4x4f.identity();
        auto trans = mat4x4f.translation(vec3f(0.0f, 0.0f, 0.0f));
        auto scaleX = cast(float)(cast(float) context.display.width / cast(
                float) context.display.logicalWidth);
        auto scaleY = cast(float)(cast(float) context.display.height / cast(
                float) context.display.logicalHeight);
        auto scale = mat4x4f.scaling(vec3f(scaleX, scaleY, 1.0f));
        model = trans * scale;
        bgfx_encoder_set_transform(encoder, model.ptr, 1);

        bgfx_encoder_set_transient_vertex_buffer(encoder, 0, &tvb, 0,
                cast(uint) queue.verticesCount(), tvb.layoutHandle);
        bgfx_encoder_set_transient_index_buffer(encoder, &tib, 0, cast(uint) queue.indicesCount());
        bgfx_encoder_set_texture(encoder, 0, cast(bgfx_uniform_handle_t) 0, texture.handle,
                BGFX_SAMPLER_U_CLAMP | BGFX_SAMPLER_V_CLAMP | BGFX_SAMPLER_MAG_POINT);

        bgfx_encoder_set_state(encoder, 0UL | BGFX_STATE_WRITE_RGB | BGFX_STATE_WRITE_A
                | BGFX_STATE_DEPTH_TEST_LEQUAL | BGFX_STATE_WRITE_Z | BlendState.Alpha, 0);
        bgfx_encoder_submit(encoder, 0, shader.handle, 0, false);

        /* Allocate a new VB/IB pair */
        queue.reset();
    }
    /**
     * Return the underlying Context for this QuadBatch instance
     */
    pure @property final Context context() @safe @nogc nothrow
    {
        return _context;
    }
}
