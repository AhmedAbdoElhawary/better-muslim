import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/last_read.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/providers.dart';

void main() {
  final now = DateTime(2026, 10, 15, 14, 10);

  ProviderContainer container() {
    final container = ProviderContainer(
      overrides: [...testOverrides(), clockProvider.overrideWithValue(() => now)],
    );
    addTearDown(container.dispose);
    container.listen(lastReadProvider, (_, _) {});
    return container;
  }

  test('a fresh store starts at Al-Fatiha 1, page 1, never read', () async {
    final c = container();
    await c.read(settingsProvider.future);
    expect(c.read(lastReadProvider), (ayah: const AyahKey(1, 1), page: 1, at: null));
  });

  test('save writes the ayah, the page and the time, and the provider follows', () async {
    final c = container();
    await c.read(settingsProvider.future);
    await c.read(saveLastReadProvider)(const AyahKey(2, 255), 42);
    await c.read(settingsProvider.future);
    await pumpEventQueue();

    expect(c.read(lastReadProvider), (ayah: const AyahKey(2, 255), page: 42, at: now));
  });
}
