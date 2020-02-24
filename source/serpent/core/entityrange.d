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

module serpent.core.entityrange;

import serpent.core.archetype : Archetype;
import serpent.core.page : Page;

/**
 * Construct a read-write range for the given page + archetype.
 * It will ALWAYS include the entity ID as the first element.
 */
auto entityRangeRW(C...)(Archetype* archetype, Page* page) @safe nothrow
{
    import serpent.core.component : EntityIdentifier;
    import serpent.core.entityrangerw : EntityRangeRW;

    return EntityRangeRW!(EntityIdentifier, C)(archetype, page);
}

/**
 * Construct a read-only range for the given page + archetype.
 * It will ALWAYS include the entity ID as the first element.
 */
auto entityRangeRO(C...)(Archetype* archetype, Page* page) @safe nothrow
{
    import serpent.core.component : EntityIdentifier;
    import serpent.core.entityrangero : EntityRangeRO;

    return EntityRangeRO!(EntityIdentifier, C)(archetype, page);
}
