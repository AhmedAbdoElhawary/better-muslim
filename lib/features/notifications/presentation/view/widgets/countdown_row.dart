import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/toggle_row.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// the live activity and the android countdown before each prayer, the boot syncs them (FR-013)
class CountdownRow extends ConsumerWidget {
  const CountdownRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(
      settingsProvider.select((settings) => settings.value?.prayerCountdown ?? true),
    );
    return ToggleRow(
      title: StringsManager.prayerCountdown,
      subtitle: StringsManager.prayerCountdownLine,
      value: on,
      onChanged: (value) => ref
          .read(databaseProvider)
          .updateSettings(SettingsCompanion(prayerCountdown: Value(value))),
    );
  }
}
