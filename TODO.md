So, long story short, we have 2 repos (prior effort and current) and many, many private
branches of this project. Add to that, we have 2 months where we ourselves weren't fully
online with the rest of the world due to various issues, health, etc.

So, let's get this document in order now to organise this months work to get Serpent into
basic demo shape.

 - [x] Bring back basic keyboard handling (F, etc.)
    - Expose underlying SDL_Event for now but in future expand to be more useful.
 - [x] Bring back fullscreen switching/support
    - [x] Port from `lispysnake2d` demo
    - [ ] Fix busted bgfx integration, ensure scaling ratio + track window changes (Note: Only broken on Vulkan)
 - [ ] Add non-crap file loading capabilities. i.e. asynchronous.
 - [x] Time to mature the ECS design to something ... not immature.
 - [x] Allow loading/setting the textures per-sprite-data (instead of everything being Ship.png..)
 - [ ] Restore camera support! `CameraProcessor`, `Transform`, `TransformComponent`, `CameraTransformComponent`
       Camera system processes all entities with a `TransformComponent`, and builds `CameraTransformComponent`
       for each entity, for things like `SpriteRenderer` to use. Only visible entities will have this
       component so it's an implicit performance optimisation too.
 - [x] Let's kill the stupid plane demo and focus on recreating the `lispysnake2d` demo.
 - [x] Bring back parsers for Tiled, but let's just focus on ~~JSON now, not XML (future-maybe?)~~
   **Edit**: XML is more complete and can be sanity-checked, as well as offering space savings
   via Base64/ZLib decoding. JSON is an export, not a primary format. Fully support TMX/TSX.
 - [x] Implement a TSX parser
 - [ ] Bring back parsers for Tilesheet sprites, to get a player on screen
 - [x] Implement tilemap renderer with commonality to sprite renderer.
 - [ ] Reintroduce animation framework through the Context Job system (perhaps stage -> static class?)
 - [ ] Retain stateful approaches to per-level/stage concepts.
 - [ ] Stop relying on PNG assets + debugmode. Compile these assets and implement ResourceManager ZIPs
 - [x] Fix crash on exit (unlink order of shader programs)

Secondary Thoughts...:

 - Go to multithreaded mode of bgfx with separate thread for rendering/main.
 - Have a wide-function sequential pipeline:
    - Run simulation step (physics, etc.)
    - Gather visibles in parallel, push to next stage
    - Gather necessary data for rendering, push to next stage
    - Order into 2 renderable queues, opaque (front to back) and transparent (back to front)
    - Submit all renderables (opaque first, transparent last)
    - Run various post-processing effects through framebuffers
    - Submit final view.
 - Remember, it will take much longer to query and extract information than it will be to merge
   into a single-threaded queue. Distributing across cores will ensure constant framerates.
 - We'll have to decouple rendering from our Processor systems in the Context and instead
   allow registering into the pipeline. Also provide default pipelines.

Nice to have:

 - Chunked data processors. Right now we can run our units in parallel or series, and ensure
   there is a correct execution order for the system. However, we have chains that run in parallel
   that would need internal parallelisation. Thus, having some example chunked processors that can
   split the input data among a group of jobs is essential.


Things to remember:

 - Plane focus is dumb as it's a simple rotational dynamic X/Y positional sprite.
 - Our real game is more reliant on tiling, as well as psuedo-infinite spaces.
 - Inside is far more important than the outside, as it's technically more difficult.
 - We need detailed tilemaps for ship/station interiors, with per-tile animations, etc.
   This is much more easily realisable (word?) with the original not-ocarina demo.
