# 02: Adhan stream and sound

**What to build:** One state stream for the app, so the progress moves and `ended` arrives. The sound is reproduced on the phone and its real cause fixed.

**Blocked by:** None (can start immediately)

**Status:** waiting for a run on the phone

- [x] `AdhanChannel.state` is one shared stream.
- [x] A test shows a late listener does not take the events from the page.
- [ ] The adhan plays on the phone with the ringer on normal.
