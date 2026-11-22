import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/features/quran/presentation/providers/selection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;
  late Selection selection;

  setUp(() {
    container = ProviderContainer();
    container.listen(selectionProvider, (_, _) {});
    selection = container.read(selectionProvider.notifier);
  });

  tearDown(() => container.dispose());

  SelectionState state() => container.read(selectionProvider);

  /// a set in a record compares by identity
  void expectState({AyahKey? sheet, Set<AyahKey> chosen = const {}}) {
    expect(state().sheet, sheet);
    expect(state().chosen, chosen);
    expect(state().choosing, chosen.isNotEmpty);
  }

  test('a tap opens the sheet on one ayah, nothing chosen', () {
    selection.select(const AyahKey(2, 255));
    expectState(sheet: const AyahKey(2, 255));
  });

  test('a long press chooses the ayah and closes the sheet', () {
    selection
      ..select(const AyahKey(2, 255))
      ..startChoosing(const AyahKey(2, 256));
    expectState(chosen: {const AyahKey(2, 256)});
  });

  test('toggle adds and removes, the last one out ends choosing', () {
    selection
      ..startChoosing(const AyahKey(2, 255))
      ..toggle(const AyahKey(3, 18));
    expect(state().chosen, {const AyahKey(2, 255), const AyahKey(3, 18)});
    selection.toggle(const AyahKey(2, 255));
    expect(state().chosen, {const AyahKey(3, 18)});
    expect(state().choosing, isTrue);
    selection.toggle(const AyahKey(3, 18));
    expectState();
  });

  test('clear ends both', () {
    selection
      ..startChoosing(const AyahKey(2, 255))
      ..clear();
    expectState();
  });
}
