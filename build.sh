#!/bin/bash
set -e
set -x

MODE="debug"

if [[ "$MODE" == "release" ]]; then
    dub build --parallel -c demo -b release --compiler=ldc2  --skip-registry=all
    strip ./serpent
else
    dub build --parallel -c demo -b debug --compiler=ldc2 --skip-registry=all
fi

