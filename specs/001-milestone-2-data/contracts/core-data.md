# Contract: core data for the features

What milestone 3 onward reads and calls. Features use only these providers and calls, never
geolocator, adhan_dart, hijri, drift or the secure storage directly (constitution I: shared logic
lives in `core/`). All are plain Riverpod providers, no code generation. Widgets watch them with
`.select()`.

## Read

| Provider | Type | Gives |
| --- | --- | --- |
| `databaseProvider` | `Provider<AppDatabase>` | the open store. Overridden in bootstrap, tests override it with an in-memory store |
| `settingsProvider` | `StreamProvider<AppSettings>` | the settings row, updates on every write |
| `locationProvider` | `Provider<Location?>` | the current location, null = no location yet |
| `clockProvider` | `Provider<DateTime Function()>` | "now". The design scenario freezes it |
| `tickerProvider` | `StreamProvider<DateTime>` | now, once a second, for countdowns |
| `todayProvider` | `StreamProvider<DateTime>` | the location's local date, changes at local midnight |
| `dayTimesProvider` | `Provider.family<DayTimes?, DateTime>` | the six times for a local date, null without a location |
| `todayTimesProvider` | `Provider<DayTimes?>` | today's times |
| `periodProvider` | `Provider<Period?>` | the current period (FR-015a), follows the ticker |
| `nextPrayerProvider` | `Provider<(Prayer, TZDateTime)?>` | the next of the five and its time (FR-015) |
| `hijriDateProvider` | `Provider.family<HijriDate, DateTime>` | the Hijri date for a local date with the adjustment |
| `placeListProvider` | `FutureProvider.autoDispose<PlaceList>` | the place list, loaded on first use, dropped when unused |
| `flavorProvider` | `Provider<FlavorConfig>` | the flavor, overridden in bootstrap |

## Write

| Call | Effect |
| --- | --- |
| `ref.read(locationControllerProvider).refresh()` | asks permission if needed, gets a fix, applies the 30 km rule (FR-008). Called on start and resume by core, features rarely need it |
| `ref.read(locationControllerProvider).useAuto()` | switches to auto and refreshes |
| `ref.read(locationControllerProvider).choose(place)` | saves a manual location (FR-006) |
| `ref.read(databaseProvider).updateSettings(SettingsCompanion)` | writes any setting. Method and Asr writes are user picks, `Value(null)` returns to "by country" |

## Search

`PlaceList.search(query, {limit = 30})` returns `List<Place>`, biggest first, matching English and
normalized Arabic (FR-005). `PlaceList.nearest(lat, lng)` returns the `Place` that names a position
(FR-003).

## Formatting

`context.formatTime(TZDateTime)` gives the phone's 12 or 24 hour format with the right digits for
the app language and the digits setting (FR-017a). It is the only way features turn a time into
text.

## Guarantees

- No call touches the network.
- Nothing here puts coordinates, place names or settings values in a crash report.
- `dayTimesProvider` gives the same result for the same inputs. It doesn't read the clock.
