# Serpent Game Framework

A game framework from [Lispy Snake, Ltd.](https://lispysnake.com).
This is not *exactly* an engine.

### UNDER DEVELOPMENT

This is very much a work in progress and will continue to
change daily. As such the document provides a rough roadmap and
vision overview. Note this is a restart of efforts after our
lispysnake2d repo (also public)

## Support Development

This framework is being developed by Lispy Snake for our first games.
While we would love to develop it full time, basic economics says we
must reinvest any contract-work revenue to support development in
any remaining time.

To accelerate development (and time-to-market) for our framework
and first game, consider buying a [Lifetime License](https://lispysnake.com/the-game-raiser) from
us ($20!) to have lifetime access to our games.

## Building

We build serpent with the `ldc2` (LLVM-based) D compiler. To test the
included demo, build the `demo` subcomponent in release mode.

    dub build --parallel -c demo -b release --compiler=ldc2

Note you will need to have `serpent-support` built in a directory
parallel to this checkout. This is a bit janky but we're focusing
more on code right now than the runtime support project. Building
it will enable components such as bgfx.

## Modifications

Please note any modifications must be hygienic - compiling with neither
warning nor error. Additionally you must have run `update_format.sh` to
ensure consistent code-styling before sending in changes.

## Design Considerations

Provide the best possible functionality required for simpler 2D games
at minimal technical debt, both for us, the framework developers, and
you, the library consumer.

Our previous engine implementation was an all-inclusive engine written
in C with a WIP rendering pipeline. Long story short, way too much
debt for us and for new users.

### D Language

Whilst some may argue the merits of D, we've found it perfectly suited
to our game development requirements. Consider the built-in concurrency
support when dealing with batches of SOA entities.

Additionally, we wanted to avoid a few pitfalls (despite being C lovers)

 - String issues (`\0`, mutability, UTF..)
 - Forced to reinvent all the wheels (to avoid linking to beastly opinionated refcount libraries)
 - Time to market. It hurts.

### Cross-platform support

We need to support, at minimum:

 - Windows (Vulkan/OpenGL)
 - Linux (Vulkan/OpenGL) & X11/Wayland
 - Android.

### Utilities

The framework simply wraps a bunch of libraries together, and provides utilities
to manage the game loop and do *stuff*. Thus, we'll provide utilities for
lifecycle management and actually loading/drawing stuff.

### 2D Focus

We want to disguise the pipeline under a 2D front. This framework is currently
designed for 2D games, that benefit from an accelerated 3D pipeline.
To that end, we'll make it possible to make awesome 2D games with UIs,
sound, tiling, etc. But you can still get slick bloom shaders..

### Reuse Where Possible

Where it is feasible we will reuse other projects to save us from
significant technical debt, such as rendering pipelines, etc.

Below is the current list of projects we know we WILL reuse. This may
be subject to modification.

#### bgfx

We will reuse bgfx / bimg / bx projects for our rendering pipeline.
This will allow us to support all relevant graphical subsystems.
The project also has a super modern architecture which allows us
to just expose it to consumers so they can basically do anything
they want.

#### SDL

We'll use SDL for our basic windowing, OS integration and input
handling. This allows consumers to leverage the advanced controller
support found within SDL (some would say a USP).

#### Newton (??)

The downfall of many a framework is to needlessly reinvent physics.
We plan to integrate a proven solution. Currently we're checking
some numbers and will revisit physics integration in the near future.

#### OpenAL

Need decent sound, right?

### Invent Where Unavoidable

Some areas we're going to be forced to do a small bit of reinvention.
This will involve basic UI support in the framework, primarily because
the main available libraries are explicitly locked to OpenGL. We very
much need to support OpenGL **and** Vulkan.
