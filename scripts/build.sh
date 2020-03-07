#!/bin/bash
set -e
set -x

MODE="debug"
# COMPILER="dmd"
COMPILER="ldc2"

if [[ ! -z "$1" ]]; then
    MODE="$1"
fi

function buildProject()
{
    dub build --parallel -c demo -b "${MODE}" --compiler="${COMPILER}" --skip-registry=all -v
}

if [[ "$MODE" == "release" ]]; then
    COMPILER="ldc2"
    buildProject
    strip ./serpent
elif [[ "$MODE" == "optimized" ]]; then
    MODE="release"
    buildProject
elif [[ "$MODE" == "debug" ]]; then
    buildProject
else
    echo "Unknown build mode"
    exit 1
fi

