# 15: Skip a schedule that didn't change

**What to build:** `apply` does nothing when the alerts are the ones it scheduled last time, minus
the ones that already went off. flutter_local_notifications rewrites its whole saved list for each
alert, and on Flutter 3.47 that runs on the thread that draws, so every resume was a hitch.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] The last applied alerts are kept in memory only, a cold open always applies.
- [x] A new, changed or removed future alert applies again, `cancelAll` forgets the last one.
- [x] The MediaQuery reads stay on `context`, a provider would cost the same and break the
  padding and text scale Flutter changes inside sheets and the share card.
