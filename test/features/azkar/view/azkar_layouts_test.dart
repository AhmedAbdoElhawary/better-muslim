import 'package:better_muslim/core/azkar/azkar_window.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/features/azkar/view/widgets/tasbih_counter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/azkar.dart';
import '../../../helpers/fonts.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';

/// every new page in each way the app is used: nothing overflows and every hit is 44 x 44
void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);
  setUp(recordPhone);

  const ways = [
    ('arabic', Locale('ar'), Brightness.dark, 1.0, false, Size(393, 852)),
    ('text scale 2.0', Locale('en'), Brightness.dark, 2.0, false, Size(393, 852)),
    ('light', Locale('en'), Brightness.light, 1.0, false, Size(393, 852)),
    ('reduce motion', Locale('en'), Brightness.dark, 1.0, true, Size(393, 852)),
    ('a tablet', Locale('en'), Brightness.dark, 1.0, false, Size(820, 1180)),
  ];

  final pages = {
    'azkar tab': Routes.azkar,
    'tasbih': Routes.tasbih,
    'evening set': Routes.azkarSet(AzkarSet.evening),
    'duas': Routes.duas,
    'a dua category': Routes.duaCategory('before-sleeping'),
  };

  for (final (way, locale, brightness, textScale, reduceMotion, size) in ways) {
    for (final MapEntry(key: page, value: path) in pages.entries) {
      testWidgets('$page, $way', (tester) async {
        final overrides = await designOverrides();
        if (path.startsWith(Routes.duas)) {
          await pumpDuas(
            tester,
            overrides,
            locale: locale,
            brightness: brightness,
            textScale: textScale,
            size: size,
          );
          if (path != Routes.duas) {
            containerOf(tester).read(routerProvider).push(path);
            await tester.pumpAndSettle();
          }
        } else {
          await pumpAzkar(
            tester,
            overrides,
            location: path,
            locale: locale,
            brightness: brightness,
            textScale: textScale,
            reduceMotion: reduceMotion,
            size: size,
          );
        }

        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await unmount(tester);
      });
    }
  }

  testWidgets('arabic tasbih: eastern digits, arabic chips, the ring not mirrored', (tester) async {
    await pumpAzkar(
      tester,
      await designOverrides(),
      location: Routes.tasbih,
      locale: const Locale('ar'),
    );

    expect(tester.widget<TasbihCounter>(find.byType(TasbihCounter)).label, '١٦');
    expect(find.text('سبحان الله'), findsOneWidget);
    expect(find.text('SubhanAllah'), findsNothing);
    expect(find.text('Glory be to Allah'), findsNothing);
    final ring = find.descendant(
      of: find.byType(TasbihCounter),
      matching: find.byType(Directionality),
    );
    expect(tester.widget<Directionality>(ring.first).textDirection, TextDirection.ltr);
    await unmount(tester);
  });
}
