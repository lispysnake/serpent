#!/bin/bash
set -e
set -x

MODE="debug"

if [[ ! -z "$1" ]]; then
    MODE="$1"
fi

if [[ "$MODE" == "release" ]]; then
    dub build --parallel -c demo -b release --compiler=ldc2  --skip-registry=all
    strip ./serpent
elif [[ "$MODE" == "debug" ]]; then
    dub build --parallel -c demo -b debug --compiler=ldc2 --skip-registry=all
else
    echo "Unknown build mode"
    exit 1
fi

