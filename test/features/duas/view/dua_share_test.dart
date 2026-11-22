import 'package:better_muslim/core/widgets/segmented.dart';
import 'package:better_muslim/core/widgets/share/share_frame.dart';
import 'package:better_muslim/core/widgets/share/share_options.dart';
import 'package:better_muslim/core/widgets/share/share_sheet.dart';
import 'package:better_muslim/features/duas/view/widgets/dua_card.dart';
import 'package:better_muslim/features/duas/view/widgets/dua_share.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/azkar.dart';
import '../../../helpers/fonts.dart';
import '../../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);
  setUp(recordPhone);

  Future<void> openShare(WidgetTester tester, {double textScale = 1}) async {
    await pumpDuas(tester, await designOverrides(), textScale: textScale);
    final share = find.descendant(of: find.byType(DuaCard), matching: find.text('Share')).first;
    await tester.ensureVisible(share);
    await tester.pumpAndSettle();
    await tester.tap(share);
    await tester.pumpAndSettle();
  }

  testWidgets('share opens the core sheet with the dua, the arch is an ornament here', (
    tester,
  ) async {
    await openShare(tester);
    expect(find.text('Share dua'), findsOneWidget);
    expect(tester.widget<ShareSheet>(find.byType(ShareSheet)).content, isA<DuaShare>());

    await tester.ensureVisible(find.text('Ornament'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ornament'));
    await tester.pumpAndSettle();
    expect(tester.widget<Segmented<ShareOrnament>>(find.byType(Segmented<ShareOrnament>)).values, [
      ShareOrnament.khatam,
      ShareOrnament.starCross,
      ShareOrnament.arch,
    ]);
    await unmount(tester);
  });

  testWidgets('text scale 2.0 leaves the card as it is', (tester) async {
    await openShare(tester);
    final card = tester.getSize(find.byType(ShareFrame));
    final layout = tester.widget<ShareFrame>(find.byType(ShareFrame)).size;
    await unmount(tester);

    await openShare(tester, textScale: 2);
    expect(tester.getSize(find.byType(ShareFrame)), card);
    expect(tester.widget<ShareFrame>(find.byType(ShareFrame)).size, layout);
    await unmount(tester);
  });
}
