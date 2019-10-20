#!/bin/bash

# Autoformat the code.
dub run --verror autoformat --  `find . -name '*.d'`

# Check we have no typos.
which misspell 2>/dev/null >/dev/null
if [[ $? -eq 0 ]]; then
    misspell -error `find source -name '*.d'`
fi
