import 'package:better_muslim/core/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fresh = (done: false, replay: false);
  const replaying = (done: true, replay: true);
  const done = (done: true, replay: false);

  for (final (name, onboarding) in [('not done', fresh), ('replaying', replaying)]) {
    group(name, () {
      test('anything else goes to the welcome', () {
        expect(onboardingRedirect(onboarding, '/'), Routes.onboarding);
        expect(onboardingRedirect(onboarding, '/prayer'), Routes.onboarding);
        expect(onboardingRedirect(onboarding, '/prayer?day=2026-10-15&prayer=asr'), '/onboarding');
        expect(onboardingRedirect(onboarding, Routes.devNotifications), Routes.onboarding);
      });

      test('the steps and the adhan stay', () {
        expect(onboardingRedirect(onboarding, Routes.onboarding), isNull);
        expect(onboardingRedirect(onboarding, Routes.onboardingLocation), isNull);
        expect(onboardingRedirect(onboarding, Routes.onboardingTheme), isNull);
        expect(onboardingRedirect(onboarding, '/adhan?prayer=asr'), isNull);
      });

      test('a path that only starts like onboarding is not one', () {
        expect(onboardingRedirect(onboarding, '/onboardingx'), Routes.onboarding);
      });
    });
  }

  group('done', () {
    test('onboarding goes home', () {
      expect(onboardingRedirect(done, Routes.onboarding), Routes.home);
      expect(onboardingRedirect(done, Routes.onboardingTheme), Routes.home);
    });

    test('anything else stays', () {
      expect(onboardingRedirect(done, Routes.more), isNull);
      expect(onboardingRedirect(done, '/'), isNull);
      expect(onboardingRedirect(done, '/adhan?prayer=asr'), isNull);
    });
  });
}
