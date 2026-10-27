import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/last_read.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/appearance.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/system/system_channel.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:better_muslim/features/quran/domain/mushaf_layout.dart';
import 'package:better_muslim/features/quran/domain/recitation.dart';
import 'package:better_muslim/features/quran/presentation/providers/page_providers.dart';
import 'package:better_muslim/features/quran/presentation/providers/recitation_providers.dart';
import 'package:better_muslim/features/quran/presentation/providers/selection.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/ayah_share.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/ayah_sheet.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/choosing_bar.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mini_player.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mushaf_page_view.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/page_chrome.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/page_turn.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/recitation_sheet.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/ribbon.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/share_sheet.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/study_tabs.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/translation_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 4.19 to 4.23 and 4.07, the page in its layout and the ayah to wash. the whole reader takes the page's palette, and
/// follow sky crossfades it at isha and fajr
class ReaderPage extends ConsumerStatefulWidget {
  const ReaderPage({required this.page, this.ayah, super.key});

  final int page;
  final AyahKey? ayah;

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> with TickerProviderStateMixin {
  late final _page = ValueNotifier(widget.page);
  late final _card = AnimationController.unbounded(vsync: this);

  /// the medium and the large sheet, and how far the page goes up for the medium one
  late final _act = AnimationController.unbounded(vsync: this);
  late final _study = AnimationController.unbounded(vsync: this);
  late final _lift = AnimationController.unbounded(vsync: this);

  /// 4.25, the recitation sheet
  late final _recite = AnimationController.unbounded(vsync: this);
  bool _chrome = false;

  /// the sheets' ayah, kept while they slide away
  AyahKey? _ayah;
  StudyTab _tab = StudyTab.tafsir;

  /// the built pages, so the reader can ask one where an ayah sits
  final _pages = <int, GlobalKey>{};
  final _sheet = GlobalKey();
  final _reciteSheet = GlobalKey();

  /// read in initState, dispose can't reach ref
  late final Future<void> Function(AyahKey ayah, int page) _saveLastRead;
  late final Future<QuranAssets> _assets;
  QuranAssets? _loaded;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _saveLastRead = ref.read(saveLastReadProvider);
    _assets = ref.read(quranAssetsProvider.future)..then((assets) => _loaded = assets);
    ref.listenManual(
      settingsProvider.select((settings) => settings.value?.keepScreenOn ?? false),
      (_, on) => SystemChannel.keepScreenOn(on),
      fireImmediately: true,
    );
    ref.listenManual(playingAyahProvider, (_, ayah) => _follow(ayah), fireImmediately: true);
    ref.listenManual(recitationStateProvider.select((state) => state.value?.failure), (_, failure) {
      if (failure != null) _failed(failure);
    });
    ref.listenManual(recitationStateProvider.select((state) => state.value?.status), (_, status) {
      if (status == RecitationStatus.playing) _announce(StringsManager.recitationPlaying);
      if (status == RecitationStatus.paused) _announce(StringsManager.recitationPaused);
    });
    _page.addListener(_turned);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.ayah case final ayah? when mounted) _select(_page.value, ayah);
    });
  }

  /// a turn away from the selected ayah closes its sheet. while it plays, following is on only on
  /// the playing ayah's page, otherwise the page settled is last read
  Future<void> _turned() async {
    final page = _page.value;
    _pages.removeWhere((n, _) => (n - page).abs() > 1);
    final key = ref.read(selectionProvider).sheet;
    if (key != null && !(ref.read(mushafPageProvider(page)).value?.has(key) ?? false)) _close();
    final assets = await _assets;
    if (!mounted || page != _page.value) return;
    final digits = ref.read(settingsProvider).value?.digits ?? Digits.eastern;
    final surah = assets.surah(assets.pageInfo(page).start.surah);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    _announce(StringsManager.pageRef, {
      'surah': isArabic ? surah.ar : surah.en,
      'p': context.formatDigits('$page', digits),
    });
    final playing = ref.read(playingAyahProvider);
    if (playing != null) {
      ref
          .read(followingProvider.notifier)
          .set(following(shownPage: page, playingPage: assets.pageOf(readAyah(playing))));
    } else {
      await _saveLastRead(assets.pageInfo(page).start, page);
    }
  }

  /// the reader turns with the recitation while following, and keeps the ayah clear of 4.25
  Future<void> _follow(AyahKey? ayah) async {
    _playing = ayah != null;
    if (ayah == null) return;
    final assets = await _assets;
    if (!mounted) return;
    final page = assets.pageOf(readAyah(ayah));
    if (page != _page.value) {
      if (!ref.read(followingProvider)) return;
      _page.value = page;
    }
    if (_recite.value > .5) {
      _liftOver(ayah, _reciteSheet);
    } else {
      _reveal(readAyah(ayah));
    }
  }

  /// a page above 100% scrolls to the ayah being recited, the cells do it themselves
  void _reveal(AyahKey ayah) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final page = _pages[_page.value]?.currentContext?.findRenderObject();
      if (!mounted || page is! RenderMushafPage || !page.reflow) return;
      if (ref.read(settingsProvider).value?.quranLayout != QuranLayout.mushaf) return;
      if (page.washBounds(ayah) case final bounds?) {
        page.showOnScreen(
          rect: bounds,
          duration: bmMotion(MediaQuery.disableAnimationsOf(context), BmMotion.standard),
          curve: BmMotion.standardCurve,
        );
      }
    });
  }

  /// for screen readers, the page number on each turn and play and pause (FR-052)
  void _announce(String key, [Map<String, String> args = const {}]) {
    SemanticsService.sendAnnouncement(
      View.of(context),
      context.tr(key, args),
      Directionality.of(context),
    );
  }

  void _failed(RecitationFailure failure) {
    final state = ref.read(recitationStateProvider).value;
    final (ayah, to) = (state?.ayah, state?.to);
    if (failure == RecitationFailure.offline || ayah == null) {
      showToast(context, StringsManager.recitationOffline, icon: BmIconName.listen);
      return;
    }
    showToast(
      context,
      StringsManager.recitationFailed,
      icon: BmIconName.listen,
      action: StringsManager.tryAgain,
      onUndo: () => playFrom(context, ref, readAyah(ayah), to: to),
    );
  }

  void _play(AyahKey from) {
    _close();
    playFrom(context, ref, from);
  }

  Future<void> _listen() async {
    final assets = await _assets;
    if (mounted) playFrom(context, ref, assets.pageInfo(_page.value).start);
  }

  void _openRecitation() {
    _close();
    setState(() => _chrome = false);
    springTo(context, _card, 0);
    springTo(context, _recite, 1);
    if (ref.read(playingAyahProvider) case final ayah?) _liftOver(ayah, _reciteSheet);
  }

  void _closeRecitation() {
    springTo(context, _recite, 0);
    springTo(context, _lift, 0);
  }

  /// measured once the sheet is laid out
  void _liftOver(AyahKey key, GlobalKey sheet) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) springTo(context, _lift, _liftFor(key, sheet));
    });
  }

  /// a tap off the text closes the sheet, or the page springs to a card and back
  void _tap(TapUpDetails _) {
    if (ref.read(selectionProvider).choosing) return;
    if (ref.read(selectionProvider).sheet != null) {
      _close();
      return;
    }
    if (_recite.value > .5) {
      _closeRecitation();
      return;
    }
    setState(() => _chrome = !_chrome);
    springTo(context, _card, _chrome ? 1 : 0);
  }

  /// while choosing a tap checks or unchecks the ayah
  void _tapAyah(int page, AyahKey key) {
    if (ref.read(selectionProvider).choosing) {
      _toggle(key);
      return;
    }
    _select(page, key);
  }

  /// a long press starts choosing ayahs to share with this one checked (FR-015)
  void _longAyah(int page, AyahKey key) {
    final selection = ref.read(selectionProvider);
    if (selection.choosing) {
      if (!selection.chosen.contains(key)) _toggle(key);
      return;
    }
    if (page != _page.value) return;
    _close();
    BmHaptics.ayahSelect();
    ref.read(selectionProvider.notifier).startChoosing(key);
    setState(() => _chrome = false);
    springTo(context, _card, 0);
  }

  /// an ayah is added only while all of them still fit the card (FR-018)
  Future<void> _toggle(AyahKey key) async {
    final chosen = ref.read(selectionProvider).chosen;
    if (!chosen.contains(key)) {
      final assets = await _assets;
      final arabic = {
        for (final key in {...chosen, key}) key: await assets.ayahText(key),
      };
      if (!mounted) return;
      if (!AyahShare.canAdd(context, arabic)) {
        showToast(context, StringsManager.ayahDoesntFit, icon: BmIconName.quran);
        return;
      }
    }
    BmHaptics.selection();
    ref.read(selectionProvider.notifier).toggle(key);
  }

  void _shareChosen() {
    final keys = ref.read(selectionProvider).chosen.toList()..sort();
    ref.read(selectionProvider.notifier).clear();
    showAyahShare(context, keys);
  }

  void _select(int page, AyahKey key) {
    if (page != _page.value) return;
    BmHaptics.ayahSelect();
    ref.read(selectionProvider.notifier).select(key);
    setState(() {
      _ayah = key;
      _chrome = false;
    });
    springTo(context, _card, 0);
    springTo(context, _recite, 0);
    springTo(context, _act, 1);
    _liftOver(key, _sheet);
  }

  /// the cells scroll their ayah into view themselves, in Both too
  double _liftFor(AyahKey key, GlobalKey sheetKey) {
    final layout = ref.read(settingsProvider).value?.quranLayout ?? QuranLayout.mushaf;
    if (layout != QuranLayout.mushaf) return 0;
    final context = _pages[_page.value]?.currentContext;
    final page = context?.findRenderObject();
    var bounds = page is RenderMushafPage ? page.washBounds(key) : null;
    if (bounds == null) return 0;

    /// a page above 100% scrolls, the ayah comes into view first
    if (Scrollable.maybeOf(context!)?.position case final scroll?) {
      page!.showOnScreen(rect: bounds);
      bounds = bounds.shift(Offset(0, -scroll.pixels));
    }
    final sheet = sheetKey.currentContext?.size?.height ?? SizeManager.ayahSheet.r;
    return ayahLift(
      bottom: bounds.bottom,
      sheetTop: MediaQuery.sizeOf(context).height - sheet,
      gap: SpaceManager.ayahLift.r,
    );
  }

  void _openStudy(StudyTab tab) {
    setState(() => _tab = tab);
    springTo(context, _act, 0);
    springTo(context, _lift, 0);
    springTo(context, _study, 1);
  }

  /// back and forward on the large sheet, onto the ayah's page when it isn't this one
  void _move(AyahKey key) {
    ref.read(selectionProvider.notifier).select(key);
    setState(() => _ayah = key);
    if (ref.read(mushafPageProvider(_page.value)).value?.has(key) ?? false) return;
    if (ref.read(quranAssetsProvider).value case final assets?) _page.value = assets.pageOf(key);
  }

  void _close() {
    ref.read(selectionProvider.notifier).clear();
    springTo(context, _act, 0);
    springTo(context, _study, 0);
    springTo(context, _lift, 0);
  }

  @override
  void dispose() {
    SystemChannel.keepScreenOn(false);
    if (_loaded case final assets? when !_playing) {
      _saveLastRead(assets.pageInfo(_page.value).start, _page.value);
    }
    _page
      ..removeListener(_turned)
      ..dispose();
    _card.dispose();
    _act.dispose();
    _study.dispose();
    _lift.dispose();
    _recite.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = ref.watch(pageColorProvider).resolve(dark: context.isThemeDark);
    final themeId = ref.watch(themeIdProvider);
    final book = ref.watch(
      settingsProvider.select((settings) => settings.value?.pageTurn ?? PageTurn.book),
    );
    final layout = ref.watch(
      settingsProvider.select((settings) => settings.value?.quranLayout ?? QuranLayout.mushaf),
    );
    final selected = ref.watch(
      selectionProvider.select((selection) => selection.sheet != null || selection.choosing),
    );
    final choosing = ref.watch(selectionProvider.select((selection) => selection.choosing));
    final reduce = MediaQuery.disableAnimationsOf(context);
    final ayah = _ayah;
    return PopScope(
      canPop: !selected,
      onPopInvokedWithResult: (popped, _) {
        if (!popped) _close();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: color.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: AnimatedTheme(
          data: AppTheme.page(color, themeId),
          duration: bmMotion(reduce, BmMotion.skyChange),
          curve: BmMotion.sacred,
          child: _Reader(
            children: [
              /// the page's own tap shows the controls, its swipes turn it
              Semantics(
                label: context.tr(StringsManager.mushaf),
                child: PageTurner(
                  page: _page,
                  book: book == PageTurn.book,
                  card: _card,
                  recede: _study,
                  lift: _lift,
                  onTap: _tap,
                  pageBuilder: (n) => switch (layout) {
                    QuranLayout.mushaf => _MushafPage(
                      n,
                      pageKey: _pages.putIfAbsent(n, GlobalKey.new),
                      onAyah: (key) => _tapAyah(n, key),
                      onLongAyah: (key) => _longAyah(n, key),
                    ),

                    /// the page fills the screen, its cells scroll up under it
                    QuranLayout.translation => LayoutBuilder(
                      builder: (context, constraints) => TranslationView(
                        n,
                        onAyah: (key) => _tapAyah(n, key),
                        onLongAyah: (key) => _longAyah(n, key),
                        mushaf: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: _MushafPage(
                            n,
                            pageKey: _pages.putIfAbsent(n, GlobalKey.new),
                            onAyah: (key) => _tapAyah(n, key),
                            onLongAyah: (key) => _longAyah(n, key),
                            scrolls: false,
                          ),
                        ),
                      ),
                    ),
                  },
                ),
              ),
              PageChrome(page: _page, card: _card, shown: _chrome, onListen: _listen),
              Align(
                alignment: Alignment.bottomCenter,
                child: MiniPlayer(
                  card: _card,
                  activeDy: _chrome ? .1 : -.2,
                  onOpen: _openRecitation,
                ),
              ),
              _Dim(study: _study, onTap: _close),
              if (ayah != null) ...[
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AyahSheet(
                    key: _sheet,
                    ayah: ayah,
                    open: _act,
                    onClose: _close,
                    onStudy: _openStudy,
                    onPlay: () => _play(ayah),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: StudySheet(
                    ayah: ayah,
                    open: _study,
                    tab: _tab,
                    onTab: (tab) => setState(() => _tab = tab),
                    onMove: _move,
                    onClose: _close,
                  ),
                ),
              ],
              Align(
                alignment: Alignment.bottomCenter,
                child: RecitationSheet(key: _reciteSheet, open: _recite, onClose: _closeRecitation),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedSwitcher(
                  duration: bmMotion(reduce, BmMotion.standard),
                  switchInCurve: BmMotion.standardCurve,
                  switchOutCurve: BmMotion.standardCurve,
                  transitionBuilder: (child, animation) => reduce
                      ? FadeTransition(opacity: animation, child: child)
                      : SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 1),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                  child: choosing
                      ? ChoosingBar(onShare: _shareChosen, onCancel: _close)
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// the mushaf page with its ribbon. above 100% the page is taller than the screen and scrolls
class _MushafPage extends ConsumerWidget {
  const _MushafPage(
    this.page, {
    required this.pageKey,
    required this.onAyah,
    required this.onLongAyah,
    this.scrolls = true,
  });

  final int page;

  /// the reader asks the page where an ayah sits through it
  final GlobalKey pageKey;
  final ValueChanged<AyahKey> onAyah;
  final ValueChanged<AyahKey> onLongAyah;

  /// false in the translation list, which scrolls it already
  final bool scrolls;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reflow = ref.watch(
      settingsProvider.select((settings) => (settings.value?.mushafSize ?? 0) > 0),
    );
    Widget view = MushafPageView(page, key: pageKey, onAyah: onAyah, onLongAyah: onLongAyah);
    if (reflow && scrolls) {
      final child = view;
      view = LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        ),
      );
    }
    return Stack(fit: StackFit.passthrough, children: [view, PageRibbon(page)]);
  }
}

/// under the page theme, so the background is the page palette's
class _Reader extends StatelessWidget {
  const _Reader({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.getColor(ThemeEnum.bg),
      body: Stack(fit: StackFit.expand, children: children),
    );
  }
}

/// the scrim over the receded page, a tap on it closes the large sheet
class _Dim extends StatelessWidget {
  const _Dim({required this.study, required this.onTap});

  final Animation<double> study;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scrim = context.getColor(ThemeEnum.scrim);
    return AnimatedBuilder(
      animation: study,
      builder: (context, _) => IgnorePointer(
        ignoring: study.value < .5,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ColoredBox(
            color: scrim.withValues(alpha: SizeManager.pageDim * study.value.clamp(0.0, 1.0)),
          ),
        ),
      ),
    );
  }
}
