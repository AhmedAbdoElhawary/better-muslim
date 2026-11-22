# Data Model: Milestone 10, Onboarding and Backup

Schema version 6 of the encrypted store. Enums are stored by name, like milestones 2 to 9.

## Stored: `settings`, new column

| Column | Type | Default | Rule |
| --- | --- | --- | --- |
| onboarded | bool | false | true after Apply on the theme step (FR-001). Belongs to the phone, never in a backup |

## Stored: `settings`, already there and now changed by onboarding

| Column | Since | Changed by |
| --- | --- | --- |
| latitude … locationMode | 2 | 4.11: Use my location (auto) or the city search (manual) |
| fajrSound … ishaSound | 5 | 4.12's segments |
| reminderMinutes | 5 | 4.12's reminder row (the milestone 9 sheet) |
| notificationsAsked | 5 | written true after 4.12's Allow is answered, or the "off" line's first ask (R10). Belongs to the phone |
| storeResetPending | 2 | cleared by either answer of the reset notice (FR-036). Belongs to the phone |
| theme, themeMode | 2 | the theme step's Apply |

## Migration 5 → 6

- add `onboarded` with default false
- `update settings set onboarded = 1 where latitude is not null` (an older install with a place
  counts as finished)
- `dart run build_runner build` and `dart run drift_dev make-migrations` write
  `drift_schema_v6.json`, the steps and `test/drift/app_database/generated/schema_v6.dart`.
  `migration_test.dart` checks v5 → v6: every row kept, a row with a place reads onboarded, one
  without reads not.

## In memory: onboarding

`Onboarding(done: bool, replay: bool)` in `core/settings/onboarding.dart`.

| Event | done | replay |
| --- | --- | --- |
| launch | from `settings.onboarded`, read in bootstrap | false |
| Apply on the theme step | true (written to the store) | false |
| dev "Replay onboarding" | unchanged | true |

The router shows onboarding while `!done || replay` (R2).

## In memory: the sun

| Field | Meaning |
| --- | --- |
| stage | intro (first screen) or main (4.10) |
| home | the rest spot the sun springs to: dome or horizon |
| position, velocity | the sun's centre and speed in logical px |
| dragging, grab offset, grab travel | the finger and its catch up |
| b | the welcome's build, 0 to 1 |
| fill | 0 glass, 1 the designed sun |
| glow, glow pulse | the arc while lifting, the flash when sinking back |
| committing | a stage change is running, the grab area is off |

## The backup file

See [contracts/backup-file.md](contracts/backup-file.md) for the bytes.

What the payload store holds:

| Table | Rows | Restored as |
| --- | --- | --- |
| settings | row 1 | every column, except this phone's `onboarded`, `notificationsAsked`, `storeResetPending`, which stay |
| prayer_log | all | all |
| qada_entries | all, ids kept | all |
| azkar_counts | all | all |
| saved_duas | all | all |

In the payload the phone's own columns are written at their defaults (false), so the file holds
nothing about the phone that made it (FR-030).

Validation on restore, in order (each one changes nothing when it fails):

| Check | Fails as |
| --- | --- |
| the magic | not a backup |
| the payload length | damaged |
| the schema version ≤ the app's | newer |
| the first read with the password | wrong password |
| `pragma quick_check` = ok | damaged |

## Store calls

| Call | What it does |
| --- | --- |
| `AppDatabase.backup(File, String password)` | opens or makes a store keyed by the password (R12) |
| `writeBackup(AppDatabase from, String password)` | returns the temp `.bmbackup` file |
| `readBackup(File, String password)` | returns the opened backup store or a `BackupError` |
| `restore(AppDatabase into, AppDatabase from)` | one transaction, all tables, phone columns kept |
