# 12: iOS lane

**What to build:** A production tag also builds through Shorebird for iOS and lands in TestFlight.

**Blocked by:** 11, and the Apple items in `RELEASE_TODO.md`

**Status:** open, the Apple account is mine

- [ ] Both iOS targets have a `PrivacyInfo.xcprivacy`.
- [ ] `deploy.yml` builds iOS on production tags only, signed with an API key, no `--obfuscate`.
- [ ] `patch.yml` can patch iOS too.
- [ ] The build reaches TestFlight, with widgets and the Live Activity working.
