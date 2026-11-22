/// one entry of the GeoNames place list, saved by value, never by its index
class Place {
  const Place({
    required this.name,
    required this.countryCode,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.population,
    required this.timeZone,
    this.nameAr,
    this.region,
    this.regionAr,
    this.countryAr,
  });

  final String name;
  final String? nameAr;
  final String? region;
  final String? regionAr;
  final String countryCode;
  final String country;
  final String? countryAr;
  final double latitude;
  final double longitude;
  final int population;
  final String timeZone;
}
