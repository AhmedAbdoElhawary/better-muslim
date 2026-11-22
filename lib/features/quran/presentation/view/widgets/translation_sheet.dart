import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/picker_row.dart';
import 'package:better_muslim/core/widgets/sheet/sheet_title.dart';
import 'package:better_muslim/features/quran/presentation/providers/page_providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

Future<void> showTranslationSheet(BuildContext context) => showBmSheet(
  context,
  title: const SheetTitle(StringsManager.translation),
  blur: false,
  builder: (_) => const _TranslationSheet(),
);

/// every translation in the app, in either language
class _TranslationSheet extends ConsumerWidget {
  const _TranslationSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shown = shownTranslation(context, ref);
    return SingleChildScrollView(
      child: SafeArea(
        top: false,
        child: BottomPadding(
          padding: SpaceManager.s6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final translation in Translation.values)
                PickerRow(
                  title: translation.label,
                  subtitle: translation.arabic
                      ? StringsManager.arabicShortTafsir
                      : StringsManager.englishTranslation,
                  selected: translation == shown,
                  onTap: () => ref
                      .read(databaseProvider)
                      .updateSettings(SettingsCompanion(translation: Value(translation))),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
