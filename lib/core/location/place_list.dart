import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:better_muslim/core/location/place.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// loaded only to name a new position or to search, dropped again when nothing listens
final placeListProvider = FutureProvider.autoDispose<PlaceList>((ref) => PlaceList.load());

/// the GeoNames list from assets/places/places.tsv.gz, biggest place first.
/// columns instead of 171k Place objects, a Place is made only for a result
class PlaceList {
  PlaceList._(
    this._zones,
    this._countryCodes,
    this._countryNames,
    this._countryNamesAr,
    this._regionNames,
    this._regionNamesAr,
    this._names,
    this._namesAr,
    this._countries,
    this._regions,
    this._latitudes,
    this._longitudes,
    this._populations,
    this._placeZones,
    this._searchKeys,
  );

  static Future<PlaceList> load() async {
    final data = await rootBundle.load('assets/places/places.tsv.gz');
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    return Isolate.run(() => _parse(bytes));
  }

  final List<String> _zones;
  final List<String> _countryCodes;
  final List<String> _countryNames;
  final List<String?> _countryNamesAr;
  final List<String> _regionNames;
  final List<String?> _regionNamesAr;
  final List<String> _names;
  final List<String?> _namesAr;
  final Uint16List _countries;

  /// -1 when the place has no region in the list
  final Int32List _regions;

  /// degrees ×1e4
  final Int32List _latitudes;
  final Int32List _longitudes;
  final Int32List _populations;
  final Uint16List _placeZones;

  /// lower-case ascii name and normalized arabic name, tab separated so a query can't span both
  final List<String> _searchKeys;

  int get length => _names.length;

  Place operator [](int index) {
    final country = _countries[index];
    final region = _regions[index];
    return Place(
      name: _names[index],
      nameAr: _namesAr[index],
      region: region < 0 ? null : _regionNames[region],
      regionAr: region < 0 ? null : _regionNamesAr[region],
      countryCode: _countryCodes[country],
      country: _countryNames[country],
      countryAr: _countryNamesAr[country],
      latitude: _latitudes[index] / 1e4,
      longitude: _longitudes[index] / 1e4,
      population: _populations[index],
      timeZone: _zones[_placeZones[index]],
    );
  }

  /// part of a name in english or arabic. big places come first, so a common name stops early
  List<Place> search(String query, {int limit = 30}) {
    final key = normalizeArabic(query.trim().toLowerCase());
    if (key.isEmpty) return const [];
    final results = <Place>[];
    for (var i = 0; i < length && results.length < limit; i++) {
      if (_searchKeys[i].contains(key)) results.add(this[i]);
    }
    return results;
  }

  /// equirectangular distance, plenty at the scale of the nearest town and quick over 171k places
  Place nearest(double latitude, double longitude) {
    final lat = (latitude * 1e4).round();
    final lng = (longitude * 1e4).round();
    final scale = cos(latitude * pi / 180);
    var best = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < length; i++) {
      final dy = (_latitudes[i] - lat).toDouble();
      var dx = (_longitudes[i] - lng).abs().toDouble();

      /// across the date line
      if (dx > 1800000) dx = 3600000 - dx;
      dx *= scale;
      final distance = dx * dx + dy * dy;
      if (distance < bestDistance) {
        best = i;
        bestDistance = distance;
      }
    }
    return this[best];
  }

  static PlaceList _parse(Uint8List bytes) {
    final lines = const LineSplitter().convert(utf8.decode(gzip.decode(bytes)));
    final zones = <String>[];
    final countryIndex = <String, int>{};
    final countryCodes = <String>[];
    final countryNames = <String>[];
    final countryNamesAr = <String?>[];
    final regionIndex = <String, int>{};
    final regionNames = <String>[];
    final regionNamesAr = <String?>[];

    var section = '';
    var start = 0;
    for (; start < lines.length; start++) {
      final line = lines[start];
      if (line.startsWith('#')) {
        section = line;
        if (section == '#places') break;
        continue;
      }
      final columns = line.split('\t');
      switch (section) {
        case '#zones':
          zones.add(line);
        case '#countries':
          countryIndex[columns[0]] = countryCodes.length;
          countryCodes.add(columns[0]);
          countryNames.add(columns[1]);
          countryNamesAr.add(_orNull(columns[2]));
        case '#regions':
          regionIndex[columns[0]] = regionNames.length;
          regionNames.add(columns[1]);
          regionNamesAr.add(_orNull(columns[2]));
      }
    }

    final rows = lines.sublist(start + 1);
    final count = rows.length;
    final names = List<String>.filled(count, '');
    final namesAr = List<String?>.filled(count, null);
    final searchKeys = List<String>.filled(count, '');
    final countries = Uint16List(count);
    final regions = Int32List(count);
    final latitudes = Int32List(count);
    final longitudes = Int32List(count);
    final populations = Int32List(count);
    final placeZones = Uint16List(count);
    for (var i = 0; i < count; i++) {
      final columns = rows[i].split('\t');
      final name = columns[0];
      final ascii = columns[1].isEmpty ? name : columns[1];
      final nameAr = _orNull(columns[2]);
      names[i] = name;
      namesAr[i] = nameAr;
      searchKeys[i] = '${ascii.toLowerCase()}\t${normalizeArabic(nameAr ?? '')}';
      countries[i] = countryIndex[columns[3]]!;
      regions[i] = regionIndex['${columns[3]}.${columns[4]}'] ?? -1;
      latitudes[i] = int.parse(columns[5]);
      longitudes[i] = int.parse(columns[6]);
      populations[i] = int.parse(columns[7]);
      placeZones[i] = int.parse(columns[8]);
    }

    return PlaceList._(
      zones,
      countryCodes,
      countryNames,
      countryNamesAr,
      regionNames,
      regionNamesAr,
      names,
      namesAr,
      countries,
      regions,
      latitudes,
      longitudes,
      populations,
      placeZones,
      searchKeys,
    );
  }

  static String? _orNull(String value) => value.isEmpty ? null : value;
}

/// so مكة, مكه and مَكَّة find the same place (FR-005)
String normalizeArabic(String text) => text
    .replaceAll(RegExp('[ً-ْٰـ]'), '')
    .replaceAll(RegExp('[أإآٱ]'), 'ا')
    .replaceAll('ة', 'ه')
    .replaceAll('ى', 'ي')
    .replaceAll('ؤ', 'و')
    .replaceAll('ئ', 'ي');
