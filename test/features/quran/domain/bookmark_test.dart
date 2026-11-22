import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/features/quran/domain/bookmark.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Bookmark bookmark({AyahKey? ayah, required int page}) => Bookmark(
    id: 1,
    ayah: ayah,
    page: page,
    category: 1,
    color: CategoryColor.primary,
    createdAt: DateTime(2026),
  );

  test(
    'in the 1405H print a bookmark shows on its page there and is kept on the 1421H one',
    () async {
      final assets = await QuranAssets.load();

      /// 80:41 is on 1421H 586 and 1405H 585
      final ayah = bookmark(ayah: const AyahKey(80, 41), page: 586);
      expect(ayah.shownIn(assets.v1).page, 585);
      expect(ayah.shownIn(assets.v1).storedIn(assets.v1), ayah);

      /// a page bookmark goes through the page's first ayah
      final page = bookmark(page: 586);
      expect(page.shownIn(assets.v1).page, 585);
      expect(bookmark(page: 121).shownIn(assets.v1).storedIn(assets.v1).page, 121);

      expect(ayah.shownIn(assets), ayah);
      expect(page.storedIn(assets), page);
    },
  );
}
