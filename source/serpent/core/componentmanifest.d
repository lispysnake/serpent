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

module serpent.core.componentmanifest;

import serpent.core.entity;
import serpent.core.greedyarray;
import serpent.core.storage;

alias storeAllocatorFunc = void* delegate() @trusted nothrow;
alias storeDeallocatorFunc = void delegate(void* chunk, bool killData) @trusted;
alias storeInsertFunc = void* delegate(void* chunk, out ulong idx) @trusted nothrow;
alias storeCloneFunc = void delegate(void* sourceChunk, ulong sourceIndex,
        void* targetChunk, ulong targetIndex) @trusted nothrow;
alias storeRemoveFunc = void delegate(void* chunk, ulong idx, bool killData) @trusted;

/**
 * 
 * A component manifest exists for every registered component in the
 * EntityManager. Along with providing membership capabilities, it
 * stores private component-specific factory functions.
 */
final struct ComponentManifest
{

private:
    GreedyBitArray entities;
    bool _alive = false; /*<Whether we're 'alive' (active) in the game world */
    void* _pool = null;
    ulong _members = 0;
    ulong _index = 0;
    ulong _maxElements = 0;
    string _name;

package:

    /* These are lambds and pointers that work around various issues
     * when it comes to generically handling templates in non templated
     * code. Cuz yknow, generics.
     */

    /**
     * Allocate a single chunk from the Component Pool
     */
    storeAllocatorFunc allocateChunk;

    /**
     * Deallocate a single chunk for reuse within the Component Pool
     */
    storeDeallocatorFunc deallocateChunk;

    /**
     * Insert a row into the Component Pool chunk
     */
    storeInsertFunc insertRow;

    /**
     * Clone one Component Pool chunk into another
     */
    storeCloneFunc cloneRow;

    /**
     * Remove one Component Pool chunk row
     */
    storeRemoveFunc removeRow;

    /**
     * Stuff the pool allocator in
     */
    pragma(inline, true) final @property void pool(C)(PoolAllocator!C* pool) @trusted @nogc nothrow
    {
        _pool = cast(void*) pool;
    }

    /**
     * Set maxElements per the chunk allocator
     */
    pragma(inline, true) final @property void maxElements(ulong n) @safe @nogc nothrow
    {
        _maxElements = n;
    }

    /**
     * Return maximum elements per the chunk allocator
     */
    pragma(inline, true) pure final @property const ulong maxElements() @safe @nogc nothrow
    {
        return _maxElements;
    }

    /**
     * Return the pool cast to the appropriate type
     */
    pragma(inline, true) pure final @property PoolAllocator!C* pool(C)() @trusted @nogc nothrow
    {
        return cast(PoolAllocator!C*) _pool;
    }

    /**
     * Construct a new ComponentManifest for the given sizes
     */
    this(ulong index, string name, ulong minSize, ulong maxSize) @safe nothrow
    {
        entities = GreedyBitArray(minSize, maxSize);
        this._index = index;
        this._name = name;
    }

    /**
     * Entity is joining this component
     */
    final void join(EntityID id) @safe nothrow
    {
        entities[id] = true;
        ++_members;
    }

    /**
     * Entity is unjoining this component
     */
    final void unjoin(EntityID id) @safe nothrow
    {
        entities[id] = false;
        --_members;
    }

    /**
     * Return true if entity is a member of this component
     */
    pure final bool joined(EntityID id) @safe nothrow
    {
        if (id >= entities.count)
        {
            return false;
        }
        return entities[id];
    }

    final ulong members() @safe @nogc nothrow
    {
        return _members;
    }

    /**
     * Clear all membership
     */
    final void clear() @safe
    {
        _members = 0;
        entities.reset();
    }

    /**
     * Set the alive status
     */
    final @property void alive(bool b) @safe @nogc nothrow
    {
        _alive = b;
    }

    /**
     * Returns whether this component is alive
     */
    pure final @property bool alive() @safe @nogc nothrow
    {
        return _alive;
    }

    /**
     * Return index of the manifest within the hosting array
     */
    pure final @property ulong index() @safe @nogc nothrow
    {
        return _index;
    }

    /**
     * Return the name of this ComponentManifest
     */
    pure final @property string name() @safe @nogc nothrow
    {
        return _name;
    }
}
