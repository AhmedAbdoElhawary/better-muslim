import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(databaseProvider).watchSettings(now: ref.read(clockProvider)()),
);

enum LocationMode { auto, manual }

/// only read when the app is in arabic
enum Digits { eastern, western }
