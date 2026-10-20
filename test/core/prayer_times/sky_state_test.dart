import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/sky_state.dart';
import 'package:better_muslim/core/resources/design/bm_sky.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each period has its sky state, no period is the theme base', () {
    expect(Period.values.map(skyState), [
      BmSkyState.fajr,
      BmSkyState.sunrise,
      BmSkyState.dhuhr,
      BmSkyState.asr,
      BmSkyState.maghrib,
      BmSkyState.isha,
    ]);
    expect(skyState(null), isNull);
  });

  test('stars only on the fajr, maghrib and isha skies, always on the theme base', () {
    expect(BmSkyState.values.where(starsOn), [
      BmSkyState.fajr,
      BmSkyState.maghrib,
      BmSkyState.isha,
    ]);
    expect(starsOn(null), isTrue);
  });
}
