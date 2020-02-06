module serpent.graphics.frame;

public import serpent.core.entity : EntityID;
public import serpent.core.ringbuffer;

import serpent.graphics.renderer;

final struct FramePacketVisible
{
    EntityID id;
    Renderer renderer;
};

/**
 * We have a pre-allocated framepacket which will store all drawing information
 * for the upcoming render.
 *
 * This is extracted once the last simulation has been run.
 */
final struct FramePacket
{

private:
    __gshared bool running = false;
    __gshared RingBuffer!FramePacketVisible _visibleEntities;
    ulong entityLimit = 0;

public:

    /**
     * Construct a new FramePacket with a preconfigured upper limit.
     * Right now the 2D centric framepacket is incredibly simple, but
     * we may flesh it out in future.
     */
    this(ulong entityLimit) @trusted nothrow
    {
        _visibleEntities = RingBuffer!FramePacketVisible(entityLimit);
        this.entityLimit = entityLimit;
    }

    /**
     * Push a visible entity into the framepacket for rendering
     * We do this in our first round to compute *what* needs to
     * go on screen.
     */
    pragma(inline, true) final void pushVisibleEntity(EntityID entityID, Renderer renderer) @trusted @nogc nothrow
    {
        _visibleEntities.add(FramePacketVisible(entityID, renderer));
    }

    /**
     * We're starting a new tick.
     */
    pragma(inline, true) final void startTick() @trusted @nogc nothrow
    {
        _visibleEntities.reset();
    }

    /**
     * Return the visible entity list (entityID handles)
     */
    pragma(inline, true) final auto visibleEntities() @trusted @nogc nothrow
    {
        return _visibleEntities.data;
    }
}
