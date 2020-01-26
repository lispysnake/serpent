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
import bindbc.sdl;

/**
 * Provided merely for demo purposes.
 */
final class DemoGame : App
{

private:
    Scene s;

    /**
     * A mouse button was just pressed
     */
    final void onMousePressed(MouseEvent e) @system
    {
        writefln("Pressed (%u): %f %f", e.button, e.x, e.y);
    }

    /**
     * The mouse was just moved
     */
    final void onMouseMoved(MouseEvent e) @safe
    {
        writefln("Moved: %f %f", e.x, e.y);
    }

    /**
     * A keyboard key was just released
     */
    final void onKeyReleased(KeyboardEvent e) @system
    {
        switch (e.scancode())
        {
        case SDL_SCANCODE_F:
            writeln("Fullscreen??");
            context.display.fullscreen = !context.display.fullscreen;
            break;
        case SDL_SCANCODE_Q:
            writeln("Quitting time.");
            context.quit();
            break;
        case SDL_SCANCODE_D:
            writeln("Flip debug.");
            context.display.debugMode = !context.display.debugMode;
            break;
        default:
            writeln("Key released");
            break;
        }
    }

public:

    /**
     * All initial game setup should be done from bootstrap.
     */
    final override bool bootstrap(View!ReadWrite initView) @system
    {
        writeln("Game Init");

        /* We need input working. */
        context.input.mousePressed.connect(&onMousePressed);
        context.input.mouseMoved.connect(&onMouseMoved);
        context.input.keyReleased.connect(&onKeyReleased);

        /* Create our first scene */
        s = new Scene("sample");
        context.display.addScene(s);
        s.addCamera(new OrthographicCamera());

        /* Construct initial entity */
        auto tex = new Texture("assets/raw/logo.png");
        auto entity_logo = initView.createEntity();
        initView.addComponent!SpriteComponent(entity_logo).texture = tex;

        /* Set the logo location */
        initView.data!TransformComponent(entity_logo)
            .position = vec3f(1366.0f - tex.width - 10.0f, 768.0f - tex.height - 10.0f, 0.0f);

        /* Now stick a large picture on screen */
        auto entity_map = initView.createEntity();
        initView.addComponent!SpriteComponent(entity_map);
        initView.data!SpriteComponent(entity_map).texture = new Texture("assets/raw/Overworld.png");

        return true;
    }
}
