import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/quran/last_read.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/appearance.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/motion/container_transform.dart';
import 'package:better_muslim/core/widgets/motion/skeleton.dart';
import 'package:better_muslim/features/quran/presentation/providers/page_providers.dart';
import 'package:better_muslim/features/quran/presentation/view/reader_page.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mushaf_page_view.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/saved_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// 4.18's continue reading: the last read page's thumbnail grows into the page
class ContinueCard extends ConsumerStatefulWidget {
  const ContinueCard({super.key});

  @override
  ConsumerState<ContinueCard> createState() => _ContinueCardState();
}

class _ContinueCardState extends ConsumerState<ContinueCard> {
  /// the last read page is laid out after the card shows, so continue opens with nothing to load.
  /// not an idle task, that one re-posts a timer every turn while anything animates
  @override
  void initState() {
    super.initState();
    ref.listenManual(
      lastReadProvider.select((lastRead) => lastRead.page),
      (_, page) => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) warmMushafPage(context, ref, page);
      }),
      fireImmediately: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(lastReadProvider.select((lastRead) => lastRead.page));
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(RadiusManager.lg.r),

        /// css box-shadow 0 0 0 1px, the ring outside the box like SurfaceCard's
        boxShadow: [BoxShadow(color: context.getColor(ThemeEnum.outline), spreadRadius: 1)],
      ),
      child: BmContainerTransform(
        closedBuilder: (context, open) => Semantics(
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,

            /// the page starts loading while the finger is still down
            onTapDown: (_) => warmMushafPage(context, ref, page),
            onTap: () async {
              await warmMushafPage(context, ref, page);
              if (context.mounted) open();
            },
            child: const _Card(),
          ),
        ),
        openBuilder: (context) => ReaderPage(page: page),
      ),
    );
  }
}

class _Card extends ConsumerWidget {
  const _Card();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loaded = ref.watch(quranAssetsProvider.select((assets) => assets.hasValue));
    return OnlyPadding(
      top: SpaceManager.continueCardTop,
      bottom: SpaceManager.continueCardTop,
      start: SpaceManager.continueCardStart,
      end: SpaceManager.continueCardEnd,
      child: Row(
        children: [
          const _Thumbnail(),
          const RSizedBox.horizontal(SpaceManager.continueGap),
          Expanded(
            child: BmSkeletonSwitch(
              loading: !loaded,
              skeleton: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BmSkeleton(height: FontSizeManager.quranTag, width: SizeManager.pageThumbH),
                  RSizedBox.vertical(SpaceManager.continueLineGap),
                  BmSkeleton(height: FontSizeManager.title),
                  RSizedBox.vertical(SpaceManager.continueLineGap),
                  BmSkeleton(
                    height: FontSizeManager.rowSubtitle,
                    width: SizeManager.pageThumbW * 2,
                  ),
                ],
              ),
              child: const _Lines(),
            ),
          ),
          const RSizedBox.horizontal(SpaceManager.continueGap),
          RSizedBox.square(
            dimension: SizeManager.continueButton,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.getColor(ThemeEnum.primary),
              ),
              child: Center(
                child: BmIcon(
                  BmIconName.quran,
                  size: SizeManager.icon.r,
                  color: context.getColor(ThemeEnum.onPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Al-Fatiha · Ayah 3" and "Page 1 · Juz 1 · Today 14:10"
class _Lines extends ConsumerWidget {
  const _Lines();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastRead = ref.watch(lastReadProvider);
    final assets = ref.watch(quranAssetsProvider).value;
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    if (assets == null) return const SizedBox.shrink();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final surah = assets.surah(lastRead.ayah.surah);
    final args = {
      'p': context.formatDigits('${lastRead.page}', digits),
      'j': context.formatDigits('${assets.pageInfo(lastRead.page).juz}', digits),
    };
    final at = lastRead.at;
    if (at != null) args['when'] = savedWhen(context, ref, at);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegularText(
          StringsManager.continueReadingTag,
          fontSize: FontSizeManager.quranTag,
          letterSpacing: isArabic ? null : LetterSpacingManager.quranTag,
          color: ThemeEnum.primary,
        ),
        const RSizedBox.vertical(SpaceManager.continueLineGap),
        SemiBoldText(
          StringsManager.quranAyahN,
          args: {
            'surah': isArabic ? surah.ar : surah.en,
            'n': context.formatDigits('${lastRead.ayah.ayah}', digits),
          },
        ),
        const RSizedBox.vertical(SpaceManager.continueLineGap),
        RegularText(
          at == null ? StringsManager.pageJuz : StringsManager.pageJuzWhen,
          args: args,
          fontSize: FontSizeManager.rowSubtitle,
          color: ThemeEnum.text2,
        ),
      ],
    );
  }
}

/// thumb() of _gen/quran.js in the color the page will open in
class _Thumbnail extends ConsumerWidget {
  const _Thumbnail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = ref.watch(pageColorProvider).resolve(dark: context.isThemeDark);
    return Theme(
      data: AppTheme.page(color, ref.watch(themeIdProvider)),
      child: Builder(
        builder: (context) => Container(
          width: SizeManager.pageThumbW.r,
          height: SizeManager.pageThumbH.r,
          decoration: BoxDecoration(
            color: context.getColor(ThemeEnum.page),
            borderRadius: BorderRadius.circular(RadiusManager.pageThumb.r),
            boxShadow: [
              BoxShadow(
                color: context.getColor(ThemeEnum.scrim).withValues(alpha: .6),
                blurRadius: SizeManager.thumbShadowBlur.r,
                offset: Offset(0, SizeManager.thumbShadowY.r),
                spreadRadius: SizeManager.thumbShadowSpread.r,
              ),
              BoxShadow(
                color: context.getColor(ThemeEnum.scrim).withValues(alpha: .2),
                spreadRadius: SizeManager.divider.r,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _ThumbnailPainter(
              ornament: context.getColor(ThemeEnum.ornament),
              ink: context.getColor(ThemeEnum.ink),
              gutter: context.getColor(ThemeEnum.gutter),
              radius: RadiusManager.pageThumb.r,
              frame: SizeManager.thumbFrameStroke.r,
              cartouche: SizeManager.thumbCartoucheStroke.r,
              line: SizeManager.thumbLine.r,
              spine: SizeManager.thumbSpine.r,
            ),
          ),
        ),
      ),
    );
  }
}

/// the frame, the cartouche and five lines, in shares of the thumbnail as thumb() places them
class _ThumbnailPainter extends CustomPainter {
  const _ThumbnailPainter({
    required this.ornament,
    required this.ink,
    required this.gutter,
    required this.radius,
    required this.frame,
    required this.cartouche,
    required this.line,
    required this.spine,
  });

  final Color ornament;
  final Color ink;
  final Color gutter;
  final double radius;
  final double frame;
  final double cartouche;
  final double line;
  final double spine;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    canvas
      ..clipRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)))
      ..drawRect(
        Rect.fromLTRB(w * .1, w * .1, w - w * .1, size.height - w * .12),
        Paint()
          ..color = ornament
          ..style = PaintingStyle.stroke
          ..strokeWidth = frame,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * .28, size.height * .3, w * .44, w * .07),
          Radius.circular(radius / 2),
        ),
        Paint()
          ..color = ornament
          ..style = PaintingStyle.stroke
          ..strokeWidth = cartouche,
      );
    final paint = Paint()..color = ink.withValues(alpha: .35);
    for (var i = 0; i < 5; i++) {
      canvas.drawRect(Rect.fromLTWH(w * .22, size.height * (.44 + i * .08), w * .56, line), paint);
    }
    final edge = Rect.fromLTRB(w - spine, 0, w, size.height);
    canvas.drawRect(
      edge,
      Paint()
        ..shader = LinearGradient(colors: [gutter.withValues(alpha: 0), gutter]).createShader(edge),
    );
  }

  @override
  bool shouldRepaint(_ThumbnailPainter old) =>
      old.ornament != ornament || old.ink != ink || old.gutter != gutter || old.radius != radius;
}
