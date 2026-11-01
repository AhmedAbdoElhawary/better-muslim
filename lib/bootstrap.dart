import 'dart:async';

import 'package:better_muslim/core/app/app.dart';
import 'package:better_muslim/core/app/app_localizations.dart';
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
import 'package:better_muslim/features/notifications/data/background.dart';
import 'package:better_muslim/features/notifications/presentation/notifications_boot.dart';
import 'package:better_muslim/features/quran/data/audio_service_recitation.dart';
import 'package:better_muslim/features/quran/presentation/providers/recitation_providers.dart';
import 'package:better_muslim/features/quran/presentation/recitation_boot.dart';
import 'package:better_muslim/features/surfaces/presentation/surfaces_boot.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:workmanager/workmanager.dart';

Future<void> bootstrap(FlavorConfig config) {
  return Monitoring.start(config: config, appRunner: () => _boot(config));
}

Future<void> _boot(FlavorConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  Monitoring.installErrorHandlers();
  Monitoring.activate(config: config);

  /// GeoNames is CC BY 4.0, the credit line in More comes in milestone 9
  LicenseRegistry.addLicense(_placesLicense);

  /// latest.dart lacks zones like Europe/Oslo
  tz.initializeTimeZones();
  final db = config.isDesignScenario ? await designScenarioStore() : await AppDatabase.open();
  final phoneZone = await PhoneZone.read();
  if (!config.isDesignScenario) {
    await AdhanFiles.init();
    unawaited(AdhanFiles.deleteRemoved());
  }

  /// before the first frame, so a new install never flashes home and a set up one never the
  /// welcome (R2)
  final settings = await db.watchSettings().first;

  /// keep, so every launch doesn't push the next run 12 hours away
  if (!config.isDesignScenario) {
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      topUpTask,
      topUpTask,
      frequency: const Duration(hours: 12),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  /// here and not in a provider, audio_service starts once and only in the app's own engine
  final recitationFiles = RecitationFiles();
  final recitation = config.isDesignScenario
      ? null
      : await AudioServiceRecitation.init(
          recitationFiles,
          channel: (await AppLocalizations.load(AppLocalizations.localeOf(settings.language)))
              .tr(StringsManager.tabQuran, const {}),
        );
  runApp(
    ProviderScope(
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
      ],
      child: const NotificationsBoot(
        child: SurfacesBoot(child: RecitationBoot(child: App())),
      ),
    ),
  );
}

Stream<LicenseEntry> _placesLicense() async* {
  final license = await rootBundle.loadString('assets/places/LICENSE.txt');
  yield LicenseEntryWithLineBreaks(['GeoNames'], license);
}
