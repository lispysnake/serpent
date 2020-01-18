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

import serpent;
import std.stdio : writeln, writefln;
import std.exception;

enum Faction
{
    EvilDudes = 1,
    GoodDudes = 2,
};

final class EnemyMovementProcessor : Processor!ReadWrite
{

    private bool _inverted = false;

    final @property void inverted(bool b) @safe @nogc nothrow
    {
        _inverted = b;
    }

    pure final @property bool inverted() @safe @nogc nothrow
    {
        return _inverted;
    }

    final override void run() @system
    {
        import std.stdio;

        auto ent = context.display.scene.visibleEntities()[0];
        foreach (i; 0 .. ent.size())
        {
            auto pos = ent.getPosition(i);
            if (inverted) {
                pos.y += 1.5;
            } else {
                pos.y -= 1.5;
            }
            if (pos.y <= 0) {
                pos.y = 0;
            }
            if (pos.y >= 768 - 75) {
                pos.y = 768 - 75;
            }
            ent.setPosition(i, pos);
        }
    }
}

/**
 * Provided merely for demo purposes.
 */
final class DemoGame : App
{

private:
    Player p;
    Enemy e;
    Scene s;

public:
    EnemyMovementProcessor proc;

private:
    final void onMousePressed(MouseEvent e) @system
    {
        writefln("Pressed (%u): %f %f", e.button, e.x, e.y);
        // context.display.debugMode = !context.display.debugMode;
        proc.inverted = !proc.inverted;
    }

    final void onMouseMoved(MouseEvent e) @safe
    {
        writefln("Moved: %f %f", e.x, e.y);
        p.setPosition(0, e.x, e.y);
    }

    final void onKeyReleased(KeyboardEvent e) @safe
    {
        // TODO: Go fullscreen on F
        writefln("Key released");
    }

public:
    final override bool init() @system
    {
        writeln("Game Init");

        context.input.mousePressed.connect(&onMousePressed);
        context.input.mouseMoved.connect(&onMouseMoved);
        context.input.keyReleased.connect(&onKeyReleased);
        proc = new EnemyMovementProcessor();
        context.addGroup(new Group!ReadWrite("logic").add(proc));

        s = new Scene("sample");
        context.display.addScene(s);
        context.display.scene = "sample";
        s.addCamera(new OrthographicCamera());
        s.camera.worldOrigin = WorldOrigin.TopLeft;

        /* Create our first player */
        p = new Player();
        p.add();
        p.setPosition(0, 0.0f, 0.0f);

        /* Create 20 enemies */
        e = new Enemy();
        e.reserve(10);
        auto offset = 10;
        foreach (i; 0 .. 13)
        {
            e.add();
            if (i % 2 == 0)
                e.setFaction(i, Faction.GoodDudes);
            e.setPosition(i, offset, 768);
            offset += 100;
        }

        context.display.scene.addEntity(e);
        context.display.scene.addEntity(p);
        return true;
    }
}

final class Player : Entity
{

private:
    uint[] health;

public:
    /**
     * Add player and health
     */
    final override void add() @safe
    {
        super.add();
        health ~= 100; /** Start with 100hp */
        setPosition(0, vec3f(20, 20));
    }

    /**
     * Set the player health
     */
    final void setHealth(uint hp) @safe
    {
        health[0] = hp;
    }

    /**
     * Fix reservation
     */
    final override void reserve(uint many) @safe nothrow
    {
        super.reserve(many);
        this.health.reserve(many);
    }
} /* Player */

/**
 * Simplistic representation of an Enemy.
 */
final class Enemy : Entity
{

private:

    uint[] health;
    Faction[] faction;

public:

    /**
     * Add enemy
     */
    final override void add() @safe
    {
        super.add();
        health ~= 100;
        this.faction ~= Faction.EvilDudes;
    }

    final void setFaction(ulong index, Faction f) @safe
    {
        enforce(index >= 0 && index < faction.length, "Invalid index");
        faction[index] = f;
    }

    final override void reserve(uint many) @safe nothrow
    {
        super.reserve(many);
        this.health.reserve(many);
        this.faction.reserve(many);
    }
} /* Enemy */

int main()
{
    auto context = new Context();
    context.display.title("#serpent demo").size(1366, 768);
    context.display.pipeline.addRenderer(new SpriteRenderer());
    context.display.backgroundColor = 0x7ec0ee;

    /* Set our root directory up */
    context.resource.root = context.resource.root ~ "/assets/built";

    return context.run(new DemoGame());
}
