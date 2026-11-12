import 'package:better_muslim/core/widgets/glass.dart';
import 'package:better_muslim/core/widgets/shell/nav_bar.dart';
import 'package:better_muslim/features/more/view/widgets/about_section.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/more.dart';
import '../../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  setUp(mockSystemChannel);

  testWidgets('the tab scrolls under the glass bar and its last row ends above it', (tester) async {
    await pumpMore(tester, await designOverrides());
    expect(
      find.descendant(of: find.byType(NavBar), matching: find.byType(BackdropFilter)),
      findsOneWidget,
    );
    expect(find.descendant(of: find.byType(NavBar), matching: find.byType(Glass)), findsOneWidget);

    final bar = tester.getRect(find.byType(NavBar));
    final view = tester.getRect(find.byType(Scrollable).first);
    expect(view.bottom, greaterThan(bar.top), reason: 'the list runs under the bar');

    await tester.fling(find.byType(Scrollable).first, const Offset(0, -5000), 3000);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(AboutSection)).bottom, lessThanOrEqualTo(bar.top));
    await unmount(tester);
  });
}
