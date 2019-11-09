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

module serpent.core.builtin;

import serpent.core.policy;
import serpent.core.processor;
import bindbc.sdl;

/**
 * The InputProcessor is owned exclusively by the Context and runs within
 * the System group.
 *
 * It is responsible for polling events, and dispatching them to the
 * correct recipients.
 */
final class InputProcessor : Processor!ReadWrite
{

package:
    this()
    {
    }

public:
    /**
     * Start consuming events, send them where they need to go.
     */
    final override void run() @system
    {
        SDL_Event event;

        while (SDL_PollEvent(&event))
        {

            /* If InputManager consumes the event, don't process it here. */
            if (context.input.process(&event))
            {
                continue;
            }

            /* Likewise, see if the display consumes it */
            if (context.display.process(&event))
            {
                continue;
            }

            switch (event.type)
            {
            case SDL_QUIT:
                context.quit();
                break;
            default:
                break;
            }
        }
    }
}

/**
 * The AppUpdater Processor will call the Context's current app's
 * `update` method during the main loop iteration.
 */
final class AppUpdateProcessor : Processor!ReadWrite
{

package:
    this()
    {
    }

public:
    /**
     * Call update on the App instance midloop
     */
    final override void run() @system
    {
        context.app.update();
    }
}

/**
 * The RenderProcessor is responsible for getting the display
 * to actually render.
 *
 * Right now it lives on the main thread - but in future this
 * will just kick off a frame render for bgfx.
 */
final class RenderProcessor : Processor!ReadWrite
{

package:
    this()
    {
    }

public:
    /**
     * Call render on the target display
     */
    final override void run() @system
    {
        context.display.render();
    }
}
