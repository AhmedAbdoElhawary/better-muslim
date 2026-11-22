# 01: Pipeline fixes

**What to build:** The fixes the pipeline needs before its first run.

**Blocked by:** None (can start immediately)

**Status:** open

- [x] `verify` in `deploy.yml` runs only for a pushed tag, not a called deploy.
- [x] `patch.yml` keeps its symbols and uploads them to Sentry, checked against `shorebird patch --help`.
- [x] Every workflow is on an action version that doesn't need Node 20.
- [x] `API_BASE_URL` and `apiBaseUrl` are gone.
- [x] `overallMin` is 85.
- [ ] `integration.yml` passes when run by hand on `develop`.
