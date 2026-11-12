import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/features/quran/presentation/providers/selection.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/page_chrome.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// in the dock's place while ayahs are chosen: Cancel and "Share (n)" (FR-015)
class ChoosingBar extends ConsumerWidget {
  const ChoosingBar({required this.onShare, required this.onCancel, super.key});

  final VoidCallback onShare;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(selectionProvider.select((selection) => selection.chosen.length));
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    return ReaderGlass(
      child: SafeArea(
        top: false,
        child: SymmetricPadding(
          horizontal: SpaceManager.s4,
          vertical: SpaceManager.choosingBarV,
          child: Row(
            children: [
              Expanded(
                child: BmButton.secondary(
                  StringsManager.cancel,
                  onPressed: () {
                    BmHaptics.selection();
                    onCancel();
                  },
                ),
              ),
              const RSizedBox.horizontal(SpaceManager.s3),
              Expanded(
                child: BmButton.primary(
                  StringsManager.shareN,
                  args: {'n': context.formatDigits('$count', digits)},
                  onPressed: () {
                    BmHaptics.selection();
                    onShare();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
