import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/widgets.dart';

void main() {
  testWidgets('the label over the card, a divider between rows and none after the last', (
    tester,
  ) async {
    await pumpCoreWidget(
      tester,
      const GroupedSection(
        label: StringsManager.sectionPrayer,
        children: [
          NavRow(title: StringsManager.calculationMethod),
          NavRow(title: StringsManager.adhanAndReminders),
          NavRow(title: StringsManager.location),
        ],
      ),
    );
    expect(find.text('PRAYER'), findsOneWidget);
    expect(find.byType(Divider), findsNWidgets(2));
    expect(
      tester.getTopLeft(find.byType(Divider).last).dy,
      lessThan(tester.getTopLeft(find.text('Location')).dy),
    );
  });

  testWidgets('no label, only the card', (tester) async {
    await pumpCoreWidget(
      tester,
      const GroupedSection(children: [NavRow(title: StringsManager.hijriDateAdjustment)]),
    );
    expect(find.byType(Divider), findsNothing);
    expect(find.text('Hijri date adjustment'), findsOneWidget);
  });
}
