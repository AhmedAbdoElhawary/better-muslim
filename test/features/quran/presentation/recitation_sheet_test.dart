import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mini_player.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/recitation_sheet.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/more.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';
import '../../../helpers/quran.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);
  setUp(mockSystemChannel);

  Finder inSheet(Finder matching) =>
      find.descendant(of: find.byType(RecitationSheet), matching: matching);

  Finder labelled(String label) =>
      inSheet(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == label));

  Future<FakeRecitation> opened(WidgetTester tester, {double textScale = 1}) async {
    final recitation = FakeRecitation();
    await pumpReciting(tester, recitation, textScale: textScale);
    await recitation.play(const AyahKey(1, 3), to: const AyahKey(1, 7));
    recitation.emit(
      recitation.current.copyWith(
        position: const Duration(seconds: 12),
        duration: const Duration(seconds: 40),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(MiniPlayer), matching: find.byType(PlayingTitle)),
    );
    await tester.pumpAndSettle();
    return recitation;
  }

  /// opens a row's picker and reads its choices
  Future<void> expectChoices(WidgetTester tester, String row, List<String> choices) async {
    await tester.tap(inSheet(find.text(row)));
    await tester.pumpAndSettle();
    for (final choice in choices) {
      expect(find.text(choice), findsWidgets, reason: '$row: $choice');
    }
    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the reciter, where it is and the time', (tester) async {
    final recitation = await opened(tester);

    for (final text in [
      'Mishary Rashid Alafasy',
      'Murattal · Hafs',
      'Al-Fatiha · Ayah 3 of 7',
      '0:12 / 0:40',
      'Repeat each ayah',
      'Range',
      'Ayah 3 – 7',
      'Pause between ayahs',
      'Sleep timer',
    ]) {
      expect(inSheet(find.text(text)), findsOneWidget, reason: text);
    }
    expect(inSheet(find.text('Murattal · Hafs · downloaded')), findsNothing);

    recitation.emit(recitation.current.copyWith(surahReady: true));
    await tester.pumpAndSettle();
    expect(inSheet(find.text('Murattal · Hafs · downloaded')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the rows hold their choices', (tester) async {
    await opened(tester);

    await expectChoices(tester, 'Repeat each ayah', [
      'Off',
      '2 times',
      '3 times',
      '5 times',
      '10 times',
    ]);
    await expectChoices(tester, 'Pause between ayahs', ['Off', '1 s', '2 s', '3 s', '5 s']);
    await expectChoices(tester, 'Sleep timer', [
      'Off',
      '5 min',
      '10 min',
      '15 min',
      '30 min',
      '60 min',
      'End of surah',
    ]);
    await unmount(tester);
  });

  testWidgets('the reciter opens a list of five, the pick is saved and plays on', (tester) async {
    final recitation = await opened(tester);

    await tester.tap(inSheet(find.text('Mishary Rashid Alafasy')));
    await tester.pumpAndSettle();
    for (final name in [
      'Mishary Rashid Alafasy',
      'Mahmoud Khalil Al-Husary',
      'Abdul Basit Abdul Samad (Murattal)',
      'Mohamed Siddiq Al-Minshawi (Murattal)',
      'Maher Al-Muaiqly',
    ]) {
      expect(find.text(name), findsWidgets, reason: name);
    }
    await tester.tap(find.text('Mahmoud Khalil Al-Husary'));
    await tester.pumpAndSettle();

    expect(containerOf(tester).read(settingsProvider).value?.reciter, Reciter.husary);
    expect(recitation.calls.last, 'reciter husary');
    expect(inSheet(find.text('Mahmoud Khalil Al-Husary')), findsOneWidget);
    expect(inSheet(find.text('MH')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('download offline shows the offline message and can be tapped again', (tester) async {
    await opened(tester);

    await tester.tap(labelled('Download surah'));

    /// the folder is made on a real clock, the oil drop never settles while it waits
    for (var i = 0; i < 5; i++) {
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    }
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Connect to the internet to download this recitation.'), findsOneWidget);
    expect(labelled('Download surah'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a picked repeat is saved and reaches the recitation', (tester) async {
    final recitation = await opened(tester);

    await tester.tap(inSheet(find.text('Repeat each ayah')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3 times'));
    await tester.pumpAndSettle();

    expect(containerOf(tester).read(settingsProvider).value?.reciteRepeat, 3);
    expect(recitation.calls.last, 'repeat 3');
    await unmount(tester);
  });

  testWidgets('speed goes from .75 to 1.5', (tester) async {
    final recitation = await opened(tester);

    for (final speed in [1.25, 1.5, .75, 1.0]) {
      await tester.tap(labelled('Speed'));
      await tester.pumpAndSettle();
      expect(recitation.current.speed, speed);
    }
    await unmount(tester);
  });

  testWidgets('holds at text scale 2.0', (tester) async {
    await opened(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    expect(inSheet(find.text('Mishary Rashid Alafasy')), findsOneWidget);
    await unmount(tester);
  });
}
