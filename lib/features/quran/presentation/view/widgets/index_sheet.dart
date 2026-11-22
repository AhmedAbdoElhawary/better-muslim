import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/surah_index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// the reader's Index: the Quran tab's surahs, juz and pages, the page tapped or null
Future<int?> showIndexSheet(BuildContext context, int page) =>
    showBmSheet<int>(context, builder: (_) => _IndexSheet(page));

class _IndexSheet extends ConsumerStatefulWidget {
  const _IndexSheet(this.page);

  final int page;

  @override
  ConsumerState<_IndexSheet> createState() => _IndexSheetState();
}

class _IndexSheetState extends ConsumerState<_IndexSheet> {
  /// the current surah's row near the top, rows are their minimum height at text scale 1
  late final _scroll = ScrollController(
    initialScrollOffset: switch (ref.read(quranAssetsProvider).value) {
      final assets? => (assets.pageInfo(widget.page).start.surah - 1) * SizeManager.surahRow.r,
      null => 0,
    },
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: CustomScrollView(
        controller: _scroll,
        slivers: [
          SurahIndex(current: widget.page, onPick: (page) => Navigator.of(context).pop(page)),
        ],
      ),
    );
  }
}
