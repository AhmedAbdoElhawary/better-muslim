# 01: Pipeline fixes

**What to build:** The fixes the pipeline needs before its first run.

**Blocked by:** None (can start immediately)

**Status:** open

- [ ] `verify` in `deploy.yml` runs only for a pushed tag, not a called deploy.
- [ ] `patch.yml` keeps its symbols and uploads them to Sentry, checked against `shorebird patch --help`.
- [ ] Every workflow is on an action version that doesn't need Node 20.
- [ ] `API_BASE_URL` and `apiBaseUrl` are gone.
- [ ] `overallMin` is 85.
- [ ] `integration.yml` passes when run by hand on `develop`.
