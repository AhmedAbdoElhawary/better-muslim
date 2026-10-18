// Builds assets/places/places.tsv.gz from GeoNames, see specs/001-milestone-2-data/contracts/places-asset.md.
//
//   dart run tool/places/build_places.dart
//
// Downloads about 220 MB into tool/places/.cache/ once, delete the folder to refresh GeoNames.

import 'dart:convert';
import 'dart:io';

import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const _source = 'https://download.geonames.org/export/dump/';
const _cache = 'tool/places/.cache';
const _out = 'assets/places/places.tsv.gz';
const _maxBytes = 8 * 1024 * 1024;

Future<void> main() async {
  tz.initializeTimeZones();
  await _download('cities1000.zip', unzipTo: 'cities1000.txt');
  await _download('admin1CodesASCII.txt');
  await _download('countryInfo.txt');
  await _download('alternateNamesV2.zip', unzipTo: 'alternateNamesV2.txt');

  final cities = _readCities();
  final countries = _readCountries();
  final regions = _readRegions();
  final arabic = await _readArabicNames({
    ...cities.map((city) => city.id),
    ...countries.values.map((country) => country.id),
    ...regions.values.map((region) => region.id),
  });

  final zones = cities.map((city) => city.zone).toSet().toList()..sort();
  final unknownZones = zones.where((zone) => !tz.timeZoneDatabase.locations.containsKey(zone));
  if (unknownZones.isNotEmpty) _fail('zones missing from package:timezone: $unknownZones');
  final zoneIndex = {for (var i = 0; i < zones.length; i++) zones[i]: i};

  final missingCountries = cities
      .map((city) => city.country)
      .toSet()
      .difference(countries.keys.toSet());
  if (missingCountries.isNotEmpty) {
    _fail('places in countries not in countryInfo: $missingCountries');
  }

  /// search stops early because the biggest places come first
  cities.sort((a, b) {
    final byPopulation = b.population.compareTo(a.population);
    return byPopulation != 0 ? byPopulation : a.id.compareTo(b.id);
  });

  final date = File('$_cache/cities1000.zip').lastModifiedSync().toIso8601String().substring(0, 10);
  final out = StringBuffer()
    ..writeln('#geonames $date CC BY 4.0')
    ..writeln('#zones');
  zones.forEach(out.writeln);
  out.writeln('#countries');
  for (final MapEntry(key: code, value: country) in countries.entries) {
    out.writeln('$code\t${country.name}\t${arabic[country.id] ?? ''}');
  }
  out.writeln('#regions');
  for (final MapEntry(key: code, value: region) in regions.entries) {
    out.writeln('$code\t${region.name}\t${arabic[region.id] ?? ''}');
  }
  out.writeln('#places');
  for (final city in cities) {
    out.writeln(
      [
        city.name,
        if (city.ascii == city.name) '' else city.ascii,
        arabic[city.id] ?? '',
        city.country,
        city.admin1,
        (city.latitude * 1e4).round(),
        (city.longitude * 1e4).round(),
        city.population,
        zoneIndex[city.zone],
      ].join('\t'),
    );
  }

  final bytes = gzip.encode(utf8.encode(out.toString()));
  if (bytes.length > _maxBytes) _fail('${bytes.length} bytes is above the 8 MB limit (SC-008)');
  File(_out)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);
  final withArabic = cities.where((city) => arabic.containsKey(city.id)).length;
  stdout.writeln(
    'Wrote $_out: ${cities.length} places ($withArabic with an arabic name), '
    '${zones.length} zones, ${(bytes.length / 1024 / 1024).toStringAsFixed(2)} MB.',
  );
}

class _City {
  _City(
    this.id,
    this.name,
    this.ascii,
    this.latitude,
    this.longitude,
    this.country,
    this.admin1,
    this.population,
    this.zone,
  );
  final int id;
  final String name;
  final String ascii;
  final double latitude;
  final double longitude;
  final String country;
  final String admin1;
  final int population;
  final String zone;
}

typedef _Named = ({int id, String name});

Future<void> _download(String file, {String? unzipTo}) async {
  Directory(_cache).createSync(recursive: true);
  if (!File('$_cache/$file').existsSync()) {
    stdout.writeln('Downloading $file');
    await _run('curl', ['-fL', '--retry', '3', '-o', '$_cache/$file', '$_source$file']);
  }
  if (unzipTo != null && !File('$_cache/$unzipTo').existsSync()) {
    await _run('unzip', ['-o', '$_cache/$file', unzipTo, '-d', _cache]);
  }
}

Future<void> _run(String command, List<String> args) async {
  final result = await Process.run(command, args);
  if (result.exitCode != 0) _fail('$command ${args.join(' ')}\n${result.stderr}');
}

List<_City> _readCities() {
  final cities = <_City>[];
  for (final (index, line) in File('$_cache/cities1000.txt').readAsLinesSync().indexed) {
    final columns = line.split('\t');
    if (columns.length != 19) {
      _fail('cities1000 line ${index + 1}: ${columns.length} columns, not 19');
    }
    final latitude = double.parse(columns[4]);
    final longitude = double.parse(columns[5]);
    final population = int.tryParse(columns[14]);
    if (population == null) _fail('cities1000 line ${index + 1}: no population');
    if (latitude.abs() > 90 || longitude.abs() > 180) {
      _fail('cities1000 line ${index + 1}: coordinates $latitude, $longitude out of range');
    }
    cities.add(
      _City(
        int.parse(columns[0]),
        columns[1],
        columns[2],
        latitude,
        longitude,
        columns[8],
        columns[10],
        population,
        columns[17],
      ),
    );
  }
  return cities;
}

Map<String, _Named> _readCountries() {
  final countries = <String, _Named>{};
  for (final line in File('$_cache/countryInfo.txt').readAsLinesSync()) {
    if (line.startsWith('#') || line.isEmpty) continue;
    final columns = line.split('\t');
    countries[columns[0]] = (id: int.parse(columns[16]), name: columns[4]);
  }
  return countries;
}

Map<String, _Named> _readRegions() {
  final regions = <String, _Named>{};
  for (final line in File('$_cache/admin1CodesASCII.txt').readAsLinesSync()) {
    final columns = line.split('\t');
    regions[columns[0]] = (id: int.parse(columns[3]), name: columns[1]);
  }
  return regions;
}

/// the plain alternatenames column has no language, so urdu and persian spellings would leak in
Future<Map<int, String>> _readArabicNames(Set<int> ids) async {
  final arabicScript = RegExp(r'[؀-ۿ]');
  final names = <int, String>{};
  final preferred = <int>{};
  final lines = File('$_cache/alternateNamesV2.txt')
      .openRead()
      .transform(utf8.decoder)
      .transform(const LineSplitter());
  await for (final line in lines) {
    final columns = line.split('\t');
    if (columns[2] != 'ar') continue;
    final id = int.parse(columns[1]);
    if (!ids.contains(id) || preferred.contains(id)) continue;
    final name = columns[3];
    final isPreferred = columns[4] == '1';
    final isColloquial = columns[6] == '1';
    final isHistoric = columns[7] == '1';
    if (isColloquial || isHistoric || !arabicScript.hasMatch(name)) continue;
    if (isPreferred) {
      names[id] = name;
      preferred.add(id);
    } else {
      names.putIfAbsent(id, () => name);
    }
  }
  return names;
}

Never _fail(String message) {
  stderr.writeln('build_places: $message');
  exit(1);
}
