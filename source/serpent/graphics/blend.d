/*
 * This file is part of serpent.
 *
 * Copyright © 2019 Lispy Snake, Ltd.
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

module serpent.graphics.blend;

import std.stdint;

import bindbc.bgfx;

/**
 * Blend helpers, simplistic port of temp.defines.h in bgfx
 * Original credit and copyright to bgfx authors
 */

static uint64_t StateBlendFuncSeparate(uint64_t srcRGB, uint64_t dstRGB,
        uint64_t srcA, uint64_t dstA)
{
    return 0UL | ((srcRGB | (dstRGB << 4)) | ((srcA | (dstA << 4) << 8)));
}

static uint64_t StateBlendEquationSeparate(uint64_t a, uint64_t b)
{
    return 0UL | a | (b << 3);
}

static uint64_t StateBlendFunc(uint64_t src, uint64_t dst)
{
    return StateBlendFuncSeparate(src, dst, src, dst);
}

static uint64_t StateBlendEquation(uint64_t e)
{
    return StateBlendEquationSeparate(e, e);
}

/**
 * BlendState provides a common set of predefined blend behaviours
 * for the bgfx graphics pipeline.
 */
enum BlendState
{
    Add = 0UL | StateBlendFunc(BGFX_STATE_BLEND_ONE, BGFX_STATE_BLEND_ONE),
    Alpha = 0UL | StateBlendFunc(BGFX_STATE_BLEND_SRC_ALPHA,
            BGFX_STATE_BLEND_INV_SRC_ALPHA),
    Darken = 0UL | StateBlendFunc(BGFX_STATE_BLEND_ONE,
            BGFX_STATE_BLEND_ONE) | StateBlendEquation(BGFX_STATE_BLEND_EQUATION_MIN),
    Lighten = 0UL | StateBlendFunc(BGFX_STATE_BLEND_ONE,
            StateBlendEquation(BGFX_STATE_BLEND_EQUATION_MAX)),
    Multiply = 0UL | StateBlendFunc(BGFX_STATE_BLEND_DST_COLOR,
            BGFX_STATE_BLEND_ZERO),
    Normal = 0UL | StateBlendFunc(
            BGFX_STATE_BLEND_ONE, BGFX_STATE_BLEND_INV_SRC_ALPHA),
    Screen = 0UL | StateBlendFunc(
            BGFX_STATE_BLEND_ONE, BGFX_STATE_BLEND_INV_SRC_COLOR),
    LinearBurn = 0UL | StateBlendFunc(
            BGFX_STATE_BLEND_DST_COLOR, BGFX_STATE_BLEND_INV_DST_COLOR),
}
