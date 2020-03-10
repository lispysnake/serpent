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

module shaderMain;

import std.file;
import std.process;
import std.path;
import std.stdio;

void compileShader(string outputPath, string shaderPath, string varyingPath,
        string shaderLang, bool vertex)
{
    string platform;

    auto rootDir = environment.get("DUB_ROOT_PACKAGE_DIR");
    if (rootDir == "")
    {
        rootDir = environment.get("DUB_PACKAGE_DIR");
    }

    string shaderc = rootDir.buildPath("..", "serpent-support", "runtime", "bin", "shaderc");
    string includedir = rootDir.buildPath("..", "serpent-support", "external", "bgfx", "src");

    string outputFileName = outputPath.buildPath(shaderLang);
    if (vertex)
    {
        outputFileName ~= ".vertex";
    }
    else
    {
        outputFileName ~= ".fragment";
    }

    /* TODO: Support other platforms.  */
    version (linux)
    {
        platform = "linux";
    }
    else version (Windows)
    {
        platform = "windows";
    }
    else
    {
        static assert(0, "Unsupported Platform");
    }

    string[] args = [
        shaderc, "-f", shaderPath, "--type", vertex ? "vertex" : "fragment", "-i",
        includedir, "--platform", platform, "-o", outputFileName, "--varyingdef",
        varyingPath,
    ];
    /* Needed? */
    if (platform != "linux" && shaderLang == "glsl")
    {
        args ~= ["--profile", "glsl"];
    }
    else if (shaderLang != "glsl")
    {
        args ~= ["--profile", shaderLang];
    }

    writefln("  * compiling %s", outputFileName);

    auto cmd = execute(args);
    if (cmd.status != 0)
    {
        writeln(cmd.output);
    }
}

void main()
{
    import std.stdio;

    writeln("*** Preparing Serpent core shaders ***\n");

    auto dir = environment.get("DUB_PACKAGE_DIR");
    auto shaderDir = dir.buildPath("assets/shaders");
    auto buildDir = dir.buildPath("built/shaders");

    buildDir.mkdirRecurse();

    foreach (item; dirEntries(shaderDir, SpanMode.shallow, false))
    {
        if (!item.isDir)
        {
            continue;
        }
        auto basenom = baseName(item);

        writefln(" > %s", basenom);
        auto fragment = shaderDir.buildPath(basenom, "fragment.sc");
        auto vertex = shaderDir.buildPath(basenom, "vertex.sc");
        auto varying = shaderDir.buildPath(basenom, "varying.def.sc");

        assert(fragment.exists, "Missing fragment shader");
        assert(vertex.exists, "Missing vertex shader");
        assert(varying.exists, "Missing varying.def.sc");

        auto outputPath = buildDir.buildPath(basenom);
        outputPath.mkdirRecurse();

        compileShader(outputPath, fragment, varying, "glsl", false);
        compileShader(outputPath, vertex, varying, "glsl", true);
        compileShader(outputPath, fragment, varying, "spirv", false);
        compileShader(outputPath, vertex, varying, "spirv", true);
        writeln();
    }
}
