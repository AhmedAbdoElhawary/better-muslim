# Contract: `assets/places/places.tsv.gz`

Written by `tool/places/build_places.dart`, read by `PlaceList` in core. UTF-8, gzip, tab
separated, `\n` line ends. A line starting with `#` opens a section. Sections come in this order.

```text
#geonames <download date yyyy-mm-dd> CC BY 4.0
#zones
<iana id>                                   one per line, line number (from 0) = zone index
#countries
<cc>\t<name en>\t<name ar or empty>
#regions
<cc>.<admin1 code>\t<name en>\t<name ar or empty>
#places
<name>\t<ascii or empty>\t<name ar or empty>\t<cc>\t<admin1 code>\t<lat ×1e4>\t<lng ×1e4>\t<population>\t<zone index>
```

## Rules

- Places are sorted by population, biggest first. Search relies on that order to stop early.
- `ascii` is empty when it equals `name`, the reader falls back to `name`.
- `lat ×1e4` and `lng ×1e4` are rounded integers (about 11 m).
- Every zone is a valid id in `package:timezone` `latest_all`. The build fails otherwise.
- Places are those in GeoNames `cities1000`: population over 1,000, plus capitals and region seats.
- Arabic names come from `alternateNamesV2` with `isolanguage = ar`. `isPreferredName` wins, and
  `isHistoric` and `isColloquial` names are skipped.
- Expected size: about 3.5 MB. The build prints the size and fails above 8 MB, which keeps SC-008
  (≤ 10 MB installed) safe.

## Reader

`PlaceList.load()` reads the asset bytes on the main isolate, then parses them inside `Isolate.run`.
The parsed list comes back without a copy, since `Isolate.exit` transfers it. A broken asset is a
build bug, the reader throws and the test suite catches it.
