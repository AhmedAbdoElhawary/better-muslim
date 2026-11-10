import 'package:better_muslim/core/network/download.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart' show BmIconName;
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/share/share_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:better_muslim/features/quran/presentation/providers/page_providers.dart';
import 'package:better_muslim/features/quran/presentation/providers/tafsir_providers.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/ayah_share.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/tafsir_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 4.30, the ayahs as a still image on a brand background (FR-041, FR-015)
Future<void> showAyahShare(BuildContext context, List<AyahKey> keys) =>
    showBmSheet(context, builder: (_) => _AyahShareSheet(keys));

class _AyahShareSheet extends ConsumerStatefulWidget {
  const _AyahShareSheet(this.keys);

  final List<AyahKey> keys;

  @override
  ConsumerState<_AyahShareSheet> createState() => _AyahShareSheetState();
}

class _AyahShareSheetState extends ConsumerState<_AyahShareSheet> {
  /// null is the language's own, translation in english and al-muyassar in arabic
  ShareTextSource? _source;

  /// a tafsir not on the phone downloads first, the card keeps the old text until then
  Future<void> _pick(ShareTextSource source) async {
    if (source.tafsir case final tafsir?) {
      try {
        await ref.read(tafsirStatusProvider(tafsir).notifier).download();
      } on DownloadException catch (error) {
        if (!mounted || error.failure == DownloadFailure.cancelled) return;
        showToast(
          context,
          error.failure == DownloadFailure.offline
              ? StringsManager.needsInternetOnce
              : StringsManager.downloadFailed,
          icon: BmIconName.quran,
        );
        return;
      }
    }
    if (mounted) setState(() => _source = source);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final source = _source ?? (isArabic ? ShareTextSource.muyassar : ShareTextSource.translation);
    final assets = ref.watch(quranAssetsProvider).value;
    final arabic = {for (final key in widget.keys) key: ref.watch(ayahTextProvider(key)).value};
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    if (assets == null || arabic.values.contains(null)) return const SizedBox.shrink();

    /// the card's translation is english, an arabic one picked has its own chip or none
    final shown = shownTranslation(context, ref);
    final english = shown.arabic ? Translation.sahih : shown;
    String? text(AyahKey key) => switch (source) {
      ShareTextSource.none => null,
      ShareTextSource.translation =>
        ref.watch(translationProvider((english, key.surah))).value?.elementAtOrNull(key.ayah - 1),
      ShareTextSource.muyassar =>
        ref.watch(surahTextProvider(key.surah)).value?.tafsir[key.ayah - 1],
      ShareTextSource.ibnKathir ||
      ShareTextSource.saadi => ref.watch(tafsirTextProvider((source.tafsir!, key))).value,
    };
    return ShareSheet(
      content: AyahShare(
        arabic: arabic.cast(),
        texts: {for (final key in widget.keys) key: ?text(key)},
        source: source,
        surahs: {for (final key in widget.keys) key.surah: assets.surah(key.surah)},
        digits: digits,
      ),
      rows: [_TextPicker(selected: source, onPick: _pick)],
    );
  }
}

/// ayah only, the translation and the three tafsirs, one not on the phone marked (FR-023)
class _TextPicker extends ConsumerWidget {
  const _TextPicker({required this.selected, required this.onPick});

  final ShareTextSource selected;
  final ValueChanged<ShareTextSource> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (i, source) in ShareTextSource.values.indexed) ...[
            if (i == 0) const RSizedBox.horizontal(SpaceManager.s4),
            if (i > 0) const RSizedBox.horizontal(SpaceManager.s2),
            TafsirChip(
              source.label,
              selected: source == selected,
              status: switch (source.tafsir) {
                final tafsir? => ref.watch(tafsirStatusProvider(tafsir)),
                null => (ready: true, downloading: false, progress: null),
              },
              onTap: () => onPick(source),
            ),
            if (i == ShareTextSource.values.length - 1) const RSizedBox.horizontal(SpaceManager.s4),
          ],
        ],
      ),
    );
  }
}
