import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:better_muslim/core/audio/audio_use.dart';
import 'package:better_muslim/core/quran/last_read.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/quran/domain/recitation.dart';
import 'package:better_muslim/features/quran/presentation/providers/recitation_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// what the recitation does wherever I am in the app: the saved choices, one voice at a time,
/// last read on the playing ayah and the notification's tap
class RecitationBoot extends ConsumerStatefulWidget {
  const RecitationBoot({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<RecitationBoot> createState() => _RecitationBootState();
}

class _RecitationBootState extends ConsumerState<RecitationBoot> {
  StreamSubscription<bool>? _clicks;

  /// paused by a clip, not by me
  var _resume = false;

  Recitation get _recitation => ref.read(recitationProvider);

  @override
  void initState() {
    super.initState();

    /// range and sleep last only for the session, the rest is saved
    ref.listenManual(
      settingsProvider.select((settings) {
        final row = settings.value;
        return row == null
            ? null
            : (row.reciteSpeed, row.reciteRepeat, row.recitePause, row.reciter);
      }),
      (previous, next) {
        if (next == null) return;
        final (speed, repeat, pause, reciter) = next;
        if (reciter != previous?.$4) _recitation.setReciter(reciter);
        if (speed != previous?.$1) _recitation.setSpeed(speed);
        if (repeat != previous?.$2) _recitation.setRepeat(repeat);
        if (pause != previous?.$3) _recitation.setPause(Duration(seconds: pause));
      },
      fireImmediately: true,
    );
    ref.listenManual(
      recitationStateProvider.select((state) => state.value?.status == RecitationStatus.playing),
      (_, playing) {
        final use = ref.read(audioUseProvider.notifier);
        playing ? use.claim(AudioUse.recitation) : use.release(AudioUse.recitation);
      },
    );

    /// the adhan's claim pauses it, it never comes back on its own (FR-028). a dua or a preview
    /// gives it back when it's done
    ref.listenManual(audioUseProvider, (previous, use) {
      switch (use) {
        case AudioUse.adhan:
          _resume = false;
          _recitation.pause();
        case AudioUse.clip when previous == AudioUse.recitation:
          _resume = true;
          _recitation.pause();
        case AudioUse.none when _resume:
          _resume = false;
          _recitation.resume();
        case AudioUse.recitation:
          _resume = false;
        case AudioUse.none || AudioUse.clip:
      }
    });
    ref.listenManual(playingAyahProvider, (_, ayah) async {
      if (ayah == null) return;
      final assets = await ref.read(quranAssetsProvider.future);
      final read = readAyah(ayah);
      await ref.read(saveLastReadProvider)(read, assets.pageOf(read));
    });
    _clicks = AudioService.notificationClicked.listen((clicked) async {
      final ayah = ref.read(playingAyahProvider);
      if (!clicked || ayah == null) return;
      final assets = await ref.read(quranAssetsProvider.future);
      ref.read(followingProvider.notifier).set(true);
      unawaited(ref.read(routerProvider).push(Routes.quranPage(assets.pageOf(readAyah(ayah)))));
    });
  }

  @override
  void dispose() {
    _clicks?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
