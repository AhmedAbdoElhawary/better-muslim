import 'package:better_muslim/core/settings/quran.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("follow sky is night in the app's dark mode and paper in its light mode", () {
    expect(PageColor.followSky.resolve(dark: true), PageColor.night);
    expect(PageColor.followSky.resolve(dark: false), PageColor.paper);
  });

  test('a picked paper, cream or night is kept in either mode', () {
    for (final picked in [PageColor.paper, PageColor.cream, PageColor.night]) {
      expect(picked.resolve(dark: true), picked);
      expect(picked.resolve(dark: false), picked);
    }
  });
}
