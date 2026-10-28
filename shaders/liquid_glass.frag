// the sun as a liquid glass lens, a backdrop ImageFilter (impeller only).
// from liquid_glass_onboarding, with the theme's glow and sun colors instead of literals,
// a fill toward the sun's color and a clip under the horizon (contracts/liquid-glass-shader.md).
//
// ImageFilter.shader needs the first uniform to be a vec2 (the engine fills the input size)
// and the first sampler2D (the engine binds the backdrop), so ours start at float index 2.

#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;        // 0,1   (engine) input texture size, physical px
uniform vec2 uScreen;      // 2,3   filtered area size, logical px
uniform vec2 uCenter;      // 4,5   lens center, logical px
uniform float uRadius;     // 6     lens radius, logical px
uniform float uMagnify;    // 7     center magnification (1 = none)
uniform float uRefraction; // 8     how hard the rim bends light
uniform float uChroma;     // 9     colour fringes at the rim
uniform float uGlow;       // 10    glow arc strength 0..1
uniform float uOpacity;    // 11    lens visibility 0..1
uniform vec2 uVelocity;    // 12,13 lens velocity, logical px/s (squash and stretch)
uniform float uShadow;     // 14    drop shadow 0..1
uniform float uSpecular;   // 15    highlight 0..1
uniform float uRimLight;   // 16    bright rim 0..1
uniform vec3 uGlowColor;   // 17-19 the theme's glow
uniform float uFill;       // 20    0 clear glass, 1 filled with the sun's color
uniform vec3 uFillColor;   // 21-23 the theme's sun
uniform float uClipY;      // 24    nothing of the lens below this logical y

uniform sampler2D uTexture;

out vec4 fragColor;

// the backdrop at a logical position. no gles y flip, the backdrop already comes the right way up
// there and the flip the ImageFilter.shader docs ask for turned the screen upside down
vec4 sampleScreen(vec2 logical) {
  vec2 uv = clamp(logical / uScreen, vec2(0.0), vec2(1.0));
  return texture(uTexture, uv);
}

void main() {
  vec2 p = FlutterFragCoord().xy / uSize * uScreen;
  vec4 base = sampleScreen(p);

  float R = uRadius;
  vec2 d = p - uCenter;
  float reach = R * 1.25 + 24.0;
  if (uOpacity <= 0.001 || R < 0.5 || dot(d, d) > reach * reach || p.y > uClipY) {
    fragColor = base;
    return;
  }

  // squash and stretch along the motion, the liquid feel
  float speed = length(uVelocity);
  if (speed > 1.0) {
    vec2 v = uVelocity / speed;
    float a = clamp(speed / 6000.0, 0.0, 0.14);
    float along = dot(d, v);
    vec2 perp = d - along * v;
    d = v * (along / (1.0 + a)) + perp / (1.0 - 0.5 * a);
  }
  float r = length(d);

  // soft drop shadow under the lens
  vec2 ds = p - uCenter - vec2(0.0, 3.0 + R * 0.06);
  float sh = 1.0 - smoothstep(R * 0.80, R * 1.10 + 14.0, length(ds));
  vec3 outside = base.rgb * (1.0 - 0.11 * sh * uShadow * uOpacity);

  float mask = 1.0 - smoothstep(R - 0.9, R + 0.6, r);
  if (mask <= 0.0) {
    fragColor = vec4(outside, base.a);
    return;
  }

  // the lens as a dome: magnified middle, the rim bends and flips what is behind it
  float nr = clamp(r / R, 0.0, 1.0);
  float z = sqrt(max(1.0 - nr * nr, 0.0));
  float edge = 1.0 - z;
  float bend = pow(edge, 1.5) * uRefraction;
  float s = 1.0 / max(uMagnify, 0.01) - bend * 1.8;

  // r, g and b refract a little differently
  float ca = uChroma * edge;
  vec3 col;
  col.r = sampleScreen(uCenter + d * s * (1.0 + ca)).r;
  col.g = sampleScreen(uCenter + d * s).g;
  col.b = sampleScreen(uCenter + d * s * (1.0 - ca)).b;

  // milky body, highlight, bright top rim, darker bottom rim
  vec3 n = normalize(vec3(d / R, max(z, 0.05)));
  vec3 L = normalize(vec3(-0.35, -0.8, 0.5));
  vec3 H = normalize(L + vec3(0.0, 0.0, 1.0));
  float spec = pow(max(dot(n, H), 0.0), 48.0);
  float rim = smoothstep(0.88, 1.0, nr);
  float up = clamp(-d.y / R, -1.0, 1.0);

  col = mix(col, vec3(1.0), 0.035);
  col = mix(col, uFillColor, clamp(uFill, 0.0, 1.0));
  col += vec3(spec * 0.28 * uSpecular);
  col += vec3(rim * (0.10 + 0.30 * smoothstep(-0.2, 0.9, up)) * uRimLight);
  col *= 1.0 - 0.07 * rim * smoothstep(0.0, 0.9, -up);

  // the glow arc on the inner bottom rim while the sun is lifted
  if (uGlow > 0.001) {
    float down = clamp(d.y / R, -1.0, 1.0);
    float bottom = smoothstep(-0.2, 0.8, down);
    float band = smoothstep(0.52, 0.70, nr) * (1.0 - smoothstep(0.80, 0.96, nr));
    float side = abs(d.x) / R;
    vec3 light = mix(uGlowColor, uFillColor, 0.5);
    vec3 g = mix(uGlowColor, light, smoothstep(0.25, 0.8, side));
    float a = clamp(band * bottom * uGlow * 1.15, 0.0, 0.95);
    col = mix(col, g, a);
    float halo = smoothstep(0.82, 0.93, nr) * (1.0 - smoothstep(0.95, 1.0, nr));
    col = mix(col, light, halo * bottom * uGlow * 0.4);
  }

  fragColor = vec4(mix(outside, clamp(col, 0.0, 1.0), mask * uOpacity), base.a);
}
