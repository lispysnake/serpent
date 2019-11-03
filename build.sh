#!/bin/bash
set -e
set -x
dub build --parallel -c demo -b release --compiler=ldc2  --skip-registry=all
strip ./serpent

