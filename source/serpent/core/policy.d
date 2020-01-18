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

module serpent.core.policy;

/**
 * The DataPolicy base type provides a mechanism whereby we can enforce
 * a compiler-level promise on data sharing. This is required for the
 * context main loop, with its Group implementation.
 */
final struct DataPolicy
{
}

/**
 * A ReadWrite policy permits read *and* write access to the underlying
 * data storage. As such, different parallel-execution strategies must
 * be employed.
 */
final struct ReadWrite
{
    DataPolicy parent;
    alias parent this;
}

/**
 * A ReadOnly policy strictly permits only read-only access to the
 * underlying data, allowing optimisation of parallel-execution within
 * a frame.
 */
final struct ReadOnly
{
    DataPolicy parent;
    alias parent this;
}
