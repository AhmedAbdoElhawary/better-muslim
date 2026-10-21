import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/widgets/adaptive/screen_util_init.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/page_turn.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// the pages built so far, a turn must never build one again
  late List<int> built;

  Future<ValueNotifier<int>> pumpTurner(
    WidgetTester tester, {
    int start = 1,
    bool book = true,
    bool reduceMotion = false,
  }) async {
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    built = [];
    final page = ValueNotifier(start);
    addTearDown(page.dispose);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData.fromView(tester.view).copyWith(disableAnimations: reduceMotion),
        child: AppScreenUtilInit(
          child: MaterialApp(
            theme: AppTheme.page(PageColor.paper),
            home: PageTurner(
              page: page,
              book: book,
              pageBuilder: (n) => _Page(n, onBuild: built.add),
            ),
          ),
        ),
      ),
    );
    return page;
  }

  /// slow, so only the distance decides
  Future<void> drag(WidgetTester tester, double dx) async {
    await tester.timedDrag(find.byType(PageTurner), Offset(dx, 0), const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  testWidgets('a drag to the right past the share opens the next page', (tester) async {
    final page = await pumpTurner(tester, start: 5);
    await drag(tester, 393 * (BmMotion.completeShare + .1));
    expect(page.value, 6);
  });

  testWidgets('a short slow drag springs back to the same page', (tester) async {
    final page = await pumpTurner(tester, start: 5);
    await drag(tester, 393 * (BmMotion.completeShare - .1));
    expect(page.value, 5);
  });

  testWidgets('a drag to the left lays the previous page back', (tester) async {
    final page = await pumpTurner(tester, start: 5);
    await drag(tester, -393 * .6);
    expect(page.value, 4);
  });

  testWidgets('a quick flick turns even when short', (tester) async {
    final page = await pumpTurner(tester, start: 5);
    await tester.fling(find.byType(PageTurner), const Offset(60, 0), BmMotion.completeVelocity * 2);
    await tester.pumpAndSettle();
    expect(page.value, 6);
  });

  testWidgets('a tap on the left edge opens the next page, elsewhere it does not', (tester) async {
    final page = await pumpTurner(tester, start: 5);
    await tester.tapAt(const Offset(20, 400));
    await tester.pumpAndSettle();
    expect(page.value, 6);
    await tester.tapAt(const Offset(200, 400));
    await tester.pumpAndSettle();
    expect(page.value, 6);
  });

  testWidgets('the first and the last page rubber band and stay', (tester) async {
    final first = await pumpTurner(tester);
    await drag(tester, -393 * .8);
    expect(first.value, 1);

    final last = await pumpTurner(tester, start: quranPageCount);
    await drag(tester, 393 * .8);
    expect(last.value, quranPageCount);
  });

  testWidgets('slide turns in 300 ms and reduce motion crossfades in 150 ms', (tester) async {
    final slide = await pumpTurner(tester, start: 5, book: false);
    await tester.tapAt(const Offset(20, 400));
    await tester.pump();
    await tester.pump(BmMotion.pageSlide + const Duration(milliseconds: 1));
    expect(slide.value, 6);

    final reduced = await pumpTurner(tester, start: 5, reduceMotion: true);
    await tester.tapAt(const Offset(20, 400));
    await tester.pump();
    await tester.pump(BmMotion.micro + const Duration(milliseconds: 1));
    expect(reduced.value, 6);
  });

  testWidgets('only the page and its two neighbours are built, once each', (tester) async {
    final page = await pumpTurner(tester, start: 5);
    await tester.pumpAndSettle();
    expect(built.toSet(), {4, 5, 6});
    built.clear();

    await drag(tester, 393 * .6);
    expect(page.value, 6);
    expect(built, [7], reason: 'the pages already there keep their elements');
  });
}

class _Page extends StatefulWidget {
  const _Page(this.n, {required this.onBuild});

  final int n;
  final ValueChanged<int> onBuild;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  @override
  void initState() {
    super.initState();
    widget.onBuild(widget.n);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
