import 'package:adhan_dart/adhan_dart.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';

/// stored by name, so reordering never changes saved data
enum PrayerMethod {
  ummAlQura,
  egyptian,
  dubai,
  qatar,
  kuwait,
  turkiye,
  singapore,
  karachi,
  tehran,
  northAmerica,
  muslimWorldLeague;

  /// the method the local mosques use (FR-010)
  static PrayerMethod forCountry(String? code) => switch (code) {
    'SA' => ummAlQura,
    'EG' => egyptian,
    'AE' => dubai,
    'QA' => qatar,
    'KW' => kuwait,
    'TR' => turkiye,
    'SG' || 'MY' || 'ID' => singapore,
    'PK' || 'IN' || 'BD' => karachi,
    'IR' => tehran,
    'US' || 'CA' => northAmerica,
    _ => muslimWorldLeague,
  };

  /// a new object each time, adhan mutates it
  CalculationParameters get parameters => switch (this) {
    ummAlQura => CalculationMethodParameters.ummAlQura(),
    egyptian => CalculationMethodParameters.egyptian(),
    dubai => CalculationMethodParameters.dubai(),
    qatar => CalculationMethodParameters.qatar(),
    kuwait => CalculationMethodParameters.kuwait(),
    turkiye => CalculationMethodParameters.turkiye(),
    singapore => CalculationMethodParameters.singapore(),
    karachi => CalculationMethodParameters.karachi(),
    tehran => CalculationMethodParameters.tehran(),
    northAmerica => CalculationMethodParameters.northAmerica(),
    muslimWorldLeague => CalculationMethodParameters.muslimWorldLeague(),
  };

  String get nameKey => switch (this) {
    ummAlQura => StringsManager.methodUmmAlQura,
    egyptian => StringsManager.methodEgyptian,
    dubai => StringsManager.methodDubai,
    qatar => StringsManager.methodQatar,
    kuwait => StringsManager.methodKuwait,
    turkiye => StringsManager.methodTurkiye,
    singapore => StringsManager.methodSingapore,
    karachi => StringsManager.methodKarachi,
    tehran => StringsManager.methodTehran,
    northAmerica => StringsManager.methodNorthAmerica,
    muslimWorldLeague => StringsManager.methodMuslimWorldLeague,
  };
}

enum AsrMethod {
  standard,
  hanafi;

  /// FR-011
  static AsrMethod forCountry(String? code) => switch (code) {
    'PK' || 'IN' || 'BD' => hanafi,
    _ => standard,
  };

  Madhab get madhab => switch (this) {
    standard => Madhab.shafi,
    hanafi => Madhab.hanafi,
  };

  String get nameKey => switch (this) {
    standard => StringsManager.asrStandard,
    hanafi => StringsManager.asrHanafi,
  };
}
