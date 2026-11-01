import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/resources/design/bm_theme.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/picker_row.dart';
import 'package:better_muslim/core/widgets/sheet/sheet_title.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showModeSheet(BuildContext context) => showBmSheet(
  context,
  title: const SheetTitle(StringsManager.lightAndDark),
  builder: (_) => const _ModeSheet(),
);

/// dark, light or follow sky, applied the moment it's picked (FR-016)
class _ModeSheet extends ConsumerWidget {
  const _ModeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(
      settingsProvider.select((settings) => settings.value?.themeMode ?? BmThemeMode.followSky),
    );
    return SingleChildScrollView(
      child: SafeArea(
        top: false,
        child: BottomPadding(
          padding: SpaceManager.s6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final mode in BmThemeMode.values)
                PickerRow(
                  title: mode.nameKey,
                  selected: mode == saved,
                  onTap: () {
                    ref
                        .read(databaseProvider)
                        .updateSettings(SettingsCompanion(themeMode: Value(mode)));
                    Navigator.pop(context);
                  },
                ),
              const SymmetricPadding(
                horizontal: SpaceManager.s4,
                vertical: SpaceManager.s2,
                child: RegularText(StringsManager.followSkyNote, color: ThemeEnum.text2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
