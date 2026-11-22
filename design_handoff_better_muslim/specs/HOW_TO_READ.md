# How to read the layout trees

Styles are the exact inline CSS from the design file. Read them as Flutter like this:
- `position:absolute; left/top/right/bottom` → Positioned inside a Stack (the phone is the Stack, 393 × 852).
- `display:flex` → Row (or Column when `flex-direction:column`); `gap` → spacing between children; `flex:1` → Expanded.
- `display:grid; grid-template-columns:repeat(N,minmax(0,1fr))` → N equal columns.
- `padding: t r b l`, `margin` → EdgeInsets (logical px). `border-radius` → BorderRadius.
- `box-shadow:0 0 0 1px X` → 1 px border in X. `inset 0 -1px 0 X` → 1 px bottom divider. `0 -1px 0 X` → 1 px top divider.
- `var(--name)` → palette role (see TOKENS.md, e.g. var(--pc) = primaryContainer, var(--onpc) = onPrimaryContainer, var(--ac) = accentContainer, var(--onac) = onAccentContainer, var(--on) = onPrimary, var(--outline2) = outlineStrong).
- `color-mix(in oklab, A N%, transparent)` → A at N% opacity.
- `font-variant-numeric:tabular-nums` → FontFeature.tabularFigures().
- `{{ name }}` → live value from state (see the screen's Dynamic values list). `IF x` → conditional child.
- `data-a=…` marks an animated element; its animation is in MOTION.md.
- ICON <folder>/<name> → assets/icons/<folder>/<name>.svg tinted with the inherited `color`.
