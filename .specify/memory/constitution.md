# Better Muslim Constitution

Prayer times, Quran, azkar and qibla for iOS and Android, in English and Arabic. Built on my
Flutter blueprint (`~/.claude/skills/flutter-new-project/BLUEPRINT.md`) and the approved design
in `design_handoff_better_muslim/`.

## Core Principles

### I. Feature-Based Structure

- `lib/` holds only `main*.dart`, `bootstrap.dart`, `core/` and `features/`.
- Each feature MUST be one shape, never a mix: MVVM (`model/`, `view_model/`, `view/`) or clean
  (`data/`, `domain/`, `presentation/`). Clean when it talks to a backend or platform service, has
  more than one data source or real business logic; MVVM otherwise.
- Shapes for this app: clean = prayer (logging, qada), notifications + adhan, quran (reader and
  audio), home widgets and live activity. MVVM = home, qibla, azkar + tasbih, duas, more, theme
  picker, hijri calendar, onboarding.
- Anything two features need lives in `core/`: prayer time calculation, location, hijri date,
  settings and the database.
- Imports go one way: no feature imports another feature, `core/` imports no feature except
  `core/router/`, `domain` imports no `data` or `presentation`, `data` imports no `presentation`,
  `model` imports no `view_model` or `view`, `view_model` imports no `view`.

Why: every feature can change or be deleted without touching the others.

### II. Centralized Design System

- The handoff values live unchanged in `lib/core/resources/design/` (`BmPalette` with its 8
  themes, `BmText`, `BmSpace`, `BmRadius`, `BmSize`, `BmMotion`, `BmHaptics`, `BmIcon`). The app
  reads them only through my api.
- Colors MUST come from `context.getColor(ThemeEnum.x)`. Never `Colors.x`, `Color(0x..)` or
  `context.bm` in features.
- Text MUST go through `LightText`, `RegularText`, `MediumText`, `SemiBoldText`, `BoldText`.
  Never `Text` or `TextStyle` outside core. The font defaults to `FontEnum.body` (Schibsted
  Grotesk / Noto Sans Arabic), Marcellus / Reem Kufi is `font: FontEnum.display`. Each weight
  defaults to the size the screens use most with it (regular 13, medium 15, semibold 17).
- Every size, gap, radius, font size, line height and letter spacing MUST come from
  `SpaceManager`, `RadiusManager`, `SizeManager`, `FontSizeManager`, `LineHeightManager`,
  `LetterSpacingManager`. No raw numbers in features.
- Spacing goes through the adaptive paddings and `RSizedBox`. Never `Padding`, `SizedBox` or
  `EdgeInsets` outside core.
- Icons MUST come from `BmIcon`. Never Material or Cupertino icons.
- Strings MUST be `StringsManager` keys: `RegularText(StringsManager.x)`, and
  `context.tr(StringsManager.x)` where there is no text widget. A new string goes into
  `StringsManager` and both arb files in `assets/l10n/` together. Text that is not a key (times,
  numbers, names, Quran) passes `translate: false`.
- Sizes scale from the 393 pt design with ScreenUtil, capped at 1.3x. Tablets and foldables get
  the phone layout stretched to at most 480 pt until they have their own design.
- RTL works by default: start/end, never left/right. The sun arc, clock times, progress rings and
  media controls are never mirrored. Arabic shows Eastern Arabic digits.

Why: one place to change any color, size, font or string, and all 8 themes, both modes and both
languages keep working.

### III. Faithful To The Design

- The handoff is the approved design. Don't redesign, restyle, re-space or "improve" it.
- A screen is built straight from its tree in `specs/screens/*.md` (positions, sizes, colors,
  fonts, copy, icons), and works in dark and light, English and Arabic, text scale 1.0 and 2.0,
  reduce motion on and off.
- No golden tests and no comparing screenshots against the PNGs, too expensive. The PNGs are only
  a reference to look at.
- Contrast meets WCAG AA in both modes. Every hit target is at least 44 x 44.
- Every animation follows `MOTION.md` and has its reduce-motion fallback. Haptics only through
  `BmHaptics`.
- Quran text is never animated, overlapped, cropped or used as decoration.

Why: the design is finished and approved, the work is building it exactly.

### IV. Simplicity (KISS, DRY, YAGNI)

- The simplest code that works. No abstraction, interface, generic or config flag nobody asked
  for.
- Logic or a widget used by two features moves to `core/`. Never two copies.
- DRY covers parameters too: a widget's defaults are what most call sites need, so a call passes
  only what differs.
- A package is added in the milestone that first needs it, not before.
- SOLID, separation of concerns, plain short names like the rest of the code.

Why: I read and change this code alone, simple code is what keeps it moving.

### V. Performance By Default

- `const` wherever it fits.
- Small widget classes, never `Widget _buildX()` functions.
- Rebuild only what changed: Riverpod `.select()`, `MediaQuery.sizeOf` and friends, never
  `MediaQuery.of`.
- A child reads its own data from Riverpod instead of the parent passing it through widgets that
  don't use it. Small leaf widgets can take a value to stay const.
- Lazy load heavy resources (Quran pages, audio), cache what was fetched, fetch only what is
  shown.

Why: a prayer app is opened many times a day, it has to open and scroll instantly.

### VI. Enforced By Tests

- `test/architecture_test.dart` checks principles I and II on every `flutter test`. A rule I care
  about gets added there, not only written down.
- `test/core/resources/font_manager_test.dart` keeps the font managers equal to `BmText`, and
  `strings_manager_test.dart` keeps `StringsManager` and both arb files the same keys and
  placeholders.
- Logic gets unit tests (prayer times, qada, notification schedule), screens get widget tests,
  main journeys get integration tests.
- Before anything is called done: `dart format` (page width 100), `flutter analyze` clean,
  `flutter test` green.

Why: rules that only live in a document get broken, a failing test doesn't.

### VII. Security And Privacy

- Location and prayer history stay on the device. Nothing leaves it without my decision.
- The whole drift database is encrypted. Its key is made on the phone on first launch and lives
  only in flutter_secure_storage.
- The database stays out of iCloud and Android auto backup. A new phone gets the data only from
  the app's own backup file.
- Secrets never go in the repo or the app bundle.
- Https only, and anything downloaded (Quran text, audio) is validated before use.
- Ask me before writing the privacy policy and terms.

Why: what someone prays and where they are is personal.

### VIII. Offline-First And Free

- Everything works with no internet: prayer times, Hijri date, Qibla, city search, Quran text,
  azkar and duas. All of it is computed on the phone or shipped inside the app.
- The network is only for downloading content (recitation audio), and what is downloaded is
  cached so it works offline after.
- No backend, no account, no paid API or service. A free online service only when nothing on the
  phone can do the job, and only after I decide it.
- Data and content used under a license (GeoNames, Tanzil, fonts) get the credit their license
  asks for.

Why: a prayer app has to work on a plane, abroad without data, and cost nothing to run.

## Stack And Constraints

- State: Riverpod. Routing: GoRouter with a `StatefulShellRoute` for the 5 tabs (Home, Prayer,
  Quran, Azkar, More). Localization: the arb files in `assets/l10n/`, read at runtime by
  `AppLocalizations` in core, no code generation. Sizing: flutter_screenutil. Svg: flutter_svg.
- Storage: drift only (with drift_dev and build_runner for its code), encrypted, with its key in
  flutter_secure_storage and its file in path_provider's Application Support folder. No
  shared_preferences, no hive.
- Domain packages, each added in its milestone: adhan_dart (not adhan, which stopped in 2023),
  hijri, geolocator, flutter_compass, flutter_local_notifications, timezone, flutter_timezone,
  just_audio, audio_session, home_widget, live_activities.
- Place names and city search come from a GeoNames list shipped in the app (every country, places
  over 1,000 people plus capitals and region seats), never from geocoding, which needs internet.
- Any other package: check pub.dev maintenance and popularity first, then ask me.
- Content not in the handoff (Quran text, recitation audio with timings, adhan audio, azkar and
  duas with sources) uses the handoff's sample content and a `TODO(ahmed)` until I provide it.

## Development Workflow

- Ask me every question first, all in one message with a recommendation each. Never fill a gap.
  When everything is answered, write **start building**.
- Build in the handoff's milestone order (`design_handoff_better_muslim/HANDOFF_CLAUDE.md`), one
  milestone at a time. Stop after each, I review it by running the app myself (Dev or the design
  scenario). No screenshots, also for screens the handoff doesn't design.
- Speckit (specify, plan, tasks) for every milestone. Where the handoff already specs the screen,
  the spec is short: only what the handoff leaves open, the layout stays in the handoff and is
  built straight from it.
- Comments only say why, one line, default none. Public core classes get a one-line `///` where
  a teammate would ask.
- Commits are mine: no tool or AI names in commits, branches, PRs or tags.
- Flavors, CI and releases come from `/flutter-shipping` when I'm ready to release.

## Governance

- This constitution wins over the handoff's own notes and any other guidance in the repo. Only an
  explicit instruction from me in the conversation overrides it.
- The project `CLAUDE.md` loads it every session with `@.specify/memory/constitution.md`.
- Changing it: edit this file, bump the version (MAJOR when a rule is removed or reversed, MINOR
  when a rule or section is added, PATCH for wording), update the date, and update
  `test/architecture_test.dart` when the changed rule can be checked there.
- Every milestone and every speckit plan is checked against these principles before it's called
  done. A break needs my approval and a line in the reply saying why.

**Version**: 3.0.0 | **Ratified**: 2026-10-16 | **Last Amended**: 2026-10-18
