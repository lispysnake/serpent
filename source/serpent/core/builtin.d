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

module serpent.core.builtin;

import serpent.core.policy;
import serpent.core.processor;
import serpent.core.view;
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
    final override void run(View!ReadWrite dataView) @system
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
    final override void run(View!ReadWrite dataView) @system
    {
        context.app.update();
    }
}

/**
 * The PrerenderProcessor will begin the frame.
 */
final class PreRenderProcessor : Processor!ReadOnly
{

package:
    this()
    {
    }

public:
    /**
     * Call prerender on the target display
     */
    final override void run(View!ReadOnly dataView) @system
    {
        context.display.prerender();
    }
}

/**
 * The PrerenderProcessor will begin the frame.
 */
final class PostRenderProcessor : Processor!ReadOnly
{

package:
    this()
    {
    }

public:
    /**
     * Call postrender on the target display
     */
    final override void run(View!ReadOnly dataView) @system
    {
        context.display.postrender();
    }
}
