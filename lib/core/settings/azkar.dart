import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// the azkar, duas and tasbih font, apart from the quran's. verses inside azkar keep the quran's
enum AzkarFont {
  amiri(StringsManager.azkarFontAmiri, FontEnum.dua),
  scheherazade(StringsManager.fontScheherazade, FontEnum.scheherazade),
  naskh(StringsManager.azkarFontNaskh, FontEnum.naskh);

  const AzkarFont(this.label, this.font);

  final String label;
  final FontEnum font;
}

final azkarFontProvider = Provider<FontEnum>(
  (ref) => ref.watch(
    settingsProvider.select((settings) => (settings.value?.azkarFont ?? AzkarFont.amiri).font),
  ),
);
