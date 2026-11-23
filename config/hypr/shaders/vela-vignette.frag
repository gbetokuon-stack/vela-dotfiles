// Vela 2.0 "Nocturne Prism" — full-screen finishing shader
// Subtle vignette + micro-grain to match the frosted-glass blur noise.
// GLSL ES 3.00 interface from Hyprland's example/screenShader.frag.

#version 300 es

precision mediump float;

in vec2 v_texcoord;
layout(location = 0) out vec4 fragColor;
uniform sampler2D tex;

void main() {
    vec4 pixColor = texture(tex, v_texcoord);

    // Soft vignette: centre unchanged, edges darkened ~7%.
    float d = length(v_texcoord - vec2(0.5, 0.5));
    float vig = 1.0 - smoothstep(0.28, 0.80, d);
    pixColor.rgb *= mix(0.93, 1.0, vig);

    // Very light film grain (pairs with decoration.blur.noise = 0.012).
    float grain = fract(sin(dot(v_texcoord, vec2(12.9898, 78.233))) * 43758.5453);
    pixColor.rgb += (grain - 0.5) * 0.006;

    fragColor = pixColor;
}
