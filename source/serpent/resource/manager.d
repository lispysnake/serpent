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

module serpent.resource.manager;

import serpent.core.context;

import std.exception : enforce;
import std.file : exists;
import std.string;
import bindbc.bgfx;

/**
 * The ResourceManager is used for abstracting access to file-based
 * resources in a platform-agnostic way. Largely we rely upon ZIP archives
 * for bundling, with the assumption that the ZIP assets are supplied
 * with the game's executable as an output of the build system for the
 * game.
 */
final class ResourceManager
{

private:
    string _root = null;
    Context _context = null;

public:

    /**
     * Construct a new ResourceManager.
     */
    this(Context ctx, string root = null)
    {
        this.context = ctx;
        this.root = root;
    }

    /**
     * Return the root directory
     */
    pure @property final const string root() @nogc @safe nothrow
    {
        return _root;
    }

    /**
     * Update the root directory
     */
    @property final void root(string s) @safe
    {
        enforce(s !is null, "Root directory cannot be null");
        enforce(s.exists, "Root directory must exist");
        _root = s;
    }

    /**
     * Return the Context associated with this ResourceManager
     */
    pure @property final Context context() @nogc @safe nothrow
    {
        return _context;
    }

    /**
     * Set the context for this ResourceManager
     */
    @property final void context(Context ctx) @safe
    {
        enforce(ctx !is null, "Cannot have a null context");
        _context = ctx;
    }

    /**
     * Super simple path substitution method that allows decorated
     * paths to automatically be *correct*.
     *
     * This is useful for shader paths, etc, so that we don't have
     * to do lots of branching.
     */
    final string substitutePath(string p) @safe
    {
        import std.string : toLower;
        import std.conv : to;

        return p.replace("${shaderModel}", to!string(context.info.shaderModel).toLower());
    }
}
