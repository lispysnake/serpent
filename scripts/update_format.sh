#!/bin/bash

# Autoformat the code.
dub run --verror autoformat --skip-registry=all --  `find source -name '*.d'`

# Check we have no typos.
which misspell 2>/dev/null >/dev/null
if [[ $? -eq 0 ]]; then
    misspell -error `find source -name '*.d'`
fi

# Nuke .orig files from modification
find . -name '*.d.orig' | xargs -I{} rm {}
