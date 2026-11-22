# 25: One-row strip on 12-hour phones

**What to build:** Home's prayer strip stays in one row on 12-hour phones by dropping AM/PM in the
strip only ("4:58", "12:05"). It still stacks above text scale 1.4.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] One row up to text scale 1.4, stacked above it.
- [x] On 12-hour phones the strip shows no AM/PM. Every other time in the app keeps it.
- [x] Screen readers still hear the full time with AM or PM.
- [x] 24-hour phones and Eastern digits are unchanged.
- [x] `home_page_test` and `break_ui_test` cover a 12-hour phone at 1.0 and 1.4.
