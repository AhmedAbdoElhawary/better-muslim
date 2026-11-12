# 01: Profile config and baseline

**What to build:** A `Dev · profile` launch config, and frame numbers from the phone before any fix.

**Blocked by:** None (can start immediately)

**Status:** waiting for a run on the phone

- [x] `Dev · profile` is in `.vscode/launch.json`.
- [ ] Idle, push, pop, tab switch, scroll, page turn, a settings change and a resume are written in
  `baseline.md`.
- [ ] A sheet opening, dragged down and closing over Home, and the Study sheet over the page, with
  their blur. A solid fallback on Android only if a frame goes over 16.6 ms.
