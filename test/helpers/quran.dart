import 'dart:async';

import 'package:better_muslim/core/app/app.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/features/quran/domain/recitation.dart';
import 'package:better_muslim/features/quran/presentation/providers/recitation_providers.dart';
import 'package:better_muslim/features/quran/presentation/recitation_boot.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'home.dart';
import 'prayer.dart';
import 'providers.dart';

/// plays nothing, records each call and moves its state the way the player would
class FakeRecitation implements Recitation {
  final calls = <String>[];
  final _states = StreamController<RecitationState>.broadcast();
  RecitationState _state = const RecitationState();

  @override
  RecitationState get current => _state;

  @override
  Stream<RecitationState> get state => _states.stream;

  void emit(RecitationState state) {
    _state = state;
    _states.add(state);
  }

  void fail(RecitationFailure failure) =>
      emit(_state.copyWith(status: RecitationStatus.idle, failure: failure));

  @override
  Future<void> play(AyahKey from, {required AyahKey to, MediaText? media}) async {
    calls.add('play $from $to');
    emit(_state.copyWith(status: RecitationStatus.playing, ayah: from, from: from, to: to));
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    if (_state.active) emit(_state.copyWith(status: RecitationStatus.paused));
  }

  @override
  Future<void> resume() async {
    calls.add('resume');
    if (_state.active) emit(_state.copyWith(status: RecitationStatus.playing));
  }

  @override
  Future<void> next() async {
    calls.add('next');
    final ayah = _state.ayah!;
    emit(_state.copyWith(ayah: AyahKey(ayah.surah, ayah.ayah + 1)));
  }

  @override
  Future<void> previous() async {
    calls.add('previous');
    final ayah = _state.ayah!;
    emit(_state.copyWith(ayah: AyahKey(ayah.surah, ayah.ayah - 1)));
  }

  @override
  Future<void> setSpeed(double speed) async {
    calls.add('speed $speed');
    emit(_state.copyWith(speed: speed));
  }

  @override
  Future<void> setRepeat(int times) async {
    calls.add('repeat $times');
    emit(_state.copyWith(repeat: times));
  }

  @override
  Future<void> setPause(Duration gap) async {
    calls.add('pause ${gap.inSeconds}');
    emit(_state.copyWith(pause: gap));
  }

  /// like the player, the same reciter again does nothing
  @override
  Future<void> setReciter(Reciter reciter) async {
    if (reciter == _state.reciter) return;
    calls.add('reciter ${reciter.name}');
    emit(_state.copyWith(reciter: reciter));
  }

  @override
  Future<void> setSleep(SleepTimer timer) async {
    calls.add('sleep');
    emit(_state.copyWith(sleep: timer));
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    emit(_state.copyWith(status: RecitationStatus.idle));
  }
}

/// the design scenario's app with the recitation's boot, the reader open on page
Future<void> pumpReciting(
  WidgetTester tester,
  FakeRecitation recitation, {
  int page = 1,
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  await pumpHome(
    tester,
    [...await designOverrides(), recitationProvider.overrideWithValue(recitation)],
    locale: locale,
    textScale: textScale,
    settle: false,
    app: const RecitationBoot(child: App()),
  );
  await tester.pump();
  containerOf(tester).read(routerProvider).push(Routes.quranPage(page));
  await tester.pumpAndSettle();
}
