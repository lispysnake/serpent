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

module serpent.core.group;

public import serpent.core.context;
public import serpent.core.policy;
public import serpent.core.processor;

import std.parallelism;
import std.stdio;
import std.exception;
import std.string;

/**
 * A Group instance must be created with the appropriate DataPolicy
 * as a templated argument, enforcing compile-time checking of the
 * given data policy.
 *
 * It is the job of a Group to execute and organise similar units
 * of work in the same data policy. i.e. we can parallel-execute
 * read-only jobs, with known join times. This allows a sequential
 * execution of parallel data sets.
 */
final class Group(T : DataPolicy)
{

private:

    string _name = "unnamed group";
    Context _context;

    static if (is(T : ReadOnly))
    {
        bool _parallel = false;
    }

public:

    Processor!T[] processors;

    this(string name)
    {
        enforce(is(T : ReadWrite) || is(T : ReadOnly), "Unknown DataPolicy: %s".format(T.stringof));
        enforce(name !is null, "Group must have a valid name");
        _name = name;
    }

    /**
     * Add a Processor to this group
     */
    final Group!T add(Processor!T processor) @safe
    {
        writefln("(%s) Adding processor: %s", name, processor.classinfo.name);
        enforce(!_context.running, "Cannot add Processor to running Context");
        processor.context = this.context;
        processors ~= processor;
        return this;
    }

    static if (is(T : ReadOnly))
    {

        /**
         * Returns true if parallel execution is both enabled and supported
         */
        @property final const bool parallel() @nogc @safe nothrow
        {
            return _parallel;
        }

        /**
         * Set this ReadOnly group to use parallel execution of all
         * units.
         */
        @property final Group!T parallel(bool b) @nogc @safe nothrow
        {
            _parallel = b;
            return this;
        }
    }
    else
    {

        /**
         * Group!ReadWrite does not support parallel execution therefore
         * this will always return false.
         */
        @property final const bool parallel() @nogc @safe nothrow
        {
            return false;
        }
    }

    /**
     * Return the (display) name for this Group
     */
    pure @property final const string name() @safe @nogc nothrow
    {
        return _name;
    }

    /**
     * Set the (display) name for this Group
     */
    @property final Group!T name(string s) @safe @nogc nothrow
    {
        _name = s;
        return this;
    }

    /**
     * Return the underlying Context for this Group
     */
    pure @property final Context context() @safe @nogc nothrow
    {
        return _context;
    }

package:

    /**
     * Sequentially bootstrap all processors to ensure all systems are
     * correctly loaded upon start of the rendering loop
     */
    final void bootstrap() @system
    {
        auto view = View!T(this.context.entity);

        foreach (ref p; processors)
        {
            p.context = this.context;
            p.bootstrap(view);
        }
    }

    /**
     * Execute our full set of processors
     */
    final void run(TaskPool tp) @system
    {
        auto view = View!T(this.context.entity);

        /* If parallel is set+supported, execute units in parallel */
        if (this.parallel())
        {
            foreach (ref p; tp.parallel(processors))
            {
                p.context = this.context;
                p.run(view);
            }
        }

        /* Otherwise, just execute sequentially. */
        else
        {
            foreach (ref p; processors)
            {
                p.context = this.context;
                p.run(view);
            }
        }
    }

    /**
     * Make all of our processors finish up their work
     */
    final void finish() @system
    {
        auto view = View!T(this.context.entity);

        foreach (ref p; processors)
        {
            p.context = this.context;
            p.finish(view);
        }
    }

    /**
     * Set the context for this Group
     */
    @property final void context(Context c) @safe @nogc nothrow
    {
        _context = c;
    }
}
