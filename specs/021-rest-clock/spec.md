# Feature Specification: Rest clock

**Feature Branch**: `feature/quran-reading`

**Created**: 2026-11-10

**Status**: Built, waiting for my review (grilled once, Q1 to Q8, all recommendations, Boundary in
`GLOSSARY.md`)

**Input**: the app drew a frame every second on every screen, even with nothing on it changing:

```text
there is something keeps playing in the background, i see that from the frames that keeps
moving wherever i am in the app.
don't keep it running, don't count down second by second, set a timer before anything that
depends on time.
```

Found on the phone: the second ticker stayed alive off Home because the notifications wiring
listens to the period and the azkar progress, both followed it. Each tick made Riverpod flush,
and a flush needs a frame.

## Decisions

### Boundaries

- One timer in core waits for the next Boundary: a prayer time, the end of its now window,
  sunrise, maghrib, local midnight. It covers yesterday, today and tomorrow, so last night's isha
  window past midnight counts too.
- The period, the prayer day, the next, now and highlighted prayer, the Prayer tab rows, the
  azkar window and badge, Follow sky and the arc follow it, never the second ticker. The day
  (today) comes from it too, its own midnight timer is gone.
- On every Resume it is worked out again from the real clock, a timer doesn't run while the
  phone sleeps. Changing the phone's clock by hand stays unsupported.
- The alerts (adhan, Reminder, Azkar nudge, Live countdown) are scheduled on the phone and never
  used the ticker, nothing changes there.

### Tickers

- The second ticker runs only while a countdown with seconds is on screen: Home's card and bar,
  the theme page's preview. Off screen it stops its timer, back on screen it ticks at once.
- The sun or stars on the arc, the prayer bar and the Prayer tab's "in h:mm" chip follow a minute
  ticker on the wall clock's minute, with the same stop and start.
- A fast day still works: boundaries come 288 times sooner, both tickers tick 10 a second so the
  sun glides.

### Guards

- Quran, Azkar and More draw no frame over 2 minutes at rest, Prayer only on the minute for its
  "in h:mm" chip.
- Home at rest draws only on the second.
- Only the countdown watches the second ticker (`architecture_test`).
- Constitution III says it, 5.3.0.
