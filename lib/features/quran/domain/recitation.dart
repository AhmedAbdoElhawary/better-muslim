import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/recitation_files.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:flutter/foundation.dart';

enum RecitationStatus { idle, loading, playing, paused }

/// off, after some minutes, or after the surah's last ayah. lives only for the session
@immutable
class SleepTimer {
  const SleepTimer.off() : after = null, endOfSurah = false;
  const SleepTimer.after(Duration this.after) : endOfSurah = false;
  const SleepTimer.endOfSurah() : after = null, endOfSurah = true;

  final Duration? after;
  final bool endOfSurah;

  bool get off => after == null && !endOfSurah;

  static const choices = [
    SleepTimer.off(),
    SleepTimer.after(Duration(minutes: 5)),
    SleepTimer.after(Duration(minutes: 10)),
    SleepTimer.after(Duration(minutes: 15)),
    SleepTimer.after(Duration(minutes: 30)),
    SleepTimer.after(Duration(minutes: 60)),
    SleepTimer.endOfSurah(),
  ];

  @override
  bool operator ==(Object other) =>
      other is SleepTimer && other.after == after && other.endOfSurah == endOfSurah;

  @override
  int get hashCode => Object.hash(after, endOfSurah);
}

const reciteSpeeds = [.75, 1.0, 1.25, 1.5];

/// in the repeat cycle after 10, each ayah once and the range again from its start
const surahLoop = 0;
const reciteRepeats = [1, 2, 3, 5, 10, surahLoop];
const recitePauses = [0, 1, 2, 3, 5, 10];

@immutable
class RecitationState {
  const RecitationState({
    this.status = RecitationStatus.idle,
    this.reciter = Reciter.alafasy,
    this.ayah,
    this.from,
    this.to,
    this.repeat = 1,
    this.pause = Duration.zero,
    this.speed = 1,
    this.sleep = const SleepTimer.off(),
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.surahReady = false,
    this.failure,
  });

  final RecitationStatus status;
  final Reciter reciter;

  /// the playing item, ayah 0 is the surah's bismillah
  final AyahKey? ayah;
  final AyahKey? from;
  final AyahKey? to;
  final int repeat;
  final Duration pause;
  final double speed;
  final SleepTimer sleep;
  final Duration position;
  final Duration duration;

  /// every file of the playing surah is on the phone, 4.25 says "downloaded"
  final bool surahReady;

  /// why the last play stopped, set with idle
  final RecitationFailure? failure;

  bool get active => status != RecitationStatus.idle;

  RecitationState copyWith({
    RecitationStatus? status,
    Reciter? reciter,
    AyahKey? ayah,
    AyahKey? from,
    AyahKey? to,
    int? repeat,
    Duration? pause,
    double? speed,
    SleepTimer? sleep,
    Duration? position,
    Duration? duration,
    bool? surahReady,
    RecitationFailure? failure,
  }) => RecitationState(
    status: status ?? this.status,
    reciter: reciter ?? this.reciter,
    ayah: ayah ?? this.ayah,
    from: from ?? this.from,
    to: to ?? this.to,
    repeat: repeat ?? this.repeat,
    pause: pause ?? this.pause,
    speed: speed ?? this.speed,
    sleep: sleep ?? this.sleep,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    surahReady: surahReady ?? this.surahReady,

    /// a failure is only ever the latest one
    failure: failure,
  );
}

/// the media notification's texts, in the app's language and digits
typedef MediaText = ({
  String Function(AyahKey ayah) title,
  String Function(Reciter reciter) artist,
});

/// contracts/recitation.md. the tests use a fake, only AudioServiceRecitation touches the phone
abstract class Recitation {
  RecitationState get current;
  Stream<RecitationState> get state;

  /// from and to in one surah
  Future<void> play(AyahKey from, {required AyahKey to, MediaText? media});
  Future<void> pause();
  Future<void> resume();
  Future<void> next();
  Future<void> previous();

  /// ±10 s through the audio, into the next or previous ayah past either end
  Future<void> seekBy(Duration by);

  /// the ayah's first play in the range, from the bar
  Future<void> seekToAyah(AyahKey ayah);
  Future<void> setSpeed(double speed);
  Future<void> setRepeat(int times);
  Future<void> setPause(Duration gap);

  /// while playing it goes on from the same ayah in the new voice
  Future<void> setReciter(Reciter reciter);
  Future<void> setSleep(SleepTimer timer);
  Future<void> stop();
}

/// the playlist: the bismillah first when the range starts a surah other than 1 and 9, then each
/// ayah as many times as repeat says, so repeats stay gapless
List<AyahKey> recitationQueue(AyahKey from, AyahKey to, {int repeat = 1}) => [
  if (from.ayah == 1 && from.surah != 1 && from.surah != 9) AyahKey(from.surah, 0),
  for (var ayah = from.ayah; ayah <= to.ayah; ayah++)
    for (var i = 0; i < (repeat == surahLoop ? 1 : repeat); i++) AyahKey(from.surah, ayah),
];

/// surah loop plays the range again when it ends, end of surah still stops it there
bool startsAgain(int repeat, SleepTimer sleep) => repeat == surahLoop && !sleep.endOfSurah;

/// every file a downloaded surah needs, its bismillah first
List<AyahKey> surahFiles(int surah, int ayahs) => [
  if (surah != 1 && surah != 9) const AyahKey(1, 1),
  for (var ayah = 1; ayah <= ayahs; ayah++) AyahKey(surah, ayah),
];

/// the pause between ayahs only, never inside a repeat
bool pausesBefore(List<AyahKey> queue, int index) =>
    index > 0 && index < queue.length && queue[index] != queue[index - 1];

/// end of surah stops after the surah's last item
bool sleepsAfter(List<AyahKey> queue, int index, SleepTimer sleep) =>
    sleep.endOfSurah && (index == queue.length - 1 || queue[index + 1].surah != queue[index].surah);

/// the first item of the ayah after or before the playing one, null past the range
int? nextAyahIndex(List<AyahKey> queue, int index) {
  for (var i = index + 1; i < queue.length; i++) {
    if (queue[i] != queue[index]) return i;
  }
  return null;
}

int? previousAyahIndex(List<AyahKey> queue, int index) {
  final start = queue.indexOf(queue[index]);
  if (start == 0) return null;
  return queue.indexOf(queue[start - 1]);
}

/// where a jump of by lands from position in the item at index, crossing into the next or
/// previous items by what is left over. the first item stops at its start, null runs past the end
Future<({int index, Duration position})?> seekAcross(
  List<AyahKey> queue,
  int index,
  Duration position,
  Duration by,
  Future<Duration> Function(int index) length,
) async {
  var at = index;
  var target = position + by;
  while (target >= await length(at)) {
    target -= await length(at);
    if (++at >= queue.length) return null;
  }
  while (target < Duration.zero) {
    if (at == 0) return (index: 0, position: Duration.zero);
    target += await length(--at);
  }
  return (index: at, position: target);
}

/// the ayah under a drag along the bar, fraction 0 at the range's start and 1 at its end
/// the ayah whose stretch of the bar holds the finger, the same stretches the fill uses
int dragAyah(double fraction, {required AyahKey from, required AyahKey to}) {
  final count = to.ayah - from.ayah + 1;
  return from.ayah + ((fraction * count).ceil() - 1).clamp(0, count - 1);
}

/// how much of the range is played with this ayah, the bismillah reads as the first
double rangeProgress(AyahKey playing, {required AyahKey from, required AyahKey to}) =>
    ((readAyah(playing).ayah - from.ayah + 1) / (to.ayah - from.ayah + 1)).clamp(0.0, 1.0);

/// following stays on while the page shown holds the playing ayah
bool following({required int shownPage, required int playingPage}) => shownPage == playingPage;

/// last read never points at the bismillah
AyahKey readAyah(AyahKey playing) => playing.ayah == 0 ? AyahKey(playing.surah, 1) : playing;

/// the design scenario and the tests that never play
class IdleRecitation implements Recitation {
  const IdleRecitation();

  @override
  RecitationState get current => const RecitationState();

  @override
  Stream<RecitationState> get state => const Stream.empty();

  @override
  Future<void> play(AyahKey from, {required AyahKey to, MediaText? media}) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> next() async {}

  @override
  Future<void> previous() async {}

  @override
  Future<void> seekBy(Duration by) async {}

  @override
  Future<void> seekToAyah(AyahKey ayah) async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> setRepeat(int times) async {}

  @override
  Future<void> setPause(Duration gap) async {}

  @override
  Future<void> setReciter(Reciter reciter) async {}

  @override
  Future<void> setSleep(SleepTimer timer) async {}

  @override
  Future<void> stop() async {}
}
