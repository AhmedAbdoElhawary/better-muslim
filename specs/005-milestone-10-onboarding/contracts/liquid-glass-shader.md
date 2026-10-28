# Contract: the liquid glass shader

`shaders/liquid_glass.frag`, from `liquid_glass_onboarding/shaders/liquid_glass.frag`, fed by
`features/onboarding/view/widgets/glass/liquid_glass.dart` as a backdrop `ImageFilter.shader`.

## Uniforms

The engine fills the first `vec2` (input size) and the first sampler (the backdrop). Ours start at
float index 2.

| Index | Uniform | Meaning | From the reference |
| --- | --- | --- | --- |
| 0, 1 | uSize | input size, physical px (engine) | same |
| 2, 3 | uScreen | filtered area, logical px | same |
| 4, 5 | uCenter | lens centre, logical px | same |
| 6 | uRadius | lens radius | same |
| 7 | uMagnify | centre magnification | same |
| 8 | uRefraction | rim bend | same |
| 9 | uChroma | colour fringes | same |
| 10 | uGlow | glow arc strength 0 to 1 | same |
| 11 | uOpacity | lens visibility | same |
| 12, 13 | uVelocity | squash and stretch, zero with reduce motion | same |
| 14 | uShadow | drop shadow | same |
| 15 | uSpecular | highlight | same |
| 16 | uRimLight | bright rim | same |
| 17, 18, 19 | uGlowColor | theme `glow`, linear rgb | new, replaces the literal blue, cyan, lavender |
| 20 | uFill | 0 clear glass, 1 filled | new |
| 21, 22, 23 | uFillColor | theme `sun` | new |
| 24 | uClipY | logical y under which the lens isn't drawn, a large value for none | new |

The light end of the arc is `mix(uGlowColor, uFillColor, 0.5)`. No colour is written in the shader.

## When it runs

- Only while the lens shows: dragging, springing, building. At rest the layer is out of the tree.
- `ImageFilter.isShaderFilterSupported` false → `FallbackGlass` (frosted, same size, rim and
  motion), also in widget tests.
- A failed shader load is reported without personal data and falls back too.
