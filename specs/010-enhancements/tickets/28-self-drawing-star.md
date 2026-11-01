# 28: Self-drawing star

**What to build:** The self-drawing star from Brand's second motif, Noor, replaces the oil drop
everywhere something loads. With a known progress it draws up to the percentage. With reduce
motion the whole star breathes.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] One star loader in core: a 0.5 pt line, a 3.6 s draw with ease-in-out, the four strokes
      starting at 0, 400, 900 and 1400 ms, an 800 ms rest, a 400 ms fade, then again.
- [x] Given a progress, the line is drawn up to it.
- [x] With reduce motion the full star breathes.
- [x] It replaces the oil drop in the loader gate, the tafsir chip, the study tabs, the mini
      player, the recording sheet and the dev page. The oil drop is deleted.
- [x] The timings are named entries in the motion tokens and the colors come from the theme.
- [x] Its repaints stay inside it.
- [x] `loader_gate_test` covers progress and reduce motion, and replaces `oil_drop_test`.
