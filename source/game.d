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

/**
 * Demo physics - if have velocity, go.
 */
final class BasicPhysics : Processor!ReadWrite
{
    final override void run(View!ReadWrite view)
    {
        /* Find all physics entities */
        foreach (ent; view.withComponent!PhysicsComponent())
        {
            auto transform = view.data!TransformComponent(ent);
            auto physics = view.data!PhysicsComponent(ent);

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
    Entity entity;
    Duration interval;

    this(Entity entity, Duration interval)
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
    Entity[] background;
    Entity player;
    Entity ship;
    Entity explosion;
    Animation explosionAnim;
    Animation playerAnim;
    Animation shipAnim;
    Texture texture;

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
        default:
            writeln("Key released");
            break;
        }
    }

    final void createPlayer(View!ReadWrite initView)
    {
        auto meterSize = 70; /* 70 pixels is our one meter */

        /* Create player */
        player = initView.createEntity();
        auto rootTexture = new Texture("assets/SciFi/Sprites/tank-unit/PNG/tank-unit.png");
        auto frameSize = rootTexture.width / 4.0f;
        playerAnim = Animation(player, dur!"msecs"(100));
        initView.addComponent!SpriteComponent(player)
            .texture = rootTexture.subtexture(rectanglef(0.0f, 0.0f, frameSize,
                    rootTexture.height));
        initView.data!TransformComponent(player)
            .position.y = texture.height - rootTexture.height - 13.0f;
        initView.addComponent!PhysicsComponent(player).velocityX = (meterSize * 0.9) / 1000.0f;

        foreach (i; 0 .. 4)
        {
            auto frame = rootTexture.subtexture(rectanglef(i * frameSize, 0.0f,
                    frameSize, rootTexture.height));
            playerAnim.addTexture(frame);
        }
    }

    final void createShip(View!ReadWrite initView)
    {
        auto meterSize = 70;

        ship = initView.createEntity();
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
            initView.addComponent!SpriteComponent(floor).texture = floortexture;
            initView.data!TransformComponent(floor).position.x = i * floortexture.width;
            initView.data!TransformComponent(floor)
                .position.y = texture.height - floortexture.height;
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

        context.component.registerComponent!PhysicsComponent;
        context.systemGroup.add(new BasicPhysics());

        createBackground(initView);
        createPlayer(initView);
        createExplosion(initView);
        createShip(initView);

        return true;
    }

    final override void update(View!ReadWrite view)
    {
        explosionAnim.update(view, context.deltaTime());
        playerAnim.update(view, context.deltaTime());
        shipAnim.update(view, context.deltaTime());
        updateCamera(view);

        auto playerPos = view.data!TransformComponent(player);
        auto explosionPos = view.data!TransformComponent(explosion);

        explosionPos.position = playerPos.position;
        explosionPos.position.z = 0.9f;
        explosionPos.position.y -= 30.0f;
    }

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
}
