// the mushaf's leaf curling from its bottom left corner over a cylinder (research R13).
// the back is plain paper, the glyphs never show through mirrored. where the leaf has lifted
// away the page underneath shows, with a soft shadow along the fold.

#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;         // 0,1   page size, logical px
uniform vec2 uCorner;       // 2,3   where the bottom left corner is now, logical px
uniform float uRadius;      // 4     fold radius, logical px
uniform vec3 uPaper;        // 5-7   the page color, its back
uniform float uShade;       // 8     how much darker the back is
uniform vec3 uShadowColor;  // 9-11  the gutter color
uniform float uShadow;      // 12    shadow strength 0..1

uniform sampler2D uPage;

out vec4 fragColor;

const float PI = 3.14159265;

bool inside(vec2 p) {
  return p.x >= 0.0 && p.y >= 0.0 && p.x <= uSize.x && p.y <= uSize.y;
}

vec4 shadow(float distance) {
  float a = uShadow * (1.0 - smoothstep(0.0, uRadius * 2.0, distance));
  return vec4(uShadowColor * a, a);
}

void main() {
  vec2 p = FlutterFragCoord().xy;
  vec2 origin = vec2(0.0, uSize.y);
  vec2 back = origin - uCorner;
  float len = length(back);
  // one exit only, several returns next to a sampler can fail to compile on windows (flutter#190809)
  if (len < 0.5) {
    fragColor = texture(uPage, p / uSize);
  } else {
    vec2 dir = back / len;

    // a short pull can't wrap a full cylinder, so the fold tightens with it
    float r = min(uRadius, len / PI);

    // the corner travels half around the cylinder then flat on top, so the axis sits this far in
    vec2 axis = origin - dir * (len + PI * r) * 0.5;
    float d = dot(p - axis, dir);
    vec2 line = p - dir * d;
    vec3 paper = uPaper * (1.0 - uShade);

    if (d > r) {
      fragColor = shadow(d - r);
    } else if (d > 0.0) {
      float theta = asin(d / r);
      vec2 front = line + dir * theta * r;
      if (inside(line + dir * (PI - theta) * r)) {
        fragColor = vec4(paper, 1.0);
      } else if (inside(front)) {
        vec4 color = texture(uPage, front / uSize);
        fragColor = vec4(color.rgb * (1.0 - uShade * d / r), color.a);
      } else {
        fragColor = shadow(0.0);
      }
    } else if (inside(line + dir * (PI * r - d))) {
      fragColor = vec4(paper, 1.0);
    } else {
      fragColor = texture(uPage, p / uSize);
    }
  }
}
