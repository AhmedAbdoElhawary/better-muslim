import 'package:better_muslim/core/audio/ui_sounds.dart';

/// plays nothing, remembers what it was asked
class FakeSoundOutput implements SoundOutput {
  final played = <String>[];

  /// false = the phone on silent or vibrate
  bool allowed = true;

  @override
  Future<bool> canPlay() async => allowed;

  @override
  Future<void> play(String asset) async => played.add(asset);
}
