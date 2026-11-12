import 'dart:ui' show Tristate;

import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/segmented.dart';
import 'package:better_muslim/core/widgets/sliding_selection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/widgets.dart';

void main() {
  late List<String> haptics;
  setUp(() => haptics = recordHaptics());

  String label(PrayerSound sound) => switch (sound) {
    PrayerSound.adhan => StringsManager.soundAdhan,
    PrayerSound.tone => StringsManager.soundTone,
    PrayerSound.silent => StringsManager.soundSilent,
  };

  for (final small in [false, true]) {
    testWidgets('${small ? 'small' : 'full width'}: a tap calls back once with the haptic, '
        'every segment takes 44 pt', (tester) async {
      final changes = <PrayerSound>[];
      await pumpCoreWidget(
        tester,
        Center(
          child: Segmented(
            values: PrayerSound.values,
            selected: PrayerSound.adhan,
            labelOf: label,
            small: small,
            onChanged: changes.add,
          ),
        ),
      );
      await tester.tap(find.text('Tone'));
      await tester.tap(find.text('Adhan'));
      expect(changes, [PrayerSound.tone]);
      expect(haptics, ['HapticFeedbackType.selectionClick']);
      for (final text in ['Adhan', 'Tone', 'Silent']) {
        final hit = find.ancestor(of: find.text(text), matching: find.byType(GestureDetector));
        expect(tester.getSize(hit.first).height, greaterThanOrEqualTo(44), reason: text);
      }
      final selected = tester.getSemantics(
        find.ancestor(of: find.text('Adhan'), matching: find.byType(Semantics)).first,
      );
      expect(selected.flagsCollection.isSelected, isNot(Tristate.isFalse));
    });
  }

  Future<ValueNotifier<(PrayerSound, Set<PrayerSound>)>> pumpEmpty(
    WidgetTester tester,
    List<PrayerSound> changes, {
    Locale locale = const Locale('en'),
  }) async {
    final state = ValueNotifier((PrayerSound.adhan, {PrayerSound.silent}));
    await pumpCoreWidget(
      tester,
      ValueListenableBuilder(
        valueListenable: state,
        builder: (context, value, _) => Segmented(
          values: PrayerSound.values,
          selected: value.$1,
          labelOf: label,
          empty: value.$2,
          onChanged: changes.add,
        ),
      ),
      locale: locale,
    );
    return state;
  }

  ThemeEnum? colorOf(WidgetTester tester, String text) => tester
      .widget<RegularText>(find.ancestor(of: find.text(text), matching: find.byType(RegularText)))
      .color;

  testWidgets('the picked highlight slides through SlidingSelection', (tester) async {
    final changes = <PrayerSound>[];
    final state = await pumpEmpty(tester, changes);
    expect(find.byType(SlidingSelection), findsOneWidget);
    state.value = (PrayerSound.tone, {});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets('an empty segment is text2 with a close icon after it, also when picked, and still '
      'calls back', (tester) async {
    final changes = <PrayerSound>[];
    final state = await pumpEmpty(tester, changes);
    expect(colorOf(tester, 'Silent'), ThemeEnum.text2);
    expect(colorOf(tester, 'Tone'), ThemeEnum.text);
    expect(find.byType(BmIcon), findsOneWidget);
    expect(
      tester.getCenter(find.byType(BmIcon)).dx,
      greaterThan(tester.getCenter(find.text('Silent')).dx),
    );

    await tester.tap(find.text('Silent'));
    expect(changes, [PrayerSound.silent]);

    state.value = (PrayerSound.silent, {PrayerSound.silent});
    await tester.pumpAndSettle();
    expect(colorOf(tester, 'Silent'), ThemeEnum.text2);
    expect(find.byType(BmIcon), findsOneWidget);
  });

  testWidgets('in arabic the close icon sits after the label, on its left', (tester) async {
    await pumpEmpty(tester, [], locale: const Locale('ar'));
    final icon = tester.getCenter(find.byType(BmIcon)).dx;
    final text = find.ancestor(of: find.byType(BmIcon), matching: find.byType(Row)).first;
    expect(icon, lessThan(tester.getCenter(text).dx));
  });

  testWidgets('a change between empty and full animates', (tester) async {
    final state = await pumpEmpty(tester, []);
    state.value = (PrayerSound.adhan, {});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('Silent'), findsNWidgets(2));
    await tester.pumpAndSettle();
    expect(find.text('Silent'), findsOneWidget);
    expect(find.byType(BmIcon), findsNothing);
  });
}
