import 'dart:ui';

import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/animated_decorated_box.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/custom_opacity.dart';
import 'package:better_muslim/features/quran/presentation/providers/saved_providers.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/bookmark_picker.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/display_sheet.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/index_sheet.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/scrubber.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// the controls over the page (4.21): the glass top bar and dock slide in over the page at its
/// full size. with reduce motion they fade
class PageChrome extends StatelessWidget {
  const PageChrome({
    required this.page,
    required this.card,
    required this.shown,
    required this.onListen,
    required this.hiding,
    required this.onTranslation,
    required this.onSearch,
    super.key,
  });

  final ValueNotifier<int> page;
  final VoidCallback onSearch;
  final VoidCallback onListen;
  final bool hiding;
  final VoidCallback onTranslation;

  /// the controls' spring, 0 hidden and 1 shown
  final Animation<double> card;
  final bool shown;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);

    /// the bar and the dock never overlap, so they share one blur of the page
    return BackdropGroup(
      child: IgnorePointer(
        ignoring: !shown,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: _Arrive(
                card: card,
                from: -1,
                reduce: reduce,
                child: _TopBar(page, onSearch: onSearch),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _Arrive(
                card: card,
                from: 1,
                reduce: reduce,
                child: _Dock(page, onListen, hiding: hiding, onTranslation: onTranslation),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// slides in from its own height above or below, and only fades with reduce motion
class _Arrive extends StatelessWidget {
  const _Arrive({
    required this.card,
    required this.from,
    required this.reduce,
    required this.child,
  });

  final Animation<double> card;
  final double from;
  final bool reduce;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: card,
      builder: (context, child) {
        final value = card.value.clamp(0.0, 1.0);
        return reduce
            ? CustomOpacity(opacity: value, child: child)
            /// off the screen it isn't painted, its blur would run on every frame of a turn
            : Opacity(
                opacity: value == 0 ? 0 : 1,
                child: FractionalTranslation(
                  translation: Offset(0, from * (1 - card.value)),
                  child: child,
                ),
              );
      },

      /// so a slide only moves its layer, nothing in the bar paints again
      child: RepaintBoundary(child: child),
    );
  }
}

/// GLASS of _gen/quran.js: the page's surface at 78% over a 24 pt blur, saturated 1.5
class ReaderGlass extends StatelessWidget {
  const ReaderGlass({required this.child, this.top = false, this.radius, super.key});

  /// the hairline is on the side facing the page
  final bool top;
  final Widget child;

  /// the mini player floats as a rounded card, outlined all round
  final double? radius;

  static const _saturation = SizeManager.glassSaturation;
  static const _luma = [.2126, .7152, .0722];

  /// css saturate() as a color matrix
  static final _saturate = ColorFilter.matrix([
    for (var row = 0; row < 3; row++) ...[
      for (var column = 0; column < 3; column++)
        _luma[column] * (1 - _saturation) + (row == column ? _saturation : 0),
      0,
      0,
    ],
    ...[0, 0, 0, 1, 0],
  ]);

  @override
  Widget build(BuildContext context) {
    final line = BorderSide(color: context.getColor(ThemeEnum.outline));
    final radius = this.radius;
    final rounded = radius == null ? null : BorderRadius.circular(radius.r);
    return ClipRRect(
      borderRadius: rounded ?? BorderRadius.zero,
      child: BackdropFilter.grouped(
        filter: ImageFilter.compose(
          outer: _saturate,
          inner: ImageFilter.blur(sigmaX: SizeManager.glassBlur, sigmaY: SizeManager.glassBlur),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.getColor(ThemeEnum.pageGlass),
            borderRadius: rounded,
            border: rounded != null
                ? Border.fromBorderSide(line)
                : top
                ? Border(bottom: line)
                : Border(top: line),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar(this.page, {required this.onSearch});

  final ValueNotifier<int> page;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(quranAssetsProvider).value;
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return ReaderGlass(
      top: true,
      child: SafeArea(
        bottom: false,

        /// arabic's two lines and larger text grow the bar
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: SizeManager.appBar.r),
          child: HorizontalPadding(
            padding: SpaceManager.s2,
            child: ValueListenableBuilder(
              valueListenable: page,
              builder: (context, page, _) {
                final info = assets?.pageInfo(page);
                final surah = info == null ? null : assets!.surah(info.start.surah);
                return Row(
                  children: [
                    const BarBackButton(),
                    const RSizedBox.square(dimension: SizeManager.hit),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SemiBoldText(
                            surah == null ? '' : (isArabic ? surah.ar : surah.en),
                            translate: false,
                            maxLines: 1,
                          ),
                          if (info != null)
                            RegularText(
                              StringsManager.juzHizbPage,
                              fontSize: FontSizeManager.label,
                              color: ThemeEnum.text2,
                              maxLines: 1,
                              args: {
                                'j': context.formatDigits('${info.juz}', digits),
                                'h': context.formatDigits('${info.hizb}', digits),
                                'p': context.formatDigits('$page', digits),
                              },
                            ),
                        ],
                      ),
                    ),

                    _Search(onSearch),
                    _PageBookmark(page),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Search extends StatelessWidget {
  const _Search(this.onTap);

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr(StringsManager.searchQuran),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: RSizedBox.square(
          dimension: SizeManager.hit,
          child: Center(
            child: BmIcon.ui(
              BmUiIcon.search,
              size: SizeManager.icon.r,
              color: context.getColor(ThemeEnum.text),
            ),
          ),
        ),
      ),
    );
  }
}

/// the page itself, an ayah is bookmarked from its sheet (FR-037)
class _PageBookmark extends ConsumerWidget {
  const _PageBookmark(this.page);

  final int page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(pageBookmarkProvider(page).select((bookmark) => bookmark != null));
    return Semantics(
      button: true,
      selected: saved,
      label: context.tr(StringsManager.bookmark),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showBookmarkPicker(context, page: page),
        child: RSizedBox.square(
          dimension: SizeManager.hit,
          child: Center(
            child: BmIcon(
              BmIconName.bookmark,
              filled: saved,
              size: SizeManager.icon.r,
              color: context.getColor(saved ? ThemeEnum.primary : ThemeEnum.text),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dock extends StatelessWidget {
  const _Dock(this.page, this.onListen, {required this.hiding, required this.onTranslation});

  final ValueNotifier<int> page;
  final VoidCallback onListen;
  final bool hiding;
  final VoidCallback onTranslation;

  /// from here so the sheet takes the page palette, closing it leaves the page as it was
  Future<void> _index(BuildContext context) async {
    final picked = await showIndexSheet(context, page.value);
    if (picked != null && context.mounted) page.value = picked;
  }

  @override
  Widget build(BuildContext context) {
    return ReaderGlass(
      top: false,
      child: SafeArea(
        top: false,
        child: OnlyPadding(
          top: SpaceManager.dockTop,
          bottom: SpaceManager.s4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HorizontalPadding(
                padding: SpaceManager.dockSide,
                child: Scrubber(page: page),
              ),
              OnlyPadding(
                top: SpaceManager.dockButtonsTop,
                start: SpaceManager.dockButtonsSide,
                end: SpaceManager.dockButtonsSide,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _DockButton(
                        icon: BmIcon.ui(BmUiIcon.contents),
                        label: StringsManager.quranIndex,
                        onTap: () => _index(context),
                      ),
                    ),
                    Expanded(
                      child: _DockButton(
                        icon: BmIcon(BmIconName.listen),
                        label: StringsManager.listen,
                        onTap: onListen,
                      ),
                    ),
                    Expanded(
                      child: _TranslationButton(hiding: hiding, onTap: onTranslation),
                    ),
                    Expanded(
                      child: _DockButton(
                        icon: BmIcon.ui(BmUiIcon.text_size),
                        label: StringsManager.display,
                        onTap: () => showDisplaySheet(context),
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

/// on while the translation shows, off as soon as it starts hiding
class _TranslationButton extends ConsumerWidget {
  const _TranslationButton({required this.hiding, required this.onTap});

  final bool hiding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(
      settingsProvider.select((settings) => settings.value?.quranLayout ?? QuranLayout.mushaf),
    );
    return _DockButton(
      icon: BmIcon.ui(BmUiIcon.translate),
      label: StringsManager.translation,
      on: layout != QuranLayout.mushaf && !hiding,
      onTap: onTap,
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({required this.icon, required this.label, this.on, this.onTap});

  final BmIcon icon;

  /// a StringsManager key
  final String label;

  /// set for a switch, the primary container behind the icon while on
  final bool? on;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final on = this.on ?? false;
    final color = on ? ThemeEnum.primary : ThemeEnum.text2;
    return Semantics(
      button: true,
      toggled: this.on,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: SizeManager.hit.r),
          child: Column(
            children: [
              AnimatedDecoratedBox(
                decoration: BoxDecoration(
                  color: context.getColor(on ? ThemeEnum.primaryContainer : ThemeEnum.transparent),
                  borderRadius: BorderRadius.circular(RadiusManager.dockButton.r),
                ),
                child: RSizedBox(
                  width: SizeManager.dockButtonW,
                  height: SizeManager.dockButtonH,
                  child: Center(
                    child: IconTheme(
                      data: IconThemeData(color: context.getColor(color)),
                      child: icon,
                    ),
                  ),
                ),
              ),
              const RSizedBox.vertical(SpaceManager.dockLabelGap),
              if (on)
                SemiBoldText(
                  label,
                  fontSize: FontSizeManager.tabLabelSelected,
                  color: color,
                  maxLines: 1,
                )
              else
                RegularText(label, fontSize: FontSizeManager.tabLabel, color: color, maxLines: 1),
            ],
          ),
        ),
      ),
    );
  }
}
