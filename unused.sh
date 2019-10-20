#!/bin/bash
#
# Ignore this script. It's here for reference purposes while the framework
# is being built. At some point we're going to need to start loading textures
# and render them to quads.
set -e
set -x

FORMAT=RGBA8
QUALITY=highest

# Mass convert assets to DDS files using RGBA8 (uncompressed)
# Future consideration: Switch to compressed assets for performance gain,
# then nuke compression on the .zip archive.
for i in *.png ; do
    ../serpent-support/runtime/bin/texturec -f "${i}" -o "${i%.png}.dds" -m -q $QUALITY -t $FORMAT
done

# Build a ZIP from the assets to load at runtime
rm -rf Knight/
mkdir Knight
mv *.dds Knight/.
zip Knight.zip -r Knight/
rm -rf Knight/
