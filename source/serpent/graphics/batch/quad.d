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
import serpent.core.lockingringbuffer;

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

    LockingRingBuffer!TexturedQuad drawOps;

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

        /* TODO: Make this cleaner, we don't want each shader consumer picking the
         * shader code itself, factoryfy it
         */

        /* Vulkan shaders */
        static auto vp_vulkan = import("texturedQuad/spirv.vertex");
        static auto fp_vulkan = import("texturedQuad/spirv.fragment");

        /* OpenGL shaders */
        static auto vp_opengl = import("texturedQuad/glsl.vertex");
        static auto fp_opengl = import("texturedQuad/glsl.fragment");

        import serpent.graphics.pipeline.info;

        if (context.display.pipeline.info.driverType == DriverType.OpenGL)
        {
            shader = new Program(Shader.fromContents(vp_opengl), Shader.fromContents(fp_opengl));
        }
        else
        {
            shader = new Program(Shader.fromContents(vp_vulkan), Shader.fromContents(fp_vulkan));
        }

        queue = BatchQueue!(PosUVVertex, uint16_t)(128, 100_000, 6, 4);

        /* Allow 131K sprites max */
        drawOps = LockingRingBuffer!TexturedQuad(2 << 6, 2 << 16);
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
    final void drawTexturedQuad(bgfx_encoder_t* encoder, const(Texture) texture,
            vec3f transformPosition, vec3f transformScale) @trusted
    {
        drawTexturedQuad(encoder, texture, transformPosition, transformScale,
                texture.width, texture.height, texture.uv());
    }

    /**
     * Draw a sprite with the given width and height, texture and transform.
     * The default clip region is assumed.
     */
    final void drawTexturedQuad(bgfx_encoder_t* encoder, const(Texture) texture,
            vec3f transformPosition, vec3f transformScale, float width, float height) @trusted
    {
        drawTexturedQuad(encoder, texture, transformPosition, transformScale,
                width, height, texture.uv());
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
    final void drawTexturedQuad(bgfx_encoder_t* encoder, const(Texture) texture,
            vec3f transformPosition, vec3f transformScale, float width,
            float height, UVCoordinates uv) @trusted
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
        quad.uv = uv;

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
                    transformPosition.z), vec2f(quad.uv.u1, quad.uv.v1)),
            PosUVVertex(vec3f(transformPosition.x + spriteWidth,
                    transformPosition.y, transformPosition.z), vec2f(quad.uv.u2, quad.uv.v1)),
            PosUVVertex(vec3f(transformPosition.x + spriteWidth,
                    transformPosition.y + spriteHeight, transformPosition.z),
                    vec2f(quad.uv.u2, quad.uv.v2)),
            PosUVVertex(vec3f(transformPosition.x, transformPosition.y + spriteHeight,
                    transformPosition.z), vec2f(quad.uv.u1, quad.uv.v2))
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
        bgfx_encoder_set_texture(encoder, 0, cast(bgfx_uniform_handle_t) 0,
                texture.handle, uint32_t.max);

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
