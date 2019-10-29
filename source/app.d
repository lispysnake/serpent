/*
 * This file is part of serpent.
 *
 * Copyright © 2019 Lispy Snake, Ltd.
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
import serpent.pipeline;
import std.stdio : writeln;
import std.exception;

enum Faction
{
    EvilDudes = 1,
    GoodDudes = 2,
};

/**
 * Provided merely for demo purposes.
 */
final class DemoGame : Game
{

private:
    Player p;
    Enemy e;

public:
    final override bool init() @system
    {
        writeln("Game Init");
        display.title = "Running: Serpent Demo";

        /* Create our first player */
        p = new Player();
        p.reserve(1);
        p.add();

        /* Create 20 enemies */
        e = new Enemy();
        e.reserve(20);
        foreach (i; 0 .. 20)
        {
            e.add();
            if (i % 2 == 0)
                e.setFaction(i, Faction.GoodDudes);
        }
        return true;
    }
}

final class Player : Entity2D
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
        setPosition(0, _vecType(20, 20));
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
final class Enemy : Entity2D
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
    return new Display(1366, 768).title("Serpent Demo").pipeline(new Pipeline2D)
        .game(new DemoGame).run();
}
