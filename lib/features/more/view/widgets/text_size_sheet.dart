import 'package:better_muslim/core/database/app_database.dart';
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

Future<void> showTextSizeSheet(BuildContext context) => showBmSheet(
  context,
  title: const SheetTitle(StringsManager.textSize),
  builder: (_) => const _TextSizeSheet(),
);

/// stays open on pick, the sheet itself resizes so it's the preview
class _TextSizeSheet extends ConsumerWidget {
  const _TextSizeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(
      settingsProvider.select((settings) => settings.value?.textSize ?? TextSize.standard),
    );
    return SingleChildScrollView(
      child: SafeArea(
        top: false,
        child: BottomPadding(
          padding: SpaceManager.s6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final size in TextSize.values)
                PickerRow(
                  title: size.nameKey,
                  selected: size == saved,
                  onTap: () => ref
                      .read(databaseProvider)
                      .updateSettings(SettingsCompanion(textSize: Value(size))),
                ),
              const SymmetricPadding(
                horizontal: SpaceManager.s4,
                vertical: SpaceManager.s2,
                child: RegularText(StringsManager.textSizeNote, color: ThemeEnum.text2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
