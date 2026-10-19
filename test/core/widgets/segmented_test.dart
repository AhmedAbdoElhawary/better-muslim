import 'dart:ui' show Tristate;

import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/segmented.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
