import 'package:better_muslim/core/widgets/share/share_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only gradients and the sky offer a solid color', () {
    expect(
      ShareBackground.values.where((background) => background.isGradient),
      containsAll([ShareBackground.sky, ShareBackground.midnight, ShareBackground.ocean]),
    );
    for (final background in [
      ShareBackground.paper,
      ShareBackground.night,
      ShareBackground.emerald,
      ShareBackground.deepSea,
    ]) {
      expect(background.isGradient, isFalse, reason: background.name);
    }
  });

  test('the solid color is the gradient middle stop', () {
    expect(ShareBackground.ocean.solidOf(), ShareBackground.ocean.colors[1]);
    expect(ShareBackground.deepSea.solidOf(), ShareBackground.deepSea.colors.single);
  });

  test('the options start on paper, square, amiri, no ornament, with the app name', () {
    const options = ShareOptions();
    expect(
      (options.background, options.size, options.sizeLocked, options.solid, options.ornament),
      (ShareBackground.paper, ShareSize.square, false, false, null),
    );
    expect(options.appName, isTrue);
    expect(options.copyWith(ornament: () => ShareOrnament.khatam).ornament, ShareOrnament.khatam);
    expect(
      options
          .copyWith(ornament: () => ShareOrnament.khatam)
          .copyWith(ornament: () => null)
          .ornament,
      isNull,
    );
  });
}
