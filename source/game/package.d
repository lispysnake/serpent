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

module game;

import serpent;
import std.stdio : writeln, writefln;
import std.exception;
import bindbc.sdl;
import serpent.tiled;
import std.format;
import std.datetime;

import game.animation;
import game.physics;

import game.bug;
import game.explosion;
import game.player;
import game.ship;

enum SpriteDirection
{
    None = 1 << 0,
    Left = 1 << 1,
    Right = 1 << 2,
};

/**
 * Provided merely for demo purposes.
 */
final class DemoGame : App
{

private:
    Scene s;
    EntityID[] background;
    EntityID player;
    EntityID ship;
    EntityID explosion;
    SpriteAnimation explosionAnim;
    SpriteAnimation playerAnim;
    SpriteAnimation shipAnim;
    SpriteAnimation bugAnim;
    Texture texture;

    SpriteDirection playerDirection = SpriteDirection.None;
    SpriteDirection viewDirection = SpriteDirection.Right;
    bool playerSpeedUp = false;
    bool destroyed = false;

    /**
     * A keyboard key was just released
     */
    final void onKeyReleased(KeyboardEvent e) @system
    {
        switch (e.scancode())
        {
        case SDL_SCANCODE_F:
            context.display.fullscreen = !context.display.fullscreen;
            break;
        case SDL_SCANCODE_Q:
            writeln("Quitting time.");
            context.quit();
            break;
        case SDL_SCANCODE_D:
            context.display.pipeline.debugMode = !context.display.pipeline.debugMode;
            break;
        case SDL_SCANCODE_RIGHT:
            playerDirection = SpriteDirection.None;
            viewDirection = SpriteDirection.Right;
            break;
        case SDL_SCANCODE_LEFT:
            playerDirection = SpriteDirection.None;
            viewDirection = SpriteDirection.Left;
            break;
        case SDL_SCANCODE_C: /* clear */
            destroyed = true;
            context.entity.clear();
            context.entity.build();
            break;
        case SDL_SCANCODE_LCTRL:
            playerSpeedUp = false;
            break;
        default:
            writeln("Key released");
            break;
        }
    }

    final void onKeyPressed(KeyboardEvent e) @system
    {
        switch (e.scancode())
        {
        case SDL_SCANCODE_RIGHT:
            playerDirection = SpriteDirection.Right;
            viewDirection = SpriteDirection.Right;
            break;
        case SDL_SCANCODE_LEFT:
            playerDirection = SpriteDirection.Left;
            viewDirection = SpriteDirection.Left;
            break;
        case SDL_SCANCODE_LCTRL:
            playerSpeedUp = true;
            break;
        default:
            break;
        }
    }

    final void createBackground(View!ReadWrite initView)
    {
        texture = new Texture("assets/SciFi/Environments/bulkhead-walls/PNG/bg-wall.png");
        auto floortexture = new Texture("assets/SciFi/Environments/bulkhead-walls/PNG/floor.png");
        auto altTexture = new Texture(
                "assets/SciFi/Environments/bulkhead-walls/PNG/bg-wall-with-supports.png");

        float x = 0.0f;
        int idx = 0;
        while (x < context.display.logicalWidth + 300)
        {
            background ~= initView.createEntity();
            auto sprite = SpriteComponent();
            if (idx % 2 == 0)
            {
                sprite.texture = altTexture;
            }
            else
            {
                sprite.texture = texture;
            }
            auto transform = TransformComponent();
            transform.position.x = x;
            transform.position.z = -0.1f;
            initView.addComponentDeferred(background[idx], transform);
            initView.addComponentDeferred(background[idx], sprite);
            x += sprite.texture.width;
            idx++;
        }

        int columns = 480 / cast(int) floortexture.width + 5;
        foreach (i; 0 .. columns)
        {
            auto floor = initView.createEntity();
            auto sprite = SpriteComponent();
            auto transform = TransformComponent();

            sprite.texture = floortexture;
            transform.position.x = i * floortexture.width;
            transform.position.y = texture.height - floortexture.height;

            initView.addComponentDeferred(floor, sprite);
            initView.addComponentDeferred(floor, transform);
        }

    }

    /**
     * Update the player sprite + velocity. TODO: Let's not actually
     * write this change on every frame unless its really needed.
     */
    final void updatePlayer(View!ReadWrite view)
    {
        auto velocityX = (meterSize * 0.9) / 1000.0f;
        if (playerSpeedUp)
        {
            velocityX *= 2.5f;
        }
        if (viewDirection == SpriteDirection.Left)
        {
            view.data!SpriteComponent(player).flip = FlipMode.Horizontal;
        }
        else
        {
            view.data!SpriteComponent(player).flip = FlipMode.None;
            view.data!PhysicsComponent(player).velocityX = velocityX;
        }

        switch (playerDirection)
        {
        case SpriteDirection.Left:
            view.data!PhysicsComponent(player).velocityX = -velocityX;
            break;
        case SpriteDirection.Right:
            view.data!PhysicsComponent(player).velocityX = velocityX;
            break;
        default:
            view.data!PhysicsComponent(player).velocityX = 0.0f;
        }
    }

    /**
     * Update the camera to center on the player
     */
    final void updateCamera(View!ReadWrite view)
    {
        import gfm.math;

        auto component = view.data!TransformComponent(player);

        auto boundsX = (component.position.x + playerAnim.textures[0].width / 2) - (
                context.display.logicalWidth() / 2);
        auto boundsY = 0.0f;
        s.camera.position = vec3f(boundsX, 0.0f, 0.0f);
        auto bounds = rectanglef(0.0f, 0.0f, 480.0f + 200.0f, 176.0f);
        auto viewport = rectanglef(0.0f, 0.0f, 480.0f, 176.0f);
        s.camera.clamp(bounds, viewport);
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
        context.input.keyPressed.connect(&onKeyPressed);

        /* Create our first scene */
        s = new Scene("sample");
        context.display.addScene(s);
        s.addCamera(new OrthographicCamera());

        context.entity.registerComponent!PhysicsComponent;
        context.entity.registerComponent!SpriteAnimationComponent;
        context.systemGroup.add(new BasicPhysics());
        context.systemGroup.add(new SpriteAnimationProcessor());

        createBackground(initView);

        playerAnim = createPlayerAnimation();
        player = createPlayer(initView, &playerAnim);

        explosionAnim = createExplosionAnimation();
        explosion = createExplosion(initView, &explosionAnim);
        shipAnim = createShipAnimation();
        ship = createShip(initView, &shipAnim);
        bugAnim = createBugAnimation();

        return true;
    }

    final override void update(View!ReadWrite view)
    {
        if (destroyed)
        {
            return;
        }
        updatePlayer(view);
        updateCamera(view);
    }
}
