import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// at null nothing was read yet, the card shows no time
typedef LastRead = ({AyahKey ayah, int page, DateTime? at});

/// in core, home's verse card and the quran tab read the same place
final lastReadProvider = Provider<LastRead>(
  (ref) => ref.watch(
    settingsProvider.select(
      (settings) => (
        ayah: AyahKey(settings.value?.lastReadSurah ?? 1, settings.value?.lastReadAyah ?? 1),
        page: settings.value?.lastReadPage ?? 1,
        at: settings.value?.lastReadAt,
      ),
    ),
  ),
);

/// called as ref.read(saveLastReadProvider)(ayah, page), from a widget or a provider
final saveLastReadProvider = Provider<Future<void> Function(AyahKey ayah, int page)>(
  (ref) =>
      (ayah, page) => ref
          .read(databaseProvider)
          .updateSettings(
            SettingsCompanion(
              lastReadSurah: Value(ayah.surah),
              lastReadAyah: Value(ayah.ayah),
              lastReadPage: Value(page),
              lastReadAt: Value(ref.read(clockProvider)()),
            ),
          ),
);
