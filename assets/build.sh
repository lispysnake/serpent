#!/bin/bash
set -e
set -x

FORMAT=RGBA8
QUALITY=highest
BUILDDIR="World"

function convert_texture()
{
    local filename="$1"
    ../../serpent-support/runtime/bin/texturec -f "raw/${filename}" -o "${BUILDDIR}/${filename%.png}.dds" -m -q $QUALITY -t $FORMAT
}

rm -rf "${BUILDDIR}"
mkdir "${BUILDDIR}"

for i in raw/*.png ; do
    nom=$(basename "${i}")
    convert_texture "${nom}"
done

pushd "${BUILDDIR}"
zip ../Assets.zip *
popd
rm -rf "${BUILDDIR}"

install -d -D -m 00755 built
mv Assets.zip built/.
