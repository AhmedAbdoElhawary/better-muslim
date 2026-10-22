import 'dart:ui' as ui;

import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart' show BmIconName;
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/system/share.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/segmented.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/sheet_title.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart' show showToast;
import 'package:better_muslim/core/widgets/toggle_row.dart';
import 'package:better_muslim/features/quran/presentation/providers/page_providers.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/share_card.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/swatch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';

/// 4.30, the ayah as a still image on a brand background (FR-041)
Future<void> showShareSheet(BuildContext context, AyahKey ayah) =>
    showBmSheet(context, maxSheetHeight: true, builder: (_) => _ShareSheet(ayah));

class _ShareSheet extends ConsumerStatefulWidget {
  const _ShareSheet(this.ayah);

  final AyahKey ayah;

  @override
  ConsumerState<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<_ShareSheet> {
  final _card = GlobalKey();
  var _background = ShareBackground.paper;
  var _size = ShareSize.square;
  var _translation = true;
  var _appName = true;
  var _busy = false;

  /// button is the share's context, ipad anchors the system sheet to it
  Future<void> _share(BuildContext button) async {
    setState(() => _busy = true);
    try {
      final box = button.findRenderObject()! as RenderBox;
      final origin = box.localToGlobal(Offset.zero) & box.size;
      final boundary = _card.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(
        pixelRatio: SizeManager.shareSquare / boundary.size.width,
      );
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await ref.read(shareProvider)(
        ShareParams(
          files: [
            XFile.fromData(png!.buffer.asUint8List(), mimeType: 'image/png', name: 'ayah.png'),
          ],
          sharePositionOrigin: origin,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ayah = widget.ayah;
    final arabic = ref.watch(ayahTextProvider(ayah)).value;
    final text = ref.watch(surahTextProvider(ayah.surah)).value;
    final surah = ref.watch(quranAssetsProvider).value?.surah(ayah.surah);
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    if (arabic == null || text == null || surah == null) return const SizedBox.shrink();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    /// in arabic the translation slot is al-muyassar (FR-020)
    final translation = isArabic ? text.tafsir[ayah.ayah - 1] : text.translation[ayah.ayah - 1];
    final card = ShareText(
      arabic: arabic,

      /// quran markers are eastern whatever the app's digits
      marker: '﴿${formatDigitsIn('${ayah.ayah}', language: 'ar', digits: Digits.eastern)}﴾',
      translation: _translation ? translation : null,
    );
    final args = {
      'surah': isArabic ? surah.ar : surah.en,
      'n': context.formatDigits('${ayah.ayah}', digits),
    };

    /// a long ayah first gets smaller, under the smallest step only the story fits it whole
    final squareFits = card.fit(context, ShareSize.square) != null;
    final size = squareFits ? _size : ShareSize.story;
    final scale = card.fit(context, size) ?? SizeManager.shareFit.last;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: BottomPadding(
          padding: SpaceManager.s6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetTitle(
                StringsManager.shareAyah,
                subtitle: StringsManager.shareAyahRef,
                subtitleArgs: args,
              ),
              TopPadding(
                padding: SpaceManager.sharePreviewTop,
                child: Center(
                  child: RSizedBox.square(
                    dimension: SizeManager.shareAyahCard,

                    /// the story shows whole in the square's place
                    child: FittedBox(
                      child: _Preview(
                        child: RepaintBoundary(
                          key: _card,
                          child: ShareCard(
                            text: card,
                            reference: context.tr(StringsManager.shareAyahRef, args),
                            background: _background,
                            size: size,
                            scale: scale,
                            appName: _appName,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              TopPadding(
                padding: SpaceManager.shareSwatchTop,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      constraints: BoxConstraints(maxHeight: 80.r),
                      child: CustomScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: 100.r),

                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (final (i, background) in ShareBackground.values.indexed) ...[
                                    if (i == 0)
                                      const RSizedBox.horizontal(SpaceManager.shareSwatchGap),

                                    Swatch(
                                      label: background.label,
                                      selected: background == _background,
                                      onTap: () => setState(() => _background = background),
                                      fill: _Fill(background),
                                    ),
                                    const RSizedBox.horizontal(SpaceManager.shareSwatchGap),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              OnlyPadding(
                top: SpaceManager.s4,
                start: SpaceManager.s4,
                end: SpaceManager.s4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Segmented<ShareSize>(
                      values: ShareSize.values,
                      selected: size,
                      labelOf: (size) => size.label,
                      muted: squareFits ? const {} : const {ShareSize.square},
                      onChanged: (size) {
                        if (size == ShareSize.square && !squareFits) {
                          showToast(
                            context,
                            StringsManager.turnOffTranslation,
                            icon: BmIconName.adhan,
                          );
                          return;
                        }
                        setState(() => _size = size);
                      },
                    ),
                    const RSizedBox.vertical(SpaceManager.s4),
                    GroupedSection(
                      children: [
                        ToggleRow(
                          title: StringsManager.includeTranslation,
                          value: _translation,
                          onChanged: (value) => setState(() => _translation = value),
                        ),
                        ToggleRow(
                          title: StringsManager.showAppName,
                          value: _appName,
                          onChanged: (value) => setState(() => _appName = value),
                        ),
                      ],
                    ),
                    const RSizedBox.vertical(SpaceManager.shareButtonsTop),
                    Builder(
                      builder: (button) => BmButton.primary(
                        StringsManager.share,
                        busy: _busy,
                        onPressed: () => _share(button),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// rounded and lifted only on screen, the image itself has square corners
class _Preview extends StatelessWidget {
  const _Preview({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(RadiusManager.sharePreview.r);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: context.getColor(ThemeEnum.scrim).withValues(alpha: .6),
            offset: Offset(0, SizeManager.sharePreviewShadowY.r),
            blurRadius: SizeManager.sharePreviewShadowBlur.r,
            spreadRadius: SizeManager.sharePreviewShadowSpread.r,
          ),
        ],
      ),
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }
}

/// the swatch shows the card's own background
class _Fill extends StatelessWidget {
  const _Fill(this.background);

  final ShareBackground background;

  @override
  Widget build(BuildContext context) {
    return Theme(data: AppTheme.page(background.page), child: ShareBackgroundFill(background));
  }
}
