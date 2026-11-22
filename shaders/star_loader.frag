// the self-drawing star (Brand's Noor) in the design's 100 x 100 box. each pixel gets its exact
// coverage like the svg, a path's edges only get the msaa steps and look dotted at this size.

#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;    // 0,1   canvas size, logical px
uniform vec4 uColor;   // 2-5   line color, straight alpha
uniform float uLine;   // 6     line width, box units
uniform float uPixel;  // 7     one device pixel, box units
uniform float uScale;  // 8     the breathing scale
uniform vec4 uShare;   // 9-12  how much of each stroke is drawn, in drawing order
uniform float uDot;    // 13    1 shows the center dot

out vec4 fragColor;

const float PI = 3.14159265;

float segment(vec2 p, vec2 a, vec2 b) {
  vec2 ab = b - a;
  float t = clamp(dot(p - a, ab) / dot(ab, ab), 0.0, 1.0);
  return length(p - a - ab * t);
}

// clockwise from 3 o'clock like the svg circle, the open end is round
float circle(vec2 q, float r, float share) {
  float t = mod(atan(q.y, q.x), 2.0 * PI) / (2.0 * PI);
  if (t <= share) return abs(length(q) - r);
  float end = 2.0 * PI * share;
  return min(length(q - vec2(r, 0.0)), length(q - r * vec2(cos(end), sin(end))));
}

vec2 vertex(int k, float tip, float valley, float turn) {
  float angle = -PI / 2.0 + turn + float(k) * PI / 8.0;
  float r = mod(float(k), 2.0) < 0.5 ? tip : valley;
  return r * vec2(cos(angle), sin(angle));
}

// two squares as one 8-point outline: 16 equal edges clockwise from the top tip
float star(vec2 q, float tip, float valley, float turn, float share) {
  float drawn = share * 16.0;
  float d = 1e4;
  for (int k = 0; k < 16; k++) {
    float f = clamp(drawn - float(k), 0.0, 1.0);
    if (f <= 0.0) break;
    vec2 a = vertex(k, tip, valley, turn);
    vec2 b = vertex(k + 1, tip, valley, turn);
    d = min(d, segment(q, a, mix(a, b, f)));
  }
  return d;
}

void main() {
  vec2 q = (FlutterFragCoord().xy * 100.0 / uSize.x - vec2(50.0)) / uScale;
  float d = 1e4;
  if (uShare.x > 0.0) d = min(d, circle(q, 46.0, uShare.x));
  if (uShare.y > 0.0) d = min(d, star(q, 42.0, 32.146, 0.0, uShare.y));
  if (uShare.z > 0.0) d = min(d, star(q, 30.0, 22.961, PI / 8.0, uShare.z));
  if (uShare.w > 0.0) d = min(d, circle(q, 15.0, uShare.w));
  float a = clamp((uLine * 0.5 - d * uScale) / uPixel + 0.5, 0.0, 1.0);
  a = max(a, uDot * clamp((2.0 - length(q)) * uScale / uPixel + 0.5, 0.0, 1.0));
  a *= uColor.a;
  fragColor = vec4(uColor.rgb * a, a);
}
