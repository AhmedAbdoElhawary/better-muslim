import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/azkar.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/picker_row.dart';
import 'package:better_muslim/core/widgets/sheet/sheet_title.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

Future<void> showAzkarFontSheet(BuildContext context) => showBmSheet(
  context,
  title: const SheetTitle(StringsManager.azkarFont),
  builder: (_) => const _AzkarFontSheet(),
);

/// the three azkar fonts, each name written in itself, applied the moment it's picked
class _AzkarFontSheet extends ConsumerWidget {
  const _AzkarFontSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(
      settingsProvider.select((settings) => settings.value?.azkarFont ?? AzkarFont.amiri),
    );
    return SingleChildScrollView(
      child: SafeArea(
        top: false,
        child: BottomPadding(
          padding: SpaceManager.s6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final font in AzkarFont.values)
                PickerRow(
                  title: font.label,
                  font: font.font,
                  selected: font == saved,
                  onTap: () {
                    ref
                        .read(databaseProvider)
                        .updateSettings(SettingsCompanion(azkarFont: Value(font)));
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
