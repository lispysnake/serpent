#!/bin/bash
set -e
set -x

FORMAT=RGBA8
QUALITY=highest
BUILDDIR="World"

function convert_texture()
{
    local filename="$1"
    ../../serpent-support/runtime/bin/texturec -f "raw/${filename}" -o "${BUILDDIR}/textures/${filename%.png}.dds" -m -q $QUALITY -t $FORMAT
}

function build_shader()
{
    # TODO: Consider (strongly) dropping shaderc and using google's one.
    local platform="$1"
    local shader_lang="$2"
    local shader_type="$3"
    local filename="$4"
    install -d -D -m 00755 "${BUILDDIR}/shaders/${shader_lang}"
    profile_arg="--profile ${shader_lang}"
    if [[ "${shader_lang}" == "glsl" ]]; then
        profile_arg=""
    fi
    ../../serpent-support/runtime/bin/shaderc -f "shaders/${filename}" -o "${BUILDDIR}/shaders/${shader_lang}/${filename%.sc}.bin" --type "${shader_type}" -i ../../serpent-support/staging/bgfx/src ${profile_arg} --platform "${platform}"
}

rm -rf "${BUILDDIR}"
mkdir "${BUILDDIR}"
mkdir "${BUILDDIR}/textures"
mkdir "${BUILDDIR}/shaders"
mkdir "${BUILDDIR}/maps"

for i in raw/*.png ; do
    nom=$(basename "${i}")
    convert_texture "${nom}"
done

# Install maps
for i in raw/*.{tsx,tmx}; do
    install -m 0644 "${i}" "${BUILDDIR}/maps/."
done

for shader_type in "vertex" "fragment" ; do
    for i in shaders/*${shader_type}.sc ; do
        nom=$(basename "${i}")
        # OpenGL Linux
        build_shader linux glsl $shader_type "${nom}"
        # Vulkan Linux
        build_shader linux spirv $shader_type "${nom}"
    done
done

pushd "${BUILDDIR}"
zip ../Assets.zip -r *
popd
rm -rf "${BUILDDIR}"

install -d -D -m 00755 built
mv Assets.zip built/.
