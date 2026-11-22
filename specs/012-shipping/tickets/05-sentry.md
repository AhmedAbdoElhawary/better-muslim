# 05: Sentry on the privacy rules

**What to build:** Crash reports that say which screen, and nothing from the never sent list.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] Every route has a fixed name with no ids in it, and each change leaves that name as a breadcrumb.
- [x] Production traces are 10%.
- [x] Errors in the background engines reach Sentry, with no sessions or traces.
- [x] A test proves no route parameter reaches a breadcrumb.
- [x] Error text loses sqlite's statement and parameters and any url before it is sent.
