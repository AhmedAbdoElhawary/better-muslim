import 'dart:async';

import 'package:better_muslim/core/app/app.dart';
import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:better_muslim/core/app/launch.dart';
import 'package:better_muslim/core/audio/adhan_files.dart';
import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/flavor/design_scenario.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/monitoring/monitoring.dart';
import 'package:better_muslim/core/quran/recitation_files.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/onboarding.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/home/view_model/home_providers.dart';
import 'package:better_muslim/features/notifications/data/background.dart';
import 'package:better_muslim/features/notifications/presentation/notifications_boot.dart';
import 'package:better_muslim/features/quran/data/audio_service_recitation.dart';
import 'package:better_muslim/features/quran/presentation/providers/recitation_providers.dart';
import 'package:better_muslim/features/quran/presentation/recitation_boot.dart';
import 'package:better_muslim/features/surfaces/presentation/surfaces_boot.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:workmanager/workmanager.dart';

Future<void> bootstrap(FlavorConfig config) {
  return Monitoring.start(config: config, appRunner: () => _boot(config));
}

Future<void> _boot(FlavorConfig config) async {
  final launch = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();

  /// the design has no landscape, android 16 still turns tablets and foldables
  unawaited(SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]));
  Monitoring.installErrorHandlers();

  /// all at once, the store opens in drift's isolate and the rest waits on the phone while the
  /// time zones decode here
  var store = Duration.zero;
  final ready = (
    (config.isDesignScenario ? designScenarioStore() : AppDatabase.open()).then((db) {
      store = launch.elapsed;
      return db;
    }),
    PhoneZone.read(),
    AppLocalizations.preload(),
    config.isDesignScenario ? Future<void>.value() : AdhanFiles.init(),
  ).wait;

  /// latest.dart lacks zones like Europe/Oslo
  tz.initializeTimeZones();
  final (db, phoneZone, _, _) = await ready;

  /// before the first frame, so a new install never flashes home and a set up one never the
  /// welcome (R2)
  final settings = await db.watchSettings().first;
  await Monitoring.follow(config: config, on: settings.crashReports);

  /// here and not in a provider, audio_service starts once and only in the app's own engine
  final recitationFiles = RecitationFiles();
  final recitation = config.isDesignScenario ? null : AudioServiceRecitation(recitationFiles);
  final settled = launchSettled();
  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      flavorProvider.overrideWithValue(config),
      phoneZoneProvider.overrideWith(() => PhoneZone(phoneZone)),

      /// starts with the row read above, the first frame has the saved theme not the fallback
      settingsProvider.overrideWith((ref) async* {
        yield settings;
        yield* db.watchSettings(now: ref.read(clockProvider)());
      }),
      onboardingProvider.overrideWith(() => OnboardingNotifier(done: settings.onboarded)),
      if (config.isDesignScenario) ...designScenarioOverrides(),
      if (recitation != null) recitationProvider.overrideWithValue(recitation),
      recitationFilesProvider.overrideWithValue(recitationFiles),
      launchSettledProvider.overrideWithValue(settled),
    ],
  );

  container.listen(settingsProvider.select((settings) => settings.value?.crashReports), (_, on) {
    if (on != null) Monitoring.follow(config: config, on: on);
  });

  /// the verse card is on the first screen, so it never pops in after it. a slow or failed read
  /// leaves the card to show it when it comes
  if (settings.onboarded) {
    final verse = container.listen(verseOfDayProvider.future, (_, _) {});
    await verse.read().timeout(const Duration(milliseconds: 300)).then((_) {}, onError: (_) {});
    verse.close();
  }
  if (kProfileMode) {
    debugPrint('cold open: store ${store.inMilliseconds} ms, run ${launch.elapsedMilliseconds} ms');
  }
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const NotificationsBoot(
        child: SurfacesBoot(child: RecitationBoot(child: App())),
      ),
    ),
  );
  if (!config.isDesignScenario) unawaited(settled.then((_) => _later(settings, recitation)));
}

/// what Home's first frame doesn't need
Future<void> _later(AppSettings settings, AudioServiceRecitation? recitation) async {
  final l10n = await AppLocalizations.load(AppLocalizations.localeOf(settings.language));
  await recitation?.start(channel: l10n.tr(StringsManager.tabQuran, const {}));

  /// keep, so every launch doesn't push the next run 12 hours away
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    topUpTask,
    topUpTask,
    frequency: const Duration(hours: 12),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
  await AdhanFiles.deleteRemoved();
}
