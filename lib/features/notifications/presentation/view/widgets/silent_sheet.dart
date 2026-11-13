import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/picker_row.dart';
import 'package:better_muslim/core/widgets/sheet/sheet_title.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// the store's check
const silentChoices = [10, 15, 20, 30, 45, 60];

Future<void> showSilentSheet(BuildContext context) => showBmSheet(
  context,
  title: const SheetTitle(StringsManager.silentFor),
  builder: (_) => const _SilentSheet(),
);

/// minutes from the prayer's time, closes on pick
class _SilentSheet extends ConsumerWidget {
  const _SilentSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(
      settingsProvider.select((settings) => settings.value?.prayerSilentMinutes ?? 20),
    );
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    return SingleChildScrollView(
      child: SafeArea(
        top: false,
        child: BottomPadding(
          padding: SpaceManager.s6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final minutes in silentChoices)
                PickerRow(
                  title: StringsManager.reminderValue,
                  args: {'minutes': context.formatDigits('$minutes', digits)},
                  selected: minutes == saved,
                  onTap: () {
                    ref
                        .read(databaseProvider)
                        .updateSettings(SettingsCompanion(prayerSilentMinutes: Value(minutes)));
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
