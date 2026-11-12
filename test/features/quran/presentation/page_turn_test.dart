import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/widgets/adaptive/screen_util_init.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/page_curl.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/page_turn.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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

    /// the pages around come one frame each
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }
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

  testWidgets('the left strip opens the next page, the right one the previous, not between', (
    tester,
  ) async {
    for (final book in [true, false]) {
      final page = await pumpTurner(tester, start: 5, book: book);
      await tester.tapAt(const Offset(20, 400));
      await tester.pumpAndSettle();
      expect(page.value, 6);
      await tester.tapAt(const Offset(373, 400));
      await tester.pumpAndSettle();
      expect(page.value, 5);
      await tester.tapAt(const Offset(60, 400));
      await tester.pumpAndSettle();
      expect(page.value, 5, reason: 'past the 44 pt strip');
    }
  });

  testWidgets('the strips stay on the first and the last page', (tester) async {
    final first = await pumpTurner(tester);
    await tester.tapAt(const Offset(373, 400));
    await tester.pumpAndSettle();
    expect(first.value, 1);

    final last = await pumpTurner(tester, start: quranPageCount);
    await tester.tapAt(const Offset(20, 400));
    await tester.pumpAndSettle();
    expect(last.value, quranPageCount);
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

  testWidgets('only the page and two each side are built, once each', (tester) async {
    final page = await pumpTurner(tester, start: 5);
    await tester.pumpAndSettle();
    expect(built.toSet(), {3, 4, 5, 6, 7});
    built.clear();

    await drag(tester, 393 * .6);
    expect(page.value, 6);
    expect(built, isEmpty, reason: 'nothing is laid out around the end of a turn');

    await tester.pump(BmMotion.standard);
    await tester.pumpAndSettle();
    expect(built, [8], reason: 'the pages already there keep their elements');
  });

  testWidgets('a turn still settling never blocks the next one', (tester) async {
    for (final book in [true, false]) {
      final page = await pumpTurner(tester, start: 5, book: book);
      for (var i = 0; i < 3; i++) {
        await tester.tapAt(const Offset(20, 400));
        await tester.pump(const Duration(milliseconds: 60));
      }
      expect(page.value, 7, reason: 'each tap lands the turn before it');
      await tester.pumpAndSettle();
      expect(page.value, 8);

      await tester.tapAt(const Offset(20, 400));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.timedDrag(
        find.byType(PageTurner),
        const Offset(393 * .6, 0),
        const Duration(milliseconds: 300),
      );
      await tester.pumpAndSettle();
      expect(page.value, 10, reason: 'a grab mid turn turns one more');
    }
  });

  /// the layers between the turner and the page, the ones that soften it on android (R11)
  List<Widget> layersAbove(WidgetTester tester, int n) {
    final layers = <Widget>[];
    tester
        .element(find.byWidgetPredicate((widget) => widget is _Page && widget.n == n))
        .visitAncestorElements((element) {
          if (element.widget is PageTurner) return false;
          if (element.widget case Transform() || Opacity() || AnimatedOpacity()) {
            layers.add(element.widget);
          }
          return true;
        });
    return layers;
  }

  testWidgets('the shown page is built first, then one neighbour a frame', (tester) async {
    built = [];
    final page = ValueNotifier(5);
    addTearDown(page.dispose);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData.fromView(tester.view),
        child: AppScreenUtilInit(
          child: MaterialApp(
            theme: AppTheme.page(PageColor.paper),
            home: PageTurner(
              page: page,
              pageBuilder: (n) => _Page(n, onBuild: built.add),
            ),
          ),
        ),
      ),
    );
    expect(built, [5]);
    await tester.pump();
    expect(built, [5, 6]);
    await tester.pump();
    expect(built, [5, 6, 4]);
    await tester.pump();
    await tester.pump();
    expect(built, [5, 6, 4, 7, 3]);
    await tester.pump();
    expect(built, [5, 6, 4, 7, 3], reason: 'nothing more once all are there');
  });

  testWidgets('a settled page has no transform or opacity above it', (tester) async {
    final book = await pumpTurner(tester, start: 5);
    expect(layersAbove(tester, 5), isEmpty);
    await drag(tester, 393 * .6);
    expect(book.value, 6);
    expect(layersAbove(tester, 6), isEmpty);

    final slide = await pumpTurner(tester, start: 5, book: false);
    await tester.pump(BmMotion.standard);
    await tester.pumpAndSettle();
    built.clear();
    await drag(tester, 393 * .6);
    expect(slide.value, 6);
    expect(layersAbove(tester, 6), isEmpty);
    await tester.pump(BmMotion.standard);
    await tester.pumpAndSettle();
    expect(built, [8], reason: 'the wrappers come and go, the pages stay');
  });

  testWidgets('book curls a picture of the leaf and lets it go when the page settles', (
    tester,
  ) async {
    final page = await pumpTurner(tester, start: 5);
    final gesture = await tester.startGesture(const Offset(200, 600));
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
    }
    expect(find.byType(PageCurl), findsOneWidget);
    final image = tester.widget<PageCurl>(find.byType(PageCurl)).image;
    await gesture.up();
    await tester.pumpAndSettle();
    expect(page.value, 5, reason: 'a short drag still falls back with the curl');
    expect(find.byType(PageCurl), findsNothing);
    expect(image.debugDisposed, isTrue);
  });

  testWidgets('the turn back curls the previous page too', (tester) async {
    final page = await pumpTurner(tester, start: 5);
    final gesture = await tester.startGesture(const Offset(200, 600));
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();
    }
    expect(find.byType(PageCurl), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(page.value, 4);
    expect(find.byType(PageCurl), findsNothing);
  });

  testWidgets('slide and reduce motion never curl', (tester) async {
    for (final (book, reduce) in [(false, false), (true, true)]) {
      await pumpTurner(tester, start: 5, book: book, reduceMotion: reduce);
      final gesture = await tester.startGesture(const Offset(200, 600));
      for (var i = 0; i < 6; i++) {
        await gesture.moveBy(const Offset(20, 0));
        await tester.pump();
      }
      expect(find.byType(PageCurl), findsNothing);
      await gesture.up();
      await tester.pumpAndSettle();
    }
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
