import 'package:better_muslim/core/app/app.dart';
import 'package:better_muslim/features/home/view/home_page.dart';
import 'package:better_muslim/features/prayer/presentation/view/prayer_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/providers.dart';

void main() {
  testWidgets('app starts on home', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: testOverrides(), child: const App()));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(PrayerPage), findsNothing);
    await unmount(tester);
  });

  testWidgets('arabic shows the arabic strings', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ar')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(ProviderScope(overrides: testOverrides(), child: const App()));
    await tester.pumpAndSettle();

    expect(find.text('الرئيسية'), findsNWidgets(2));
    await unmount(tester);
  });

  testWidgets('tapping a tab shows its page and hides the old one', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: testOverrides(), child: const App()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Prayer'));
    await tester.pumpAndSettle();

    expect(find.byType(PrayerPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
    await unmount(tester);
  });
}
