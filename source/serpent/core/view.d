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

module serpent.core.view;

public import serpent.core.policy;

import serpent.core.component;
import serpent.core.entity;

/**
 * The view helps correctly control access to entities and components
 * to ensure the data policy is respected at the compiler level. This
 * effectively means a read-only view cannot modify any component membership
 * or data, or destroy/create entities.
 *
 * TODO: Make this actually useful.
 */
final struct View(T : DataPolicy)
{

private:
    ComponentManager _component;
    EntityManager _entity;

package:
    this(EntityManager ent, ComponentManager comp)
    {
        this._entity = ent;
        this._component = comp;
    }

public:

    @disable this();

    static if (is(T : ReadOnly))
    {

        /* READ-ONLY APIs */

        /**
         * Return data for the given entity ID
         */
        final const C* data(C)(EntityID id)
        {
            return _component.dataRO!C(id);
        }

        /**
         * Return data for the given entity ID
         */
        final const C* data(C)(Entity ent)
        {
            return _component.dataRO!C(ent.id);
        }

    }
    else
    {

        /* READ-WRITE APIs */
        final Entity createEntity()
        {
            return _entity.create();
        }

        /**
         * Return data for the given entity ID
         */
        final C* data(C)(EntityID id)
        {
            return _component.dataRW!C(id);
        }

        /**
         * Return data for the given entity
         */
        final C* data(C)(Entity ent)
        {
            return _component.dataRW!C(ent.id);
        }

        /**
         * Add a component to the given entity ID
         */
        final C* addComponent(C)(EntityID id)
        {
            _component.addComponent!C(id);
            return _component.dataRW!C(ent.id);
        }

        /**
         * Add a component to the given entity
         */
        final C* addComponent(C)(Entity ent)
        {
            _component.addComponent!C(ent.id);
            return _component.dataRW!C(ent.id);
        }

        /**
         * Remove a component from the given entity ID
         */
        final void removeComponent(C)(EntityID id)
        {
            _component.removeComponent!C(id);
        }

        /**
         * Remove a component from the given entity
         */
        final void removeComponent(C)(Entity ent)
        {
            _component.removeComponent!C(ent.id);
        }

        /**
         * Return an EntityRange helper that allows one to foreach
         * over the underlying entity data.
         */
        final auto withComponent(C)()
        {
            return _component.withComponent!C();
        }
    }
}
