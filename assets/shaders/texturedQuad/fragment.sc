$input v_texcoord0, v_color0

#include <bgfx_shader.sh>

SAMPLER2D(s_texColor, 0);

void main()
{
    vec4 tcolor = texture2D(s_texColor, v_texcoord0);
    gl_FragColor = v_color0 * tcolor;
}
