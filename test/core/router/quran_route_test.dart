import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a page and an ayah make the reader link, and the ayah reads back', () {
    expect(Routes.quranPage(1), '/quran/page/1');
    expect(Routes.quranPage(42, ayah: const AyahKey(2, 255)), '/quran/page/42?ayah=2%3A255');
    expect(
      AyahKey.tryParse(
        Uri.parse(Routes.quranPage(42, ayah: const AyahKey(2, 255))).queryParameters['ayah'],
      ),
      const AyahKey(2, 255),
    );
    expect(AyahKey.tryParse('2-255'), isNull);
    expect(AyahKey.tryParse(null), isNull);
  });
}
