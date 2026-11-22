# Research: Milestone 4, Prayer

Checked on 2026-10-17 against the code from milestones 1 and 2, the package sources in the pub
cache (drift 2.35.2, drift_flutter 0.3.1, riverpod 3.4.3, intl 0.20.3) and the Flutter SDK.

## R1. What goes in core, what stays in the feature

- **Decision**:
  - `core/`: the prayer log, the prayer day and the window ends. Home's strip checks
    (milestone 3), Mark prayed on the adhan screen and the notification (milestone 5) and the
    widgets (milestone 11) all read or write the log.
  - `features/prayer/` (clean): qada, the row states, the week strip and the screens. Nothing
    else needs them.
  - All tables sit in `core/database/app_database.dart`, since drift registers every table on the
    one database class and core can't import a feature.
- **Rationale**: constitution I puts shared logic in core and makes prayer a clean feature.
  Milestone 5's spec (`specs/002-milestone-5-notifications/`, FR-018) logs a prayer from a
  notification action without opening the app, so the write has to be a plain store call that
  works without widgets or Riverpod.
- **Alternatives**: the log inside the feature (Home and notifications couldn't reach it), qada in
  core (no second user, it would only move code away from its one screen).

## R2. How a day is stored

- **Decision**: a date is stored as text `yyyy-MM-dd` through one drift `TypeConverter`
  (`CivilDate`), read back as `DateTime(y, m, d)`, the same shape `todayProvider` gives.
- **Rationale**: drift stores `DateTime` as unix seconds by default, an instant. Read back in
  another time zone, a local midnight lands on a different date and a logged prayer would move a
  day (FR-010). Text dates have no zone, sort and compare as strings (week and month ranges are
  string `between`), and read clearly in a dump.
- **Alternatives**: an int day number (same safety, unreadable), `store_date_time_values_as_text`
  (still an instant with an offset, changes every existing datetime column).

## R3. The prayer day and the windows

- **Decision**:
  - `DayTimes.endOf(prayer, tomorrow)` gives the end of a prayer's window: the next period start
    that has a time, so Fajr ends at sunrise, Dhuhr at Asr, Asr at Maghrib, Maghrib at Isha and
    Isha at tomorrow's Fajr. It returns null only when nothing after has a time (polar).
  - `prayerDayProvider` in `core/prayer_times/` is the location's date, except before today's Fajr
    when it is yesterday.
  - Like `periodProvider`, it follows the ticker but only notifies when the date changes.
- **Rationale**: these are the same boundaries `periodAt` already uses (milestone 2 FR-015a), so
  Home's NOW and the Prayer tab's NOW never disagree. They are the widest valid window (Q2), and
  Isha at 00:30 stays on its own day.
- **Alternatives**: Isha until the middle of the night (a ruling, turned down in Q2), a midnight
  day switch (late Isha would sit on yesterday's cell).

## R4. Row state as one pure function

- **Decision**: `features/prayer/domain/prayer_row_state.dart` holds
  `PrayerRowState rowState({time, end, now, logged, qada, next})` plus `isOpen`. It is pure Dart,
  with no Flutter and no providers. The rules, first match wins:
  1. no time that day → `unavailable`
  2. logged → `prayed`
  3. before its time → `next` when it is the next prayer's exact instant, else `later`
  4. before its end → `mark`
  5. a dated qada entry → `madeUp` when made up, else `inQada`
  6. otherwise → `addToQada`

  `isOpen` (start ≤ now < end) fills the row and shows NOW, logged or not.
- **Rationale**: SC-004 asks for every row at a minute either side of every boundary. A pure
  function is tested in a loop over minutes with no widget tree. Future days need no special
  case, rule 3 already turns them into `next` or `later`.
- **Alternatives**: the state worked out inside each row widget (untestable without a tree), a
  stored state per row (it goes stale the moment a window closes).

## R5. Qada storage and "made one up"

- **Decision**:
  - One row per entry in `qada_entries`: prayer, `missed_on` (null for "before the app") and
    `made_up_at` (null while open).
  - "Made one up" picks the open entry of that prayer ordered by `missed_on` with nulls first,
    then by id.
  - A unique index on `(missed_on, prayer)` keeps a prayer day in qada once. SQLite treats nulls
    as distinct, so dateless entries don't collide.
  - Counts come from grouped `count(*)` queries, never from loading every row.
  - + adds `count` dateless rows (1 to 999) in one batch and returns their ids, so the toast's
    Undo deletes exactly that batch.
- **Rationale**: one shape for both kinds of entry. Undo of "made one up" sets `made_up_at` back to
  null on the same id. The month count (FR-016) is a `missed_on` range on open entries.
- **Alternatives**: five counters on the settings row (no dates, so no "this month" and no "Made up"
  on a day's row), a separate table for dateless entries (two queries for every count).

## R6. Schema version 2

- **Decision**: `schemaVersion` goes to 2 with drift's step by step migration (`make-migrations`,
  already set up in `build.yaml`): `from1To2` creates `prayer_log` and `qada_entries`, adds
  `settings.first_use` and fills it with `date('now', 'localtime')`.
  - New stores set `first_use` when the settings row is created, from the clock `settingsProvider`
    passes in (`watchSettings(now: clock())`), so tests and the scenario control it.
  - `drift_schemas/` gets `drift_schema_v2.json`, and `test/drift/` gets the generated v2 schema
    and `migration_test.dart`.
- **Rationale**: milestone 2 FR-022 says data survives updates that change the store layout, and
  the dev phone already has a v1 store. `ADD COLUMN` can't take a non-constant default in SQLite,
  hence the nullable column filled by the migration.
- **Alternatives**: deriving first use from the earliest log row (a user who logged nothing yet
  couldn't reach the weeks since install), a destructive reset on upgrade (breaks FR-022).

## R7. Arabic plurals

- **Decision**:
  - Arabic strings with counts use ICU plural syntax in `app_ar.arb`.
  - `AppLocalizations.tr` swaps the `{placeholders}` as today, then runs any string with
    `, plural,` through intl's `MessageFormat` (`package:intl/message_format.dart`, intl 0.20.3 is
    already a direct dependency), with the count read back from its Eastern or Western digits.
  - `AppLocalizations` keeps the language code for that.
  - English stays plain text, it needs no plural forms here.
- **Rationale**: the existing "{count} صلوات فائتة…" is right only for 3 to 10 (FR-029).
  `MessageFormat` uses CLDR rules (zero, one, two, few, many, other), so no rules get written by
  hand. Callers keep passing already formatted digits, so nothing at the call sites changes.
- **Forms**: one "صلاة واحدة …", two "صلاتان …" (with "فائتتان" for the missed line), few
  "{count} صلوات …", other (zero, many and 11 or more) "{count} صلاة …". These are only the
  grammatical forms of the approved wording (Q4).
- **Tests**: every plural string formats for 0 to 12 in both languages without throwing, and has
  no `'` (ICU quote). `strings_manager_test` still sees `{count}` in both files, its regex only
  matches ASCII names.
- **Alternatives**: a key per form (the arb key sets would differ between languages),
  hand-written Arabic rules (CLDR already has them).

## R8. Toast, sheet and compact bar

- **Decision**: three design system components from `03 Components.dc.html`, in
  `core/widgets/`:
  - `toast/`: `showToast(context, key, args:, onUndo:)`. A floating `SnackBar` with the
    component's content, 4 s, Undo as our own text button. The shell Scaffold is the root, and
    Flutter shows a SnackBar only on the root of nested Scaffolds, so it sits above the tab bar
    and survives tab switches.
  - `sheet/`: `showBmSheet(context, title:, child:)` with the grabber, xl top radius and the 64%
    dark / 48% light scrim, plus `PickerRow` (the "Selected (picker)" row state).
  - `compact_app_bar.dart`: the 56 pt bar with the 44 × 44 back chevron that mirrors in RTL, and
    the large title that collapses into it on scroll (Prayer now, More in milestone 9).
- **Rationale**: they are design system parts like the adaptive widgets, and the next milestones
  use them too (adhan sound sheet in 5, bookmark toast and text size sheet in 7, Qibla's pushed
  page in 6), so core avoids a move later.
- **Alternatives**: an Overlay toast (has to work out the nav bar height and the tab switches by
  itself), copies inside the feature (moved again in milestone 5).
- **Milestone 3 first**: Home is built before this milestone, and its location sheet needs a
  bottom sheet. Whatever of these three milestone 3 already put in `core/` is reused as it is.

## R9. Week strip paging

- **Decision**:
  - A `PageView` with one page per week, from the week of `first_use` (clamped to today) up to
    the current week. It opens on the last page and has no page after it.
  - A week starts on the Sunday on or before the date.
  - Each page watches one range query for its 7 days (`weekLogProvider(weekStart)`, autoDispose).
- **Rationale**: horizontal scrollables follow `Directionality`, so in Arabic page 0 is on the
  right: earlier weeks come from the right, and the week reads from Sunday on the right as 4.17
  shows. One query per visible week keeps a year of logs cheap (SC-006).
- **Alternatives**: an infinite strip (would reach future weeks, which FR-013 rules out), 7
  queries per page.

## R10. Selected day and deep links

- **Decision**:
  - `selectedDayProvider` (presentation) holds the picked day, null = follow `prayerDayProvider`.
    So at Fajr the screen moves to the new day unless another day was picked.
  - The strip's filled cell is the shown day (`selectedDay ?? prayerDay`), so at 00:30 it is
    yesterday. Future days keep their grey numbers.
  - The route takes `day` and `prayer` query params: `/prayer?day=2026-10-15&prayer=asr` picks the
    day and scrolls to the row. `/prayer/qada` pushes the qada list inside the Prayer branch.
- **Rationale**: Home's strip cell → "Prayer tab scrolled to that prayer" (milestone 3), and a
  notification tap → "the Prayer tab at that prayer" (milestone 5 spec). One route serves both.
  The summary card keeps reading today (FR-014).
- **Alternatives**: a route per day (`/prayer/2026-10-15`, would push pages onto the tab stack).

## R11. Day complete

- **Decision**: `mark()` returns whether this mark made the day's fifth. Only then does the view
  play Motion 08 with `BmHaptics.dayComplete`.
- **Rationale**: a day that is already complete when it opens or when the stream updates must not
  play. After an undo, marking the fifth again plays it again (spec edge case).
- **Alternatives**: playing when the count reaches 5 (plays when a complete day is opened).

## R12. Design scenario data

- **Decision**:
  - In the scenario, bootstrap opens an in-memory store from `designScenarioStore()` instead of
    `AppDatabase.open()`, seeded with: `first_use` 1 Oct 2026; Sun 11, Mon 12 and Wed 14 with all
    five; Tue 13 without Isha and with Tue Isha in qada; Thu 15 Fajr and Dhuhr; and two more open
    dated entries in October (Fajr 6 Oct, Fajr 8 Oct). That is 3 for "this month".
  - The scenario overrides `dayTimesProvider` per date: 15 Oct gives the handoff's six times
    (milestone 2 R10), every other date a real Makkah calculation. `todayTimesProvider` then
    follows by itself, so its own override goes.
- **Rationale**: seeding the real dev store would mix fake prayers into the developer's own log.
  Riverpod 3 families take `overrideWith((ref, date) => …)`, which keeps the scenario in one file.
- **Note**: in the scenario the method sheet changes nothing, since its times are fixed. The sheet
  is checked in plain Dev (quickstart 3).

## R13. Accessibility without new copy

- **Decision**: each row is one `Semantics` node built from the existing strings: prayer name,
  time and the chip label. Mark and "Add to qada" are buttons. "Prayed" is a toggle that reads as
  checked, so "Prayed, checked, button" tells the screen reader user that a tap unchecks it.
  "Made up" is plain text, not a button.
- **Rationale**: FR-030 without adding strings outside the approved table (Q4).

## R14. The location sheet from milestone 3

- **Decision**: the pin calls the same sheet as Home's location pill (milestone 3 FR-021 to
  FR-023). The sheet lives in `core/`. If milestone 3 left it under `features/home/`, this
  milestone moves it to `core/` first, with no change to how it looks or works.
- **Rationale**: constitution I, a widget two features use lives in core, never two copies. Its
  data (place list search, `locationControllerProvider.choose` and `useAuto`) is already core from
  milestone 2.
- **Alternatives**: a second sheet in the prayer feature (two copies), a pin that does nothing
  (the first Q7 answer, changed once milestone 3 pulled the sheet forward).

## R15. The + count sheet

- **Decision**: `add_older_sheet.dart` in the prayer feature: the sheet from R8, the title "Add
  missed {prayer}", − and + as 44 × 44 `BmIcon.ui` buttons around the count, and "Add".
  - Holding − or + repeats on a timer that speeds up the longer it is held. The count stays
    between 1 and 999.
  - A tap gives the selection haptic, and the repeat steps don't, so a long hold doesn't buzz on
    every step.
- **Rationale**: someone returning to prayer adds months at once (the second Q2). The handoff has
  no stepper, so it is built from parts it does have, the minus and plus icons and the sheet, and
  I check it in the app before it counts as done (FR-022).
- **Alternatives**: a text field for the number (needs a keyboard and validation, and Eastern
  digits input), one entry per tap (the first answer, slow for years).

## R16. The journey test

- **Decision**: one test in `integration_test/prayer_journey_test.dart` with the SDK's
  `integration_test` (approved 2026-10-18). It pumps `App` with `designScenarioOverrides()` on
  `designScenarioStore()` and walks one path:
  - Mark Asr, then unmark it and Undo
  - Tuesday's Isha: "In qada", then "Add to qada", then "I prayed it"
  - on the qada list, "Made one up" on Fajr, then Undo

  It runs on an iOS simulator and an Android emulator.
- **Rationale**: constitution VI asks for an integration test of each main journey, and logging a
  prayer is this milestone's main journey. On a real engine it also covers what widget tests fake:
  the encrypted store's drift streams, the shell's toast and real gestures.
- **Alternatives**: widget tests only (they don't cover the store's streams or the shell's toast
  on a real engine), patrol or another driver package (not needed for one path).

## Notes for later milestones

- **Milestone 5**: the notification action writes through `AppDatabase.markPrayed` from a
  background engine. drift streams only refresh for writes on the same connection, so milestone 5
  either opens the store with `DriftNativeOptions(shareAcrossIsolates: true)` (drift_flutter
  0.3.1 has it) or refreshes the log providers on resume. Its spec only asks that the prayer
  "shows as prayed the next time Home or Prayer opens", both work.
- **Milestone 9**: "Reset prayer journey?" adds `AppDatabase.clearPrayerJourney()` (both tables).
  If More reuses the method sheet, the sheet moves to `core/` then.
