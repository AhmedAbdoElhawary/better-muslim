# 06: Firebase in the app

**What to build:** Firebase starts in every flavor with collection off, without slowing the first frame.

**Blocked by:** 03

**Status:** after launch, 1.0.0 ships without Firebase Analytics (specs/029)

- [ ] `firebase_core` and `firebase_analytics` are added, and iOS builds with them.
- [ ] Config files stay out of git, CI writes them for every job that builds.
- [ ] Collection is off by default in the manifest and Info.plist.
- [ ] The advertising id is off on both platforms.
- [ ] A launch with the phone asleep is still fine.
