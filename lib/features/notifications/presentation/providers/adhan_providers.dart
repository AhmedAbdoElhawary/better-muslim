import 'package:better_muslim/core/audio/adhan_files.dart';
import 'package:better_muslim/core/audio/audio_use.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/settings/adhan_recording.dart';
import 'package:better_muslim/features/notifications/data/adhan_channel.dart';
import 'package:better_muslim/features/notifications/data/adhan_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adhanPlayerProvider = Provider<AdhanPlayer>((ref) {
  final AdhanPlayer player;
  if (ref.watch(flavorProvider.select((config) => config.isDesignScenario))) {
    player = FixedAdhanPlayer(
      position: const Duration(seconds: 42),
      duration: const Duration(minutes: 2, seconds: 56),
    );
  } else if (defaultTargetPlatform == TargetPlatform.android) {
    player = NativeAdhanPlayer(ref.watch(adhanChannelProvider));
  } else {
    player = JustAudioAdhanPlayer();
  }

  /// the players have no ref, so the claim is made here from what they play
  final claims = player.playback.listen((state) {
    final use = ref.read(audioUseProvider.notifier);
    state.playing && !state.ended ? use.claim(AudioUse.adhan) : use.release(AudioUse.adhan);
  });
  ref.onDispose(() {
    claims.cancel();
    player.dispose();
  });
  return player;
});

final playbackProvider = StreamProvider<Playback>((ref) => ref.watch(adhanPlayerProvider).playback);

/// progress is null while the size is unknown
typedef AdhanDownload = ({bool ready, bool downloading, double? progress});

final adhanDownloadProvider =
    NotifierProvider.family<AdhanDownloadNotifier, AdhanDownload, AdhanRecording>(
      AdhanDownloadNotifier.new,
    );

class AdhanDownloadNotifier extends Notifier<AdhanDownload> {
  AdhanDownloadNotifier(this.recording);

  final AdhanRecording recording;

  @override
  AdhanDownload build() =>
      (ready: AdhanFiles.isReady(recording), downloading: false, progress: null);

  /// throws a DownloadException, cancelled included
  Future<void> download() async {
    if (state.ready || state.downloading) return;
    state = (ready: false, downloading: true, progress: null);
    try {
      await AdhanFiles.download(
        recording,
        onProgress: (progress) => state = (ready: false, downloading: true, progress: progress),
      );
      state = (ready: true, downloading: false, progress: null);
    } on Object {
      state = (ready: false, downloading: false, progress: null);
      rethrow;
    }
  }

  void cancel() => AdhanFiles.cancel(recording);
}
