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
import std.format;
import std.datetime;

/**
 * We apply a PhysicsComponent when there is some position manipulation
 * to be had.
 */
@serpentComponent final struct PhysicsComponent
{
    float velocityX = 0.0f;
    float velocityY = 0.0f;
}

enum SpriteDirection
{
    None = 1 << 0,
    Left = 1 << 1,
    Right = 1 << 2,
};

/**
 * Demo physics - if have velocity, go.
 */
final class BasicPhysics : Processor!ReadWrite
{
    final override void run(View!ReadWrite view)
    {
        /* Find all physics entities */
        foreach (ent, transform, physics; view.withComponents!(TransformComponent,
                PhysicsComponent))
        {
            auto frameTime = context.frameTime();

            transform.position.x += physics.velocityX * frameTime;
            transform.position.y += physics.velocityY * frameTime;
        }
    }
}

/**
 * Absurdly simple Animation helper.
 */
final struct Animation
{
    Texture[] textures;
    ulong textureIndex = 0;
    Duration passed;
    EntityID entity;
    Duration interval;

    this(EntityID entity, Duration interval)
    {
        this.entity = entity;
        this.interval = interval;
    }

    /**
     * Add a texture to our known set
     */
    void addTexture(Texture t)
    {
        textures ~= t;
    }

    /**
     * Update with the given duration
     */
    void update(View!ReadWrite view, Duration dt)
    {
        passed += dt;
        if (passed <= this.interval)
        {
            return;
        }
        passed = dt;
        textureIndex++;
        if (textureIndex >= textures.length)
        {
            textureIndex = 0;
        }
        view.data!SpriteComponent(entity).texture = textures[textureIndex];
    }
}

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
    Animation explosionAnim;
    Animation playerAnim;
    Animation shipAnim;
    Animation bugAnim;
    Texture texture;
    const auto meterSize = 70;

    SpriteDirection playerDirection = SpriteDirection.None;
    SpriteDirection viewDirection = SpriteDirection.Right;
    bool playerSpeedUp = false;

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

    final void createPlayer(View!ReadWrite initView)
    {
        /* Create player */
        player = initView.createEntity();
        initView.addComponent!TransformComponent(player);
        auto rootTexture = new Texture("assets/SciFi/Sprites/tank-unit/PNG/tank-unit.png");
        auto frameSize = rootTexture.width / 4.0f;
        playerAnim = Animation(player, dur!"msecs"(100));
        initView.addComponent!SpriteComponent(player)
            .texture = rootTexture.subtexture(rectanglef(0.0f, 0.0f, frameSize,
                    rootTexture.height));
        initView.data!TransformComponent(player)
            .position.y = texture.height - rootTexture.height - 13.0f;
        initView.addComponent!PhysicsComponent(player).velocityX = 0.0f;

        foreach (i; 0 .. 4)
        {
            auto frame = rootTexture.subtexture(rectanglef(i * frameSize, 0.0f,
                    frameSize, rootTexture.height));
            playerAnim.addTexture(frame);
        }
    }

    final void createShip(View!ReadWrite initView)
    {
        ship = initView.createEntity();
        initView.addComponent!TransformComponent(ship);
        auto rootTexture = new Texture(
                "assets/SciFi/Sprites/spaceship-unit/PNG/ship-unit-with-thrusts.png");
        auto frameSize = rootTexture.width / 8.0f;
        shipAnim = Animation(ship, dur!"msecs"(50));
        initView.addComponent!SpriteComponent(ship)
            .texture = rootTexture.subtexture(rectanglef(0.0f, 0.0f, frameSize,
                    rootTexture.height));
        initView.data!SpriteComponent(ship).flip = FlipMode.Horizontal;
        initView.data!TransformComponent(ship).position.y = 60.0f;
        initView.data!TransformComponent(ship).position.x = 500.0f;
        initView.addComponent!PhysicsComponent(ship).velocityX = (meterSize * -1.2) / 1000.0f;
        initView.data!PhysicsComponent(ship).velocityY = (meterSize * -0.1) / 1000.0f;
        foreach (i; 0 .. 8)
        {
            auto frame = rootTexture.subtexture(rectanglef(i * frameSize, 0.0f,
                    frameSize, rootTexture.height));
            shipAnim.addTexture(frame);
        }
    }

    final void createExplosion(View!ReadWrite initView)
    {
        /* Create the explosion */
        explosion = initView.createEntity();
        initView.addComponent!TransformComponent(explosion);
        initView.addComponent!SpriteComponent(explosion);
        explosionAnim = Animation(explosion, dur!"msecs"(80));
        foreach (i; 0 .. 10)
        {
            explosionAnim.addTexture(new Texture(
                    "assets/SciFi/Sprites/Explosion/sprites/explosion-animation%d.png".format(i + 1)));
        }
        initView.data!SpriteComponent(explosion).texture = explosionAnim.textures[0];
        initView.data!TransformComponent(explosion).position.x = 40.0f;
        initView.data!TransformComponent(explosion).position.y = texture.height - 93.0f;
        initView.data!TransformComponent(explosion).position.z = 0.9f;
    }

    final void createBug(View!ReadWrite initView)
    {
        auto bug = initView.createEntity();
        initView.addComponent!TransformComponent(bug);
        initView.addComponent!SpriteComponent(bug);
        bugAnim = Animation(bug, dur!"msecs"(50));
        foreach (i; 0 .. 8)
        {
            bugAnim.addTexture(new Texture(
                    "assets/SciFi/Sprites/alien-flying-enemy/sprites/alien-enemy-flying%d.png".format(
                    i + 1)));
        }
        initView.data!SpriteComponent(bug).flip = FlipMode.Horizontal;
        initView.addComponent!PhysicsComponent(bug).velocityX = (meterSize * 1.5) / 1000.0f;
        initView.data!SpriteComponent(bug).texture = bugAnim.textures[0];
    }

    final void createBackground(View!ReadWrite initView)
    {
        texture = new Texture("assets/SciFi/Environments/bulkhead-walls/PNG/bg-wall.png");
        auto floortexture = new Texture("assets/SciFi/Environments/bulkhead-walls/PNG/floor.png");
        auto altTexture = new Texture(
                "assets/SciFi/Environments/bulkhead-walls/PNG/bg-wall-with-supports.png");

        float x = 0;
        int idx = 0;
        while (x < context.display.logicalWidth + 300)
        {
            background ~= initView.createEntity();
            initView.addComponent!TransformComponent(background[idx]);
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

        int columns = 480 / cast(int) floortexture.width + 5;
        foreach (i; 0 .. columns)
        {
            auto floor = initView.createEntity();
            initView.addComponent!TransformComponent(floor);
            initView.addComponent!SpriteComponent(floor).texture = floortexture;
            initView.data!TransformComponent(floor).position.x = i * floortexture.width;
            initView.data!TransformComponent(floor)
                .position.y = texture.height - floortexture.height;
        }

    }

    /**
     * Update the player sprite + velocity. TODO: Let's not actually
     * write this change on every frame unless its really needed.
     */
    final void updatePlayer(View!ReadWrite view)
    {
        playerAnim.update(view, context.deltaTime());

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

        auto boundsX = (component.position.x + playerAnim.textures[playerAnim.textureIndex].width
                / 2) - (context.display.logicalWidth() / 2);
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
        context.systemGroup.add(new BasicPhysics());

        context.entity.begin();

        createBackground(initView);
        createPlayer(initView);
        createExplosion(initView);
        createShip(initView);
        createBug(initView);

        return true;
    }

    final override void update(View!ReadWrite view)
    {
        explosionAnim.update(view, context.deltaTime());
        shipAnim.update(view, context.deltaTime());
        bugAnim.update(view, context.deltaTime());
        updatePlayer(view);
        updateCamera(view);

        /*
        auto playerPos = view.data!TransformComponent(player);
        auto explosionPos = view.data!TransformComponent(explosion);
        explosionPos.position = playerPos.position;
        explosionPos.position.z = 0.9f;
        explosionPos.position.y -= 30.0f;*/
    }
}
