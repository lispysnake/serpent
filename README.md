# Serpent Game Framework

[![License](https://img.shields.io/badge/License-ZLib-blue.svg)](https://opensource.org/licenses/ZLib)

The Serpent Game Framework is a brand new game framework from [Lispy Snake, Ltd](https://lispysnake.com) leveraging
the latest technologies such as D, OpenGL and Vulkan, to make indie game
development easier than ever.

![demo](https://github.com/lispysnake/serpent/raw/master/.github/screenshot.png)

## Support It

This framework is being developed by Lispy Snake for our first games.
While we would love to develop it full time, basic economics says we
must reinvest any contract-work revenue to support development in
any remaining time.

To accelerate development (and time-to-market) for our framework
and first game, consider buying a [Lifetime License](https://lispysnake.com/the-game-raiser) from
us ($20!) to have lifetime access to our games. If you just want to send a tip
to help with Serpent development (and our other efforts) then please click one
of the links below!

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=VYHL9CEFSNCVA) [![Donate with Bitcoin](https://en.cryptobadges.io/badge/small/168AkAQszA7mZSv2epzYoPq4qnefiyhAKG)](https://en.cryptobadges.io/donate/168AkAQszA7mZSv2epzYoPq4qnefiyhAKG)

## Modifications

Please note any modifications must be hygienic - compiling with neither
warning nor error. Additionally you must have run `scripts/update_format.sh` to
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

We will reuse bgfx to power the underlying rendering pipeline in
order to abstract support for various platforms and rendering APIs.

Currently we're focused on Vulkan and OpenGL, with Metal and DirectX
on the cards in the future.

#### SDL

We'll use SDL for our basic windowing, OS integration and input
handling. This allows consumers to leverage the advanced controller
support found within SDL (some would say a USP).

#### Chipmunk2D

After investigating several options, we're probably going to use Chipmunk2D
for 2D physics, and find another 3D option should the need arise. We looked
into Newton Dynamics and its too problematic for integration.

#### OpenAL

Need decent sound, right?

### Invent Where Unavoidable

Some areas we're going to be forced to do a small bit of reinvention.
This will involve basic UI support in the framework, primarily because
the main available libraries are explicitly locked to OpenGL. We very
much need to support OpenGL **and** Vulkan.
