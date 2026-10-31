import 'package:better_muslim/core/audio/audio_use.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/recitation_files.dart';
import 'package:better_muslim/features/quran/domain/recitation.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mini_player.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mushaf_page_view.dart';
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

  Finder inPlayer(Finder matching) =>
      find.descendant(of: find.byType(MiniPlayer), matching: matching);

  Finder labelled(String label) =>
      inPlayer(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == label));

  Future<FakeRecitation> playing(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    final recitation = FakeRecitation();
    await pumpReciting(tester, recitation, locale: locale);
    await recitation.play(const AyahKey(1, 3), to: const AyahKey(1, 7));
    await tester.pumpAndSettle();
    return recitation;
  }

  testWidgets('shows the playing ayah, the reciter and the speed', (tester) async {
    await playing(tester);

    expect(inPlayer(find.text('Al-Fatiha · Ayah 3')), findsOneWidget);
    expect(inPlayer(find.text('Mishary Alafasy · 1.0×')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('play or pause and next reach the recitation', (tester) async {
    final recitation = await playing(tester);

    await tester.tap(labelled('Pause'));
    await tester.pumpAndSettle();
    expect(recitation.calls, contains('pause'));
    expect(labelled('Play'), findsOneWidget);

    await tester.tap(labelled('Play'));
    await tester.tap(labelled('Next ayah'));
    await tester.pumpAndSettle();
    expect(recitation.calls, containsAllInOrder(['resume', 'next']));
    expect(inPlayer(find.text('Al-Fatiha · Ayah 4')), findsOneWidget);

    await tester.tap(labelled('Stop'));
    await tester.pumpAndSettle();
    expect(recitation.calls.last, 'stop');
    await unmount(tester);
  });

  testWidgets('the controls stay left to right in arabic', (tester) async {
    await playing(tester, locale: const Locale('ar'));

    final play = tester.getCenter(inPlayer(find.byType(PlayButton))).dx;
    final title = tester.getCenter(inPlayer(find.byType(PlayingTitle))).dx;
    expect(play, lessThan(title));
    await unmount(tester);
  });

  testWidgets('the follow wash moves on the same frame as the ayah', (tester) async {
    final recitation = await playing(tester);
    RenderMushafPage page() => tester.allRenderObjects.whereType<RenderMushafPage>().firstWhere(
      (page) => page.washBounds(const AyahKey(1, 3)) != null,
    );
    expect(page().following, const AyahKey(1, 3));

    recitation.emit(recitation.current.copyWith(ayah: const AyahKey(1, 4)));

    /// the stream hands the event over before the next frame, like the player's index does
    await Future<void>.microtask(() {});
    expect(page().following, const AyahKey(1, 3));
    await tester.pump();
    expect(page().following, const AyahKey(1, 4));
    await unmount(tester);
  });

  testWidgets('the adhan pauses it', (tester) async {
    final recitation = await playing(tester);

    containerOf(tester).read(audioUseProvider.notifier).claim(AudioUse.adhan);
    await tester.pumpAndSettle();
    expect(recitation.calls.last, 'pause');
    expect(recitation.current.status, RecitationStatus.paused);
    await unmount(tester);
  });

  testWidgets('a dua pauses it and gives it back when done, the adhan never does', (tester) async {
    final recitation = await playing(tester);
    final use = containerOf(tester).read(audioUseProvider.notifier);

    use.claim(AudioUse.clip);
    await tester.pumpAndSettle();
    expect(recitation.calls.last, 'pause');

    use.release(AudioUse.clip);
    await tester.pumpAndSettle();
    expect(recitation.calls.last, 'resume');
    expect(recitation.current.status, RecitationStatus.playing);

    use.claim(AudioUse.adhan);
    await tester.pumpAndSettle();
    use.release(AudioUse.adhan);
    await tester.pumpAndSettle();
    expect(recitation.calls.last, 'pause');
    await unmount(tester);
  });

  testWidgets('an offline download says so', (tester) async {
    final recitation = await playing(tester);

    recitation.fail(RecitationFailure.offline);
    await tester.pumpAndSettle();
    expect(find.text('Connect to the internet to download this recitation.'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
    await unmount(tester);
  });

  testWidgets('a failed download offers try again from the same ayah', (tester) async {
    final recitation = await playing(tester);

    recitation.fail(RecitationFailure.failed);
    await tester.pumpAndSettle();
    expect(find.text("The recitation couldn't download."), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(recitation.calls.last, 'play 1:3 1:7');
    await unmount(tester);
  });
}
