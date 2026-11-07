import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_theme.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef ThemePick = ({BmThemeId theme, BmThemeMode mode});

final themePreviewProvider = NotifierProvider.autoDispose<ThemePreview, ThemePick>(
  ThemePreview.new,
);

/// what the page shows before apply, gone when the page closes (FR-010, FR-012)
class ThemePreview extends Notifier<ThemePick> {
  @override
  ThemePick build() {
    final settings = ref.read(settingsProvider).value;
    return (
      theme: settings?.theme ?? BmThemeId.moonlight,
      mode: settings?.themeMode ?? BmThemeMode.followSky,
    );
  }

  void pickTheme(BmThemeId theme) => state = (theme: theme, mode: state.mode);

  void pickMode(BmThemeMode mode) => state = (theme: state.theme, mode: mode);

  Future<void> apply() => ref
      .read(databaseProvider)
      .updateSettings(SettingsCompanion(theme: Value(state.theme), themeMode: Value(state.mode)));
}
