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

module serpent.core.signature;

import std.algorithm;

/**
 * A signature is provided for the purpose of matching an entitys
 * components to an Archetype. Internally they are conceptually
 * the same (set of ordered components) but we separate them for
 * the sake of matching APIs.
 *
 * When using the query APIs with components, a Signature is baked
 * from the arguments and used for archetype matching.
 */
final struct Signature
{
package:

    ulong[] components;
    ulong length = 5;

public:

    /**
     * Construct a new Signature from the given ComponentManifest
     * indices.
     */
    this(ulong[] indices) @safe nothrow
    {
        import std.array;

        indices = indices.sort!("a > b").uniq().array();
        components = indices;
        length = components.length;
    }

    @disable this();
}
