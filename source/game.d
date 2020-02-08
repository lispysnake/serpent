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
import serpent.tiled;

/**
 * Provided merely for demo purposes.
 */
final class DemoGame : App
{

private:
    Scene s;
    Entity[] background;

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
        context.input.keyReleased.connect(&onKeyReleased);

        /* Create our first scene */
        s = new Scene("sample");
        context.display.addScene(s);
        s.addCamera(new OrthographicCamera());

        auto texture = new Texture("assets/SciFi/Environments/bulkhead-walls/PNG/bg-wall.png");
        auto floortexture = new Texture("assets/SciFi/Environments/bulkhead-walls/PNG/floor.png");
        auto altTexture = new Texture(
                "assets/SciFi/Environments/bulkhead-walls/PNG/bg-wall-with-supports.png");

        float x = 0;
        int idx = 0;
        while (x < context.display.logicalWidth)
        {
            background ~= initView.createEntity();
            auto component = initView.addComponent!SpriteComponent(background[idx]);
            if (idx % 2 == 0)
            {
                component.texture = altTexture;
            }
            else
            {
                component.texture = texture;
            }
            auto transform = initView.data!TransformComponent(background[idx]);
            transform.position.x = x;
            transform.position.z = -0.1f;
            x += component.texture.width;
            idx++;
        }

        int columns = 480 / cast(int) floortexture.width + 1;
        foreach (i; 0 .. columns)
        {
            auto floor = initView.createEntity();
            initView.addComponent!SpriteComponent(floor).texture = floortexture;
            initView.data!TransformComponent(floor).position.x = i * floortexture.width;
            initView.data!TransformComponent(floor)
                .position.y = texture.height - floortexture.height;
        }

        auto sprite = initView.createEntity();
        initView.addComponent!SpriteComponent(sprite).texture = new Texture(
                "assets/SciFi/Sprites/bipedal-Unit/PNG/sprites/bipedal-unit1.png");
        initView.data!TransformComponent(sprite).position.x = 30.0f;
        initView.data!TransformComponent(sprite).position.y = texture.height - 70.0f;
        initView.data!TransformComponent(sprite).position.z = 0.1f;

        return true;
    }
}
