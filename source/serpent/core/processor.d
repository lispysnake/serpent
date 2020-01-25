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

module serpent.core.processor;

public import serpent.core.context;
public import serpent.core.policy;
public import serpent.core.view;

/**
 * The virtual base class for any Processor (System) within the Serpent
 * core framework loop.
 *
 * Any implementation of Processor must explicitly extend with their
 * data-policy defined at compile time, i.e. ReadWrite or ReadOnly.
 *
 * A Processor can only be added to a group with the same data policy,
 * to allow optimisation of parallel execution strategies. Thus you
 * cannot add a ReadWrite Processor to a ReadOnly Group.
 *
 * With these (deliberate) limitations in mind, you should ensure
 * your group setup is chained to take advantage of this in terms
 * of data batching.
 */
abstract class Processor(T : DataPolicy)
{

private:
    Context _context;

public:
    abstract void bootstrap(View!T entityView) @system;
    abstract void run(View!T entityView) @system;
    abstract void finish(View!T entityView) @system;

package:

    final void context(Context c) @safe @nogc nothrow
    {
        _context = c;
    }

public:
    /**
     * Return the underlying context for this processor
     */
    pure final Context context() @safe @nogc nothrow
    {
        return _context;
    }
}
