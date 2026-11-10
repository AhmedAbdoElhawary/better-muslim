import 'package:better_muslim/core/resources/design/bm_theme.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/segmented.dart';
import 'package:better_muslim/features/theme_picker/view_model/theme_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// dark, light, follow sky and follow phone for the preview only, saved on apply
class ModeControl extends ConsumerWidget {
  const ModeControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themePreviewProvider.select((pick) => pick.mode));
    return Segmented(
      values: BmThemeMode.values,
      selected: mode,
      labelOf: (mode) => mode.nameKey,

      /// 4.15 mutes only follow sky, all four look the same so none reads as lesser
      muted: BmThemeMode.values.toSet(),
      onChanged: ref.read(themePreviewProvider.notifier).pickMode,
    );
  }
}
