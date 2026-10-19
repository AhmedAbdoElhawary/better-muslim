import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/theme_picker/view_model/theme_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const _columns = 4;

/// the gradient's sky1 sits at 60% of the dark half
const _skyStop = .6;

/// the 8 themes in the 4.15 order, each half dark and half light
class ThemeSwatches extends ConsumerWidget {
  const ThemeSwatches({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picked = ref.watch(themePreviewProvider.select((pick) => pick.theme));
    final rows = [
      for (var start = 0; start < bmThemeOrder.length; start += _columns)
        bmThemeOrder.sublist(start, start + _columns),
    ];
    return Column(
      children: [
        for (final (index, row) in rows.indexed) ...[
          if (index > 0) const RSizedBox.vertical(SpaceManager.swatchRowGap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (index, id) in row.indexed) ...[
                if (index > 0) const RSizedBox.horizontal(SpaceManager.swatchColumnGap),
                Expanded(
                  child: _Swatch(
                    id,
                    selected: id == picked,
                    onTap: () => ref.read(themePreviewProvider.notifier).pickTheme(id),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.id, {required this.selected, required this.onTap});
  final BmThemeId id;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = bmThemes[id]!;
    final radius = BorderRadius.circular(RadiusManager.md.r);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: context.tr(id.nameKey),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            RSizedBox(
              height: SizeManager.swatch,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  boxShadow: [
                    BoxShadow(color: context.getColor(ThemeEnum.outline), spreadRadius: 1),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: Stack(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _Half(theme.dark, dark: true)),
                          Expanded(child: _Half(theme.light, dark: false)),
                        ],
                      ),
                      if (selected) ...[
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: radius,
                              border: Border.all(
                                color: context.getColor(ThemeEnum.primary),
                                width: SizeManager.swatchRing.r,
                              ),
                            ),
                          ),
                        ),
                        const PositionedDirectional(
                          top: 0,
                          end: 0,
                          child: AllPadding(padding: SpaceManager.swatchCheck, child: _Check()),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const RSizedBox.vertical(SpaceManager.swatchNameGap),
            RegularText(
              id.nameKey,
              fontSize: FontSizeManager.swatchName,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// the dark half shows the theme's night sky and primary, the light half its bg and primary
class _Half extends StatelessWidget {
  const _Half(this.palette, {required this.dark});
  final BmPalette palette;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? null : ThemeEnum.bg.resolve(palette),
        gradient: dark
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [ThemeEnum.sky3.resolve(palette), ThemeEnum.sky1.resolve(palette)],
                stops: const [0, _skyStop],
              )
            : null,
      ),
      child: AllPadding(
        padding: SpaceManager.swatchInset,
        child: Align(
          alignment: dark ? AlignmentDirectional.bottomStart : AlignmentDirectional.bottomEnd,
          child: RSizedBox(
            width: SizeManager.swatchPillW,
            height: SizeManager.swatchPillH,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ThemeEnum.primary.resolve(palette),
                borderRadius: BorderRadius.circular(RadiusManager.swatchPill.r),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check();

  @override
  Widget build(BuildContext context) {
    return RSizedBox.square(
      dimension: SizeManager.swatchCheck,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.getColor(ThemeEnum.primary),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: BmIcon.ui(
            BmUiIcon.check,
            size: SizeManager.iconChipSmall.r,
            color: context.getColor(ThemeEnum.onPrimary),
          ),
        ),
      ),
    );
  }
}
