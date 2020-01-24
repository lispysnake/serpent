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

    final void onMousePressed(MouseEvent e) @system
    {
        writefln("Pressed (%u): %f %f", e.button, e.x, e.y);
    }

    final void onMouseMoved(MouseEvent e) @safe
    {
        writefln("Moved: %f %f", e.x, e.y);
    }

    final void onKeyReleased(KeyboardEvent e) @system
    {
        // TODO: Go fullscreen on F
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
    final override bool init(View!ReadWrite initView) @system
    {
        writeln("Game Init");

        context.input.mousePressed.connect(&onMousePressed);
        context.input.mouseMoved.connect(&onMouseMoved);
        context.input.keyReleased.connect(&onKeyReleased);

        s = new Scene("sample");
        context.display.addScene(s);
        context.display.scene = "sample";
        s.addCamera(new OrthographicCamera());
        s.camera.worldOrigin = WorldOrigin.TopLeft;

        context.component.registerComponent!SpriteComponent;
        context.component.registerComponent!TilemapComponent;

        /* Construct initial entity */
        auto entity = initView.createEntity();
        initView.addComponent!SpriteComponent(entity);

        initView.data!SpriteComponent(entity).texture = "ship.png";

        writefln("Texture is %s", initView.data!SpriteComponent(entity).texture);

        foreach (ent; initView.withComponent!SpriteComponent)
        {
            writefln("Got an entity: %d", ent.id);
        }
        return true;
    }
}

@serpentComponent final struct SpriteComponent
{
    string texture;
}

@serpentComponent final struct TilemapComponent
{
}

int main()
{
    auto context = new Context();
    context.display.title("#serpent demo").size(1366, 768);

    /* Set our root directory up */
    context.resource.root = context.resource.root ~ "/assets/built";

    return context.run(new DemoGame());
}
