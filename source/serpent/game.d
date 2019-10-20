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

module serpent.game;

import serpent.display;

/**
 * The Game interface is used to control lifecycle and entry points,
 * to make life that bit easier for the end developer. This avoids
 * ugly C-style func hooks.
 */
abstract class Game
{

private:
    Display _display = null;

public:
    /**
     * Get the display associated with this Game
     */
    @property final Display display() @safe @nogc nothrow
    {
        return _display;
    }

    /**
     * Set the display associated with this Game
     */
    @property final void display(Display d) @safe @nogc nothrow
    {
        _display = display;
    }

    /**
     * Implementations should attempt to init themselves at this
     * point as the Window is up and running. Once this method
     * has returned safely, the window will be shown for the first
     * time.
     */
    abstract bool init();
}
