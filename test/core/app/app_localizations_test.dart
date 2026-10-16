import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tr fills the placeholders by name, whatever their order', () {
    const strings = AppLocalizations({'untilPrayerAt': 'حتى {prayer} الساعة {time}'});

    expect(
      strings.tr('untilPrayerAt', {'time': '١٧:٥٦', 'prayer': 'المغرب'}),
      'حتى المغرب الساعة ١٧:٥٦',
    );
  });
}
