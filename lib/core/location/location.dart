import 'package:better_muslim/core/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;

final phoneZoneProvider = NotifierProvider<PhoneZone, String?>(PhoneZone.new);

/// the phone's IANA zone, read in bootstrap and again on resume (R11)
class PhoneZone extends Notifier<String?> {
  PhoneZone([this._initial]);

  final String? _initial;

  static Future<String> read() async => (await FlutterTimezone.getLocalTimezone()).identifier;

  @override
  String? build() => _initial;

  Future<void> refresh() async => state = await read();
}

/// null = no location yet, it is never made up (wrong prayer times are worse than none)
final locationProvider = Provider<Location?>((ref) {
  final saved = ref.watch(
    settingsProvider.select((settings) {
      final row = settings.value;
      final latitude = row?.latitude;
      final longitude = row?.longitude;
      if (row == null || latitude == null || longitude == null) return null;
      return (
        latitude: latitude,
        longitude: longitude,
        placeName: row.placeName,
        placeNameAr: row.placeNameAr,
        regionName: row.regionName,
        regionNameAr: row.regionNameAr,
        countryCode: row.countryCode,
        timeZone: row.timeZone,
        mode: row.locationMode ?? LocationMode.auto,
      );
    }),
  );
  if (saved == null) return null;
  final phoneZone = ref.watch(phoneZoneProvider);
  final usePhoneZone =
      saved.mode == LocationMode.auto &&
      phoneZone != null &&
      tz.timeZoneDatabase.locations.containsKey(phoneZone);
  final zone = usePhoneZone ? phoneZone : saved.timeZone;
  if (zone == null) return null;
  return Location(
    latitude: saved.latitude,
    longitude: saved.longitude,
    placeName: saved.placeName,
    placeNameAr: saved.placeNameAr,
    regionName: saved.regionName,
    regionNameAr: saved.regionNameAr,
    countryCode: saved.countryCode,
    zone: tz.getLocation(zone),
    mode: saved.mode,
  );
});

/// where times are computed for. auto uses the phone's zone, manual the place's own (FR-016)
class Location {
  const Location({
    required this.latitude,
    required this.longitude,
    required this.zone,
    required this.mode,
    this.placeName,
    this.placeNameAr,
    this.regionName,
    this.regionNameAr,
    this.countryCode,
  });

  final double latitude;
  final double longitude;
  final String? placeName;
  final String? placeNameAr;
  final String? regionName;
  final String? regionNameAr;
  final String? countryCode;
  final tz.Location zone;
  final LocationMode mode;
}
