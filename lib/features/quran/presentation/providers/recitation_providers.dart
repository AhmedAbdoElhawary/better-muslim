import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/quran/domain/recitation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// the app's own run overrides it with AudioServiceRecitation, the design scenario never plays
final recitationProvider = Provider<Recitation>((ref) => const IdleRecitation());

final recitationStateProvider = StreamProvider<RecitationState>((ref) async* {
  final recitation = ref.watch(recitationProvider);
  yield recitation.current;
  yield* recitation.state;
});

/// the follow wash's item, null when nothing plays
final playingAyahProvider = Provider<AyahKey?>(
  (ref) => ref.watch(
    recitationStateProvider.select((state) {
      final value = state.value;
      return value != null && value.active ? value.ayah : null;
    }),
  ),
);

/// the reader turns the page with the recitation while true (FR-024)
final followingProvider = NotifierProvider<Following, bool>(Following.new);

class Following extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool on) => state = on;
}

/// from an ayah to the end of its surah or to, the media texts in the app's language and digits
Future<void> playFrom(BuildContext context, WidgetRef ref, AyahKey from, {AyahKey? to}) async {
  final assets = await ref.read(quranAssetsProvider.future);
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context);
  final language = Localizations.localeOf(context).languageCode;
  final digits = ref.read(settingsProvider).value?.digits ?? Digits.eastern;
  final surah = assets.surah(from.surah);
  ref.read(followingProvider.notifier).set(true);
  await ref
      .read(recitationProvider)
      .play(
        from,
        to: to ?? AyahKey(from.surah, surah.ayahs),
        media: (
          title: (ayah) => l10n.tr(StringsManager.quranAyahN, {
            'surah': language == 'ar' ? surah.ar : surah.en,
            'n': formatDigitsIn('${ayah.ayah}', language: language, digits: digits),
          }),
          artist: (reciter) => l10n.tr(reciter.label, const {}),
        ),
      );
}
