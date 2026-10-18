import 'package:better_muslim/core/flavor/flavor_config.dart';
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
  ref.onDispose(player.dispose);
  return player;
});

final playbackProvider = StreamProvider<Playback>((ref) => ref.watch(adhanPlayerProvider).playback);
