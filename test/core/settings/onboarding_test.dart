import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/settings/onboarding.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/providers.dart';

void main() {
  ProviderContainer container({required bool done}) {
    final container = ProviderContainer(overrides: testOverrides(onboarded: done));
    addTearDown(container.dispose);
    return container;
  }

  test('a new install starts not done and not replaying', () {
    expect(container(done: false).read(onboardingProvider), (done: false, replay: false));
  });

  test('finish writes onboarded and ends onboarding', () async {
    final c = container(done: false);
    await c.read(onboardingProvider.notifier).finish();

    expect(c.read(onboardingProvider), (done: true, replay: false));
    expect((await c.read(databaseProvider).watchSettings().first).onboarded, isTrue);
  });

  test('replay shows it again and writes nothing', () async {
    final c = container(done: true);
    c.read(onboardingProvider.notifier).replay();

    expect(c.read(onboardingProvider), (done: true, replay: true));
    expect((await c.read(databaseProvider).watchSettings().first).onboarded, isFalse);
  });

  test('finish after a replay clears it', () async {
    final c = container(done: true);
    c.read(onboardingProvider.notifier).replay();
    await c.read(onboardingProvider.notifier).finish();

    expect(c.read(onboardingProvider), (done: true, replay: false));
  });
}
