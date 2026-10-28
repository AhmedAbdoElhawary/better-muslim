import 'dart:ui' as ui;

import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/appearance.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/system/share.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/segmented.dart';
import 'package:better_muslim/core/widgets/share/share_frame.dart';
import 'package:better_muslim/core/widgets/share/share_options.dart';
import 'package:better_muslim/core/widgets/share/swatch.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/sheet_title.dart';
import 'package:better_muslim/core/widgets/toggle_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';

/// the size and scale a content fits at. fits is false when it only fit under the last
/// SizeManager.shareFit step. note shows under the preview, already translated
typedef ShareLayout = ({ShareSize size, double scale, bool fits, String? note});

/// what a feature puts on the card (contracts/share-sheet)
abstract class ShareContent {
  const ShareContent();

  /// the sheet's title, a StringsManager key
  String get title;

  /// the png's name
  String get file;

  /// false hides the Font row when no quran text is on the card
  bool get usesFont => true;

  /// the line next to the app name, the sheet's subtitle too
  String footer(BuildContext context);

  /// called on every option change, so it only measures
  ShareLayout layout(BuildContext context, ShareOptions options);

  /// the text inside the frame, at the layout's scale
  Widget build(BuildContext context, ShareOptions options, ShareLayout layout);
}

/// the card as a still image on a brand background, for ayahs and duas (FR-008)
Future<void> showShareSheet(
  BuildContext context, {
  required ShareContent content,
  List<Widget> rows = const [],
  List<ShareOrnament> ornaments = ShareOrnament.patterns,
}) => showBmSheet(
  context,
  maxSheetHeight: true,
  builder: (_) => ShareSheet(content: content, rows: rows, ornaments: ornaments),
);

/// public so a content with its own rows keeps their state around it
class ShareSheet extends ConsumerStatefulWidget {
  const ShareSheet({
    required this.content,
    this.rows = const [],
    this.ornaments = ShareOrnament.patterns,
    super.key,
  });

  final ShareContent content;

  /// the feature's own options, under the sheet's
  final List<Widget> rows;
  final List<ShareOrnament> ornaments;

  @override
  ConsumerState<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<ShareSheet> {
  final _card = GlobalKey();

  /// starts on the reader's font (FR-011)
  late var _options = ShareOptions(
    font: ref.read(settingsProvider).value?.quranFont ?? QuranFont.amiri,
  );
  var _busy = false;

  void _set(ShareOptions options) => setState(() => _options = options);

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
            XFile.fromData(
              png!.buffer.asUint8List(),
              mimeType: 'image/png',
              name: widget.content.file,
            ),
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
    final content = widget.content;
    final options = _options;
    final layout = content.layout(context, options);
    final footer = content.footer(context);
    final note = layout.note;
    final ornament = options.ornament;
    final themeId = ref.watch(themeIdProvider);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: BottomPadding(
          padding: SpaceManager.s6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetTitle(context.tr(content.title), subtitle: footer, translate: false),
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
                          child: ShareFrame(
                            options: options,
                            size: layout.size,
                            footer: footer,
                            child: content.build(context, options, layout),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (note != null)
                OnlyPadding(
                  top: SpaceManager.shareNoteTop,
                  start: SpaceManager.s4,
                  end: SpaceManager.s4,
                  child: RegularText(
                    note,
                    translate: false,
                    fontSize: FontSizeManager.label,
                    color: ThemeEnum.text2,
                    textAlign: TextAlign.center,
                  ),
                ),
              TopPadding(
                padding: SpaceManager.shareSwatchTop,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: REdgeInsets.symmetric(horizontal: SpaceManager.shareSwatchGap),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: SizeManager.shareSwatchRow.r),
                    child: Row(
                      children: [
                        for (final (i, background) in ShareBackground.values.indexed) ...[
                          if (i > 0) const RSizedBox.horizontal(SpaceManager.shareSwatchGap),
                          Swatch(
                            label: background.label,
                            selected: background == options.background,
                            onTap: () => _set(options.copyWith(background: background)),
                            fill: Theme(
                              data: AppTheme.page(background.page, themeId),
                              child: ShareBackgroundFill(background),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
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
                      selected: layout.size,
                      labelOf: (size) => size.label,
                      onChanged: (size) => _set(options.copyWith(size: size, sizeLocked: true)),
                    ),
                    const RSizedBox.vertical(SpaceManager.s4),
                    GroupedSection(
                      children: [
                        if (options.background.isGradient)
                          ToggleRow(
                            title: StringsManager.solidColor,
                            value: options.solid,
                            onChanged: (solid) => _set(options.copyWith(solid: solid)),
                          ),
                        ToggleRow(
                          title: StringsManager.ornament,
                          value: ornament != null,
                          onChanged: (on) => _set(
                            options.copyWith(ornament: () => on ? widget.ornaments.first : null),
                          ),
                        ),
                        ToggleRow(
                          title: StringsManager.showAppName,
                          value: options.appName,
                          onChanged: (appName) => _set(options.copyWith(appName: appName)),
                        ),
                      ],
                    ),
                    if (ornament != null) ...[
                      const RSizedBox.vertical(SpaceManager.s4),
                      Segmented<ShareOrnament>(
                        values: widget.ornaments,
                        selected: ornament,
                        labelOf: (ornament) => ornament.label,
                        onChanged: (ornament) => _set(options.copyWith(ornament: () => ornament)),
                      ),
                    ],
                    if (content.usesFont) ...[
                      const RSizedBox.vertical(SpaceManager.s4),
                      Segmented<QuranFont>(
                        values: QuranFont.values,
                        selected: options.font,
                        labelOf: (font) => font.label,
                        onChanged: (font) => _set(options.copyWith(font: font)),
                      ),
                    ],
                    for (final row in widget.rows) ...[
                      const RSizedBox.vertical(SpaceManager.s4),
                      row,
                    ],
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
