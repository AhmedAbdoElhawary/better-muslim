import 'package:better_muslim/core/widgets/shell/nav_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../helpers/more.dart';
import '../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  setUp(mockSystemChannel);

  testWidgets('the shell keeps its own page', (tester) async {
    await pumpMore(tester, await designOverrides());
    final route = ModalRoute.of(tester.element(find.byType(NavBar)));
    expect(route, isNot(isA<MaterialRouteTransitionMixin>()));
    await unmount(tester);
  });
}
