module serpent.core.ringbuffer;

import std.container.array;
import core.sync.mutex;

/**
 * Our ringbuffer implementation is very simple and crude, it provides a way
 * for us to mass-insert items into the buffer with one set of threads in
 * a write operation.
 *
 * Later we may access the data either sequentially or in parallel but with
 * a guarantee of being read-only, so there are no race conditions for us to
 * consider.
 */
final struct RingBuffer(T)
{

private:
    __gshared Array!T _buffer; /* Classic non-TLS */
    ulong _bufferIndex = 0;
    ulong _bufferLimit = 0;
    shared Mutex mtx;

public:

    /**
     * Construct a new MPQueue with the given upper limit
     */
    this(ulong bufferLimit) @trusted nothrow
    {
        _bufferLimit = bufferLimit;
        _buffer.reserve(_bufferLimit);
        _buffer.length = _bufferLimit;
        mtx = new shared Mutex();
    }

    /**
     * Reset the buffer for the current frame
     */
    final void reset() @safe @nogc nothrow
    {
        mtx.lock_nothrow();
        _bufferIndex = 0;
        mtx.unlock_nothrow();
    }

    /**
     * Add a single item to the queue
     */
    final void add(T item) @trusted @nogc nothrow
    {
        mtx.lock_nothrow();
        if (_bufferIndex >= _bufferLimit)
        {
            _bufferIndex = 0;
        }
        _buffer[_bufferIndex] = item;
        ++_bufferIndex;
        mtx.unlock_nothrow();
    }

    final const @property auto data() @trusted @nogc nothrow
    {
        return _buffer[0 .. _bufferIndex];
    }
}
