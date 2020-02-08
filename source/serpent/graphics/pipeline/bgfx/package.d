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

module serpent.graphics.pipeline.bgfx;

public import serpent.graphics.pipeline.info;
public import bindbc.bgfx : bgfx_renderer_type_t;

/**
 * This package provides the bgfx implementation of our graphical pipeline
 * We've designed an abstraction around the underlying API in order to provide
 * a more D-centric way of doing things.
 */

public import serpent.graphics.pipeline.bgfx.pipeline;

/**
     * Convert a bgfx_renderer_type_t to a serpent.info.DriverType
     */
pure final DriverType convRenderer(bgfx_renderer_type_t renType) @nogc @safe nothrow
{
    switch (renType)
    {
    case bgfx_renderer_type_t.BGFX_RENDERER_TYPE_NOOP:
        return DriverType.None;
    case bgfx_renderer_type_t.BGFX_RENDERER_TYPE_DIRECT3D9:
        return DriverType.Direct3D9;
    case bgfx_renderer_type_t.BGFX_RENDERER_TYPE_DIRECT3D11:
        return DriverType.Direct3D11;
    case bgfx_renderer_type_t.BGFX_RENDERER_TYPE_DIRECT3D12:
        return DriverType.Direct3D12;
    case bgfx_renderer_type_t.BGFX_RENDERER_TYPE_GNM:
        return DriverType.Gnm;
    case bgfx_renderer_type_t.BGFX_RENDERER_TYPE_METAL:
        return DriverType.Metal;
    case bgfx_renderer_type_t.BGFX_RENDERER_TYPE_NVN:
        return DriverType.Nvn;
    case bgfx_renderer_type_t.BGFX_RENDERER_TYPE_OPENGLES:
        return DriverType.OpenGLES;
    case bgfx_renderer_type_t.BGFX_RENDERER_TYPE_OPENGL:
        return DriverType.OpenGL;
    case bgfx_renderer_type_t.BGFX_RENDERER_TYPE_VULKAN:
        return DriverType.Vulkan;
    default:
        return DriverType.Unsupported;
    }
}

/**
     * Convert a DriverType to a bgfx_renderer_type_t
     */
public final bgfx_renderer_type_t convDriver(DriverType driverType) @nogc @safe nothrow
{
    switch (driverType)
    {
    case DriverType.None:
        return bgfx_renderer_type_t.BGFX_RENDERER_TYPE_NOOP;
    case DriverType.Direct3D9:
        return bgfx_renderer_type_t.BGFX_RENDERER_TYPE_DIRECT3D9;
    case DriverType.Direct3D11:
        return bgfx_renderer_type_t.BGFX_RENDERER_TYPE_DIRECT3D11;
    case DriverType.Direct3D12:
        return bgfx_renderer_type_t.BGFX_RENDERER_TYPE_DIRECT3D12;
    case DriverType.Gnm:
        return bgfx_renderer_type_t.BGFX_RENDERER_TYPE_GNM;
    case DriverType.Metal:
        return bgfx_renderer_type_t.BGFX_RENDERER_TYPE_METAL;
    case DriverType.OpenGLES:
        return bgfx_renderer_type_t.BGFX_RENDERER_TYPE_OPENGLES;
    case DriverType.OpenGL:
        return bgfx_renderer_type_t.BGFX_RENDERER_TYPE_OPENGL;
    case DriverType.Vulkan:
        return bgfx_renderer_type_t.BGFX_RENDERER_TYPE_VULKAN;
    default:
        return bgfx_renderer_type_t.BGFX_RENDERER_TYPE_COUNT;
    }
}
