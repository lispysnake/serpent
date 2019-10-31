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

module serpent.graphics.shader;

import bindbc.bgfx;
import std.stdio;
import std.file;
import std.string : toStringz;

/**
 * The Shader struct is a quick and dirty wrapper around bgfx's
 * shader APIs.
 */
final class Shader
{

private:
    string _filename = null;
    bgfx_shader_handle_t _handle = cast(bgfx_shader_handle_t) 0;

public:

    @disable this();

    /**
     * Construct a new Shader from the given filename.
     */
    this(string filename)
    {
        _filename = filename;
        auto shader_data = cast(string) read(filename);
        immutable char* data = toStringz(shader_data);

        auto memory = bgfx_copy(cast(const void*) data, cast(uint) shader_data.length + 1);
        _handle = bgfx_create_shader(memory);
        bgfx_set_shader_name(_handle, cast(const char*) toStringz(_filename),
                cast(uint) filename.length + 1);
    }

    /**
     * Return the underlying shader handle
     */
    pure @property final bgfx_shader_handle_t handle() @nogc @safe nothrow
    {
        return _handle;
    }

    pure @property final string filename() @nogc @safe nothrow
    {
        return _filename;
    }
}

/**
 * A Program combines two shaders so that they can be used by bgfx
 * for rendering in some meaningful way.
 */
final class Program
{

private:
    bgfx_program_handle_t _handle = cast(bgfx_program_handle_t) 0;

public:
    @disable this();

    /**
     * Construct a new program from the given shaders
     */
    this(Shader vertex, Shader fragment)
    {
        _handle = bgfx_create_program(vertex.handle, fragment.handle, true);
    }

    ~this()
    {
        bgfx_destroy_program(_handle);
    }

    /**
     * Return the underlying program handle.
     */
    pure @property final bgfx_program_handle_t handle() @nogc @safe nothrow
    {
        return _handle;
    }
}
