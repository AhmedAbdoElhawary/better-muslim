import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/network/download.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart' show BmIconName;
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/core/widgets/motion/star_loader.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/picker_row.dart';
import 'package:better_muslim/core/widgets/sheet/sheet_title.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:better_muslim/features/quran/presentation/providers/mushaf_style_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<void> showMushafStyleSheet(BuildContext context) => showBmSheet(
  context,
  title: const SheetTitle(StringsManager.mushaf, subtitle: StringsManager.madinahHafs),
  builder: (_) => const _MushafStyleSheet(),
);

/// a qcf style not on the phone downloads here first, the page keeps its style until it's done
class _MushafStyleSheet extends ConsumerWidget {
  const _MushafStyleSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(
      settingsProvider.select((settings) => settings.value?.mushafStyle ?? MushafStyle.text),
    );
    return SingleChildScrollView(
      child: SafeArea(
        top: false,
        child: BottomPadding(
          padding: SpaceManager.s6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final style in MushafStyle.values) _StyleRow(style, selected: style == saved),
            ],
          ),
        ),
      ),
    );
  }
}

class _StyleRow extends ConsumerWidget {
  const _StyleRow(this.style, {required this.selected});

  final MushafStyle style;
  final bool selected;

  /// one on the phone is picked once the sheet has gone, the page's new layout dropped the sheet's
  /// frames. the others stay to show their download
  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final pick = ref.read(mushafStylePickProvider.notifier);
    try {
      if (ref.read(mushafStyleStatusProvider(style)).ready) {
        final route = ModalRoute.of(context);
        Navigator.pop(context);
        await route?.completed;
      }
      await pick.pick(style);
    } on DownloadException catch (error) {
      if (!context.mounted || error.failure == DownloadFailure.cancelled) return;
      showToast(
        context,
        error.failure == DownloadFailure.offline
            ? StringsManager.needsInternetOnce
            : StringsManager.downloadFailed,
        icon: BmIconName.quran,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(mushafStyleStatusProvider(style));
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    return PickerRow(
      title: style.label,
      subtitle: style.body,
      selected: selected && !status.downloading,
      trailing: status.downloading
          ? _Downloading(
              progress: status.progress,
              onCancel: ref.read(mushafStyleStatusProvider(style).notifier).cancel,
            )
          : status.ready
          ? null
          : RegularText(
              StringsManager.sizeMb,
              args: {'n': context.formatDigits((style.bytes / 1000000).toStringAsFixed(0), digits)},
              fontSize: FontSizeManager.rowValue,
              color: ThemeEnum.text2,
            ),
      onTap: () => _pick(context, ref),
    );
  }
}

class _Downloading extends StatelessWidget {
  const _Downloading({required this.progress, required this.onCancel});

  final double? progress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BmStarLoader(size: SizeManager.loaderInline, progress: progress),
        const RSizedBox.horizontal(SpaceManager.s2),
        BmButton.text(StringsManager.cancel, onPressed: onCancel),
      ],
    );
  }
}
