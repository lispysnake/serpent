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

module serpent.graphics.pipeline.bgfx.framebuffer;

public import serpent.graphics.pipeline.framebuffer;
public import serpent.graphics.pipeline.bgfx.pipeline : BgfxPipeline;

/**
 * The BgfxFrameBuffer wraps the bgfx_frame_buffer_handle_t to make
 * it trivial to use.
 */
final class BgfxFrameBuffer : FrameBuffer
{

package:

    /**
     * Construct a new BgfxFrameBuffer for the given parent
     */
    this(BgfxPipeline parent) @safe
    {
        super(parent);
    }

public:

    /**
     * Bind underlying FBO ready for use
     */
    final override void bind() @system @nogc nothrow
    {
    }

    /**
     * Unbind underlying FBO
     */
    final override void unbind() @system @nogc nothrow
    {
    }
}
