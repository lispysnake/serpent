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

module serpent.graphics.pipeline.info;

import bindbc.bgfx;

/**
 * DriverType is our own representation of bgfx_renderer_type_t
 */
enum DriverType
{
    None = 0,
    Direct3D9,
    Direct3D11,
    Direct3D12,
    Gnm,
    Metal,
    Nvn,
    OpenGLES,
    OpenGL,
    Vulkan,
    Unsupported, /** Should error out in this instance */



}

/**
 * ShaderModel indicates the language used for the underlying
 * driver. For example, GLSL is used for OpenGL/ES, whereas SPIRV
 * is used for Vulkan.
 */
enum ShaderModel
{
    None = 0,
    GLSL,
    Metal,
    SPIRV,
    Unsupported, /** Should error out in this instance */



};

/**
 * The Info class is populated at runtime with information on the
 * execution environment, to help with game portability.
 */
final struct Info
{

private:
    DriverType _driverType = DriverType.None;
    ShaderModel _shaderModel = ShaderModel.None;

    /**
     * Update the driver and automatically set the shader model
     */
    final @property void driverType(DriverType driver) @nogc @safe nothrow
    {
        _driverType = driver;
        _shaderModel = convShaderModel(driver);
    }

public:

    this(DriverType driverType) @safe @nogc nothrow
    {
        this.driverType = driverType;
    }

    /**
     * Convert a DriverType to the associated shader language
     */
    pure static final ShaderModel convShaderModel(DriverType driver) @nogc @safe nothrow
    {
        switch (driver)
        {
        case DriverType.None:
            return ShaderModel.None;
        case DriverType.OpenGL:
        case DriverType.OpenGLES:
            return ShaderModel.GLSL;
        case DriverType.Metal:
            return ShaderModel.Metal;
        case DriverType.Vulkan:
            return ShaderModel.SPIRV;
        default:
            return ShaderModel.Unsupported;
        }
    }

    /**
     * Return the currently running driver type
     */
    pure @property const DriverType driverType() @nogc @safe nothrow
    {
        return _driverType;
    }

    /**
     * Return the underlying shader model
     */
    pure @property const ShaderModel shaderModel() @nogc @safe nothrow
    {
        return _shaderModel;
    }
}
