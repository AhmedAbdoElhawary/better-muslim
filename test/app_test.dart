import 'package:better_muslim/core/app/app.dart';
import 'package:better_muslim/features/home/view/home_page.dart';
import 'package:better_muslim/features/prayer/presentation/view/prayer_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app starts on home', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(PrayerPage), findsNothing);
  });

  testWidgets('arabic shows the arabic strings', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ar')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.text('الرئيسية'), findsNWidgets(2));
  });

  testWidgets('tapping a tab shows its page and hides the old one', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Prayer'));
    await tester.pumpAndSettle();

    expect(find.byType(PrayerPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
  });
}
