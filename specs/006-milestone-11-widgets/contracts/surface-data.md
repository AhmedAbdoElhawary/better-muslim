# Contract: the surface data file

`surfaces.json`, written by `packages/prayer_surfaces` with the JSON `buildSurfaceData` returns
(`lib/core/surfaces/surface_data.dart`). Read by the iOS extension, the iOS plugin (Live Activity)
and the Android plugin. UTF-8, about 40 KB for 7 days.

Every string is final: in the app's language, digits and 12/24 hour setting. The only things the
native side makes are the countdown numbers and the shares (contracts/native-surfaces.md).

## Shape

```json
{
  "version": 1,
  "place": true,
  "language": "en",
  "eastern": false,
  "countdown": true,
  "until": 1792646280000,
  "texts": {
    "noPlace": "Open Better Muslim to set your place",
    "outdated": "Open Better Muslim to update the times",
    "open": "Open Better Muslim",
    "now": "Now",
    "inDuration": "in {duration}",
    "timeLeft": "{hours} h {minutes} min until {prayer}",
    "next": "NEXT",
    "nextPrayer": "Next prayer",
    "nextCity": "NEXT · MAKKAH",
    "nextCityShort": "Next · Makkah",
    "liveNext": "Next prayer · Makkah",
    "methodLine": "Makkah · Umm al-Qura",
    "channel": "Prayer countdown"
  },
  "entries": [
    {
      "from": 1792066020000,
      "prayer": "maghrib",
      "day": "2026-10-15",
      "at": 1792076160000,
      "name": "Maghrib",
      "time": "17:56",
      "atTime": "at 17:56",
      "timeCity": "17:56 · Makkah",
      "nameTime": "Maghrib 17:56",
      "barFrom": 1792066020000,
      "barFromLabel": "Asr 15:27 · prayed",
      "sunrise": 1792043700000,
      "maghrib": 1792076160000,
      "hijri": "4 Jumada I 1448",
      "hijriCity": "4 Jumada I 1448 · Makkah",
      "dateLine": "Thu 15 Oct · 4 Jumada I",
      "prayedLine": "3 of 5 prayed today",
      "reminder": "Reminder 17:46",
      "next": 3,
      "strip": [
        { "prayer": "fajr", "name": "Fajr", "time": "04:58", "logged": true, "past": true },
        { "prayer": "dhuhr", "name": "Dhuhr", "time": "12:05", "logged": true, "past": true },
        { "prayer": "asr", "name": "Asr", "time": "15:27", "logged": true, "past": true },
        { "prayer": "maghrib", "name": "Maghrib", "time": "17:56", "logged": false, "past": false },
        { "prayer": "isha", "name": "Isha", "time": "19:26", "logged": false, "past": false }
      ]
    }
  ],
  "countdowns": [
    { "start": 1792068960000, "end": 1792076160000, "entry": 0 }
  ]
}
```

## Fields

| Field | Rule |
| --- | --- |
| version | 1. A reader that finds a higher one shows "out of date" (an app update the extension hasn't caught up with) |
| place | false: no entries, no countdowns, the no place state |
| language | `en` or `ar`. `ar` lays out right to left, uses Reem Kufi for names and Noto Sans Arabic for the rest |
| eastern | true only in Arabic with Eastern digits. The native countdowns map 0-9 to ٠-٩ |
| countdown | the switch. false: `countdowns` is empty and every running one ends |
| until | end of the last entry. Past it: the out of date state. 0 with no place |
| texts | the strings that don't change with the moment. `{duration}`, `{hours}`, `{minutes}`, `{prayer}` are filled natively |
| entries | ascending `from`, the first at the start of the stretch the write falls in (the last boundary at or before it), so two writes in the same stretch give the same file and the equal check skips the second |
| entries[].strip | always 5, Fajr first. Times of a polar day without one are "—" (as Home's strip) |
| entries[].next | 0 to 4, or null after Isha |
| entries[].barFrom, sunrise, maghrib | null when the day has no such time |
| entries[].reminder | null when the reminder is off |
| countdowns | ascending `start`, at most 30 (6 days x 5) |

Nothing else goes in: the test compares the key set of the built JSON with this list (SC-006).

## Countdown content

What a running countdown shows, taken from `entries[entry]` and `texts`:

| Shown | From |
| --- | --- |
| "Next prayer · {city}" | `texts.liveNext` |
| "Next prayer" | `texts.nextPrayer` (expanded island) |
| the prayer | `name` |
| the countdown | `at`, counted by the system |
| "at {time}" | `atTime` |
| the bar | `barFrom` to `at` |
| start label | `barFromLabel` |
| end label | `nameTime` |
| "{city} · {method}" | `texts.methodLine` (expanded island) |
| "Reminder {time}" | `reminder`, the chip only when not null |
| Android title | `nameTime` |
| Android text | `texts.liveNext` |
