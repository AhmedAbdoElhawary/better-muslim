import 'package:better_muslim/core/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// replay = the dev page shows onboarding again without clearing anything (FR-004)
typedef Onboarding = ({bool done, bool replay});

final onboardingProvider = NotifierProvider<OnboardingNotifier, Onboarding>(OnboardingNotifier.new);

/// read once in bootstrap, so the first frame is already on the right route (R2)
class OnboardingNotifier extends Notifier<Onboarding> {
  OnboardingNotifier({this.done = false});

  final bool done;

  @override
  Onboarding build() => (done: done, replay: false);

  /// apply on the theme step
  Future<void> finish() async {
    await ref
        .read(databaseProvider)
        .updateSettings(const SettingsCompanion(onboarded: Value(true)));
    state = (done: true, replay: false);
  }

  void replay() => state = (done: state.done, replay: true);
}
