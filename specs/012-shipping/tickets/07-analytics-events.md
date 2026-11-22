# 07: Analytics events

**What to build:** `AnalyticsService` with the fixed events from the spec, and the rule in the constitution.

**Blocked by:** 06

**Status:** after launch, with 06

- [ ] App code only calls `AnalyticsService.instance`, debug runs and tests send nothing.
- [ ] The events take enums, so free text can't be sent.
- [ ] `architecture_test` bans analytics calls outside `core/monitoring`.
- [ ] The constitution is 5.3.0 with the never sent rule and Firebase Analytics in the stack.
