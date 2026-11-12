import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/last_read.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/quran/recitation_files.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
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
import 'package:drift/drift.dart' show Value;
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// 4.19 to 4.23 and 4.07, the page in its layout and the ayah to wash. the whole reader takes the page's palette, and
/// follow sky crossfades it at isha and fajr
class ReaderPage extends ConsumerStatefulWidget {
  const ReaderPage({required this.page, this.ayah, this.recite = false, super.key});

  final int page;
  final AyahKey? ayah;

  /// the Quran tab's Listen, the recitation sheet rises once the reader is open
  final bool recite;

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

  /// the translation scrolling back up before the layout switches, its button is already off
  bool _hiding = false;

  /// the page the Translation button turned on
  int? _entering;

  /// 4.25 opened, its sheet is built right away
  bool _reciting = false;

  /// in the translation, whether the recitation follows the cells or the mushaf page above them
  final _followCells = ValueNotifier(false);

  /// the sheets' ayah, kept while they slide away
  AyahKey? _ayah;

  /// the Ayah sheet of the ayah the reader opened at, until it rises
  Timer? _waiting;
  StudyTab _tab = StudyTab.tafsir;

  /// the built pages, so the reader can ask one where an ayah sits. one per layout, a page moved
  /// between the two under a sheet left the reader's semantics pointing at the old one
  final _pages = <(int, QuranLayout), GlobalKey>{};
  final _turner = GlobalKey<PageTurnerState>();
  final _sheet = GlobalKey();
  final _reciteSheet = GlobalKey();

  /// read in initState, dispose can't reach ref
  late final Future<void> Function(AyahKey ayah, int page) _saveLastRead;
  late Future<QuranAssets> _assets;
  QuranAssets? _loaded;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _saveLastRead = ref.read(saveLastReadProvider);
    _assets = ref.read(quranAssetsProvider.future)..then((assets) => _loaded = assets);

    /// a switch to or from the 1405H print keeps the page's first ayah on screen
    ref.listenManual(quranAssetsProvider.select((assets) => assets.value), (old, assets) {
      if (old == null || assets == null || old == assets) return;
      _assets = Future.value(_loaded = assets);
      _page.value = assets.pageOf(old.pageInfo(_page.value).start);
    });
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
    ref.listenManual(settingsProvider.select((settings) => settings.value?.mushafStyle), (old, _) {
      if (old != null) _turner.currentState?.relayout();
    });
    ref.listenManual(settingsProvider.select((settings) => settings.value?.quranLayout), (_, _) {
      setState(() => _hiding = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _entering = null);
    });
    _page.addListener(_turned);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.ayah case final ayah?) _openAt(ayah);
      if (widget.recite) _whenOpen(_openRecitation);
    });
  }

  /// the sheet rising with the route's own move dropped frames of both
  void _whenOpen(VoidCallback then) {
    final route = ModalRoute.of(context)?.animation;
    if (route == null || route.isCompleted) return then();
    void opened(AnimationStatus status) {
      if (!status.isCompleted) return;
      route.removeStatusListener(opened);
      if (mounted) then();
    }

    route.addStatusListener(opened);
  }

  /// a turn away from the selected ayah closes its sheet. while it plays, following is on only on
  /// the playing ayah's page, otherwise the page settled is last read
  Future<void> _turned() async {
    final page = _page.value;

    /// the turner keeps two pages each side built, a new key would build one again
    _pages.removeWhere((key, _) => (key.$1 - page).abs() > 2);
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

    /// picked before a turn, the next page keeps the part that was being read
    final translation = ref.read(settingsProvider).value?.quranLayout == QuranLayout.translation;
    _followCells.value = translation && !_onPage();
    final assets = await _assets;
    if (!mounted) return;
    final page = assets.pageOf(readAyah(ayah));
    if (page != _page.value) {
      if (!ref.read(followingProvider)) return;
      _page.value = page;
    }

    /// a sheet still rising for a recitation that just started counts as up
    if (_recite.value > .5 || _recite.velocity > 0) {
      _liftOver(ayah, _reciteSheet, onPage: translation && !_followCells.value);
    } else {
      _reveal(readAyah(ayah), layout: translation ? QuranLayout.translation : QuranLayout.mushaf);
    }
  }

  /// only the mushaf page on screen in the translation, none of the cells under it
  bool _onPage() {
    final context = _pages[(_page.value, QuranLayout.translation)]?.currentContext;
    final page = context?.findRenderObject();
    final scroll = context == null ? null : Scrollable.maybeOf(context)?.position;
    if (page is! RenderBox || !page.hasSize || scroll == null || !scroll.hasContentDimensions) {
      return true;
    }
    return scroll.pixels + scroll.viewportDimension <= page.size.height + 1;
  }

  /// a page taller than the screen scrolls to the ayah being recited. in the translation only
  /// while it follows the page, the cells do it themselves
  void _reveal(AyahKey ayah, {required QuranLayout layout}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final page = _pages[(_page.value, layout)]?.currentContext?.findRenderObject();
      if (!mounted || page is! RenderMushafPage) return;
      if (ref.read(settingsProvider).value?.quranLayout != layout) return;
      if (layout == QuranLayout.mushaf ? !page.reflow : _followCells.value) return;
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

  /// a recitation starts with its sheet up
  void _play(AyahKey from) {
    _openRecitation();
    playFrom(context, ref, from);
  }

  Future<void> _listen() async {
    final assets = await _assets;
    if (mounted) _play(assets.pageInfo(_page.value).start);
  }

  void _openRecitation() {
    _close();
    setState(() {
      _chrome = false;
      _reciting = true;
    });
    springTo(context, _card, 0);
    springTo(context, _recite, 1);
    if (ref.read(playingAyahProvider) case final ayah?) _liftOver(ayah, _reciteSheet);
  }

  void _closeRecitation() {
    springTo(context, _recite, 0);
    springTo(context, _lift, 0);
  }

  /// measured once the sheet is laid out
  void _liftOver(AyahKey key, GlobalKey sheet, {bool onPage = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) springTo(context, _lift, _liftFor(key, sheet, onPage: onPage));
    });
  }

  /// a tap on the page or its words closes an open sheet, or the controls slide in over the page
  void _tap(TapUpDetails _) {
    if (_closeSheets() || ref.read(selectionProvider).choosing) return;
    setState(() => _chrome = !_chrome);
    springTo(context, _card, _chrome ? 1 : 0);
  }

  /// only this tap scrolls the translation in and out, an open or a turn shows the whole page
  void _translation() {
    BmHaptics.selection();
    if (_hiding) return setState(() => _hiding = false);
    final on = ref.read(settingsProvider).value?.quranLayout != QuranLayout.mushaf;
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (on && !reduce) return setState(() => _hiding = true);
    if (!on && !reduce) _entering = _page.value;
    _layout(on ? QuranLayout.mushaf : QuranLayout.translation);
  }

  /// a result turns this reader, back from search leaves it as it was
  Future<void> _search() async {
    final hit = await context.push<(int, AyahKey?)>(Routes.quranSearchFromReader);
    if (hit == null || !mounted) return;
    final (page, ayah) = hit;
    _page.value = page;
    if (ayah == null) return;

    /// once the page is built, the sheet lifts it from where the ayah sits
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openAt(ayah);
    });
  }

  void _layout(QuranLayout layout) {
    ref.read(databaseProvider).updateSettings(SettingsCompanion(quranLayout: Value(layout)));
  }

  /// with a sheet open a Turn strip only closes it
  void _edge(int direction) {
    if (!_closeSheets()) _turner.currentState?.turn(direction);
  }

  /// whether a sheet was open. a tap before the opened at ayah's sheet rises only drops its wash
  bool _closeSheets() {
    if (_waiting?.isActive ?? false) {
      _close();
      return false;
    }
    if (ref.read(selectionProvider).sheet != null) {
      _close();
      return true;
    }
    if (_recite.value > .5) {
      _closeRecitation();
      return true;
    }
    return false;
  }

  /// a long press or a double tap, opening the reader at an ayah has no haptic. [onPage] is a press
  /// on the mushaf page, which keeps the translation layout on the page
  void _openAyah(int page, AyahKey key, {bool onPage = false}) {
    if (page != _page.value) return;
    BmHaptics.ayahSelect();
    _select(key, onPage: onPage);
  }

  /// Share on the sheet starts choosing ayahs to share with this one checked (FR-015)
  void _share(AyahKey key) {
    _close();
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

    /// from under the page's theme, the sheet is drawn in the page color
    showAyahShare(_turner.currentContext ?? context, keys);
  }

  /// the ayah washed with its page, its sheet rising on its own once the page has been seen
  void _openAt(AyahKey key) {
    ref.read(selectionProvider.notifier).select(key);
    setState(() => _ayah = key);
    _whenOpen(() => _waiting = Timer(BmMotion.ayahSheetWait, () => _select(key)));
  }

  /// a finger on the page drops the opened at ayah's wash before its sheet rises
  void _down(PointerDownEvent _) {
    if (_waiting?.isActive ?? false) _close();
  }

  void _select(AyahKey key, {bool onPage = false}) {
    _waiting?.cancel();
    if (!mounted) return;
    ref.read(selectionProvider.notifier).select(key);
    setState(() {
      _ayah = key;
      _chrome = false;
    });
    springTo(context, _card, 0);
    springTo(context, _recite, 0);
    springTo(context, _act, 1);
    _liftOver(key, _sheet, onPage: onPage);
  }

  /// the cells scroll their ayah into view themselves, an ayah pressed on the translation's page
  /// lifts like on the mushaf
  double _liftFor(AyahKey key, GlobalKey sheetKey, {bool onPage = false}) {
    final layout = ref.read(settingsProvider).value?.quranLayout ?? QuranLayout.mushaf;
    if (layout != QuranLayout.mushaf && !onPage) return 0;
    final context = _pages[(_page.value, layout)]?.currentContext;
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
    _waiting?.cancel();
    ref.read(selectionProvider.notifier).clear();
    springTo(context, _act, 0);
    springTo(context, _study, 0);
    springTo(context, _lift, 0);
  }

  @override
  void dispose() {
    SystemChannel.keepScreenOn(false);
    _waiting?.cancel();
    if (_loaded case final assets? when !_playing) {
      _saveLastRead(assets.pageInfo(_page.value).start, _page.value);
    }
    _page
      ..removeListener(_turned)
      ..dispose();
    _followCells.dispose();
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
              /// the page's own tap shows the controls, its swipes and Turn strips turn it
              Semantics(
                label: context.tr(StringsManager.mushaf),
                child: Listener(
                  onPointerDown: _down,
                  child: PageTurner(
                    key: _turner,
                    page: _page,
                    book: book == PageTurn.book,
                    lift: _lift,
                    onTap: _tap,
                    onEdge: _edge,
                    strip: layout == QuranLayout.translation
                        ? translationStrip(MediaQuery.sizeOf(context))
                        : null,
                    pageBuilder: (n) => switch (layout) {
                      QuranLayout.mushaf => _MushafPage(
                        n,
                        pageKey: _pages.putIfAbsent((n, layout), GlobalKey.new),
                        onAyah: (key) => _openAyah(n, key),
                        onCheck: choosing ? _toggle : null,
                      ),

                      QuranLayout.translation => TranslationView(
                        n,
                        onAyah: (key) => _openAyah(n, key),
                        onCheck: choosing ? _toggle : null,
                        mushaf: _MushafPage(
                          n,
                          pageKey: _pages.putIfAbsent((n, layout), GlobalKey.new),
                          onAyah: (key) => _openAyah(n, key, onPage: true),
                          onCheck: choosing ? _toggle : null,
                          scrolls: false,
                        ),
                        shown: !_hiding,

                        /// the pages beside it are already up, only the shown one's scroll counts
                        onHidden: () {
                          if (n == _page.value) _layout(QuranLayout.mushaf);
                        },
                        entering: n == _entering,
                        followCells: _followCells,
                      ),
                    },
                  ),
                ),
              ),
              _Later(
                frames: 3,
                now: _chrome,
                child: PageChrome(
                  page: _page,
                  card: _card,
                  shown: _chrome,
                  onListen: _listen,
                  hiding: _hiding,
                  onTranslation: _translation,
                  onSearch: _search,
                ),
              ),
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
                    onShare: () => _share(ayah),
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
                child: _Later(
                  frames: 4,
                  now: _reciting,
                  child: RecitationSheet(
                    key: _reciteSheet,
                    open: _recite,
                    onClose: _closeRecitation,
                  ),
                ),
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

/// nothing until some frames after the reader is open, after the pages next to it, then its child.
/// built at once when the reader needs it sooner
class _Later extends StatefulWidget {
  const _Later({required this.frames, required this.now, required this.child});

  final int frames;
  final bool now;
  final Widget child;

  @override
  State<_Later> createState() => _LaterState();
}

class _LaterState extends State<_Later> {
  late bool _built = widget.now;
  var _waited = 0;

  @override
  void initState() {
    super.initState();
    _wait();
  }

  @override
  void didUpdateWidget(_Later oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.now) _built = true;
  }

  void _wait() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _built) return;
      if (ModalRoute.of(context)?.animation?.isCompleted ?? true) _waited++;
      if (_waited == widget.frames) {
        setState(() => _built = true);
        return;
      }
      SchedulerBinding.instance.scheduleFrame();
      _wait();
    });
  }

  @override
  Widget build(BuildContext context) => _built ? widget.child : const SizedBox.shrink();
}

/// the mushaf page with its ribbon. above 100% the page is taller than the screen and scrolls
class _MushafPage extends ConsumerWidget {
  const _MushafPage(
    this.page, {
    required this.pageKey,
    required this.onAyah,
    required this.onCheck,
    this.scrolls = true,
  });

  final int page;

  /// the reader asks the page where an ayah sits through it
  final GlobalKey pageKey;
  final ValueChanged<AyahKey> onAyah;
  final ValueChanged<AyahKey>? onCheck;

  /// false for the translation's page, it scrolls with the cells under it
  final bool scrolls;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reflow =
        scrolls &&
        ref.watch(settingsProvider.select((settings) => (settings.value?.mushafSize ?? 0) > 0));
    Widget view = MushafPageView(page, key: pageKey, onAyah: onAyah, onCheck: onCheck);
    if (reflow) {
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

/// the scrim over the page, a tap on it closes the large sheet
class _Dim extends StatelessWidget {
  const _Dim({required this.study, required this.onTap});

  final Animation<double> study;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scrim = context.getColor(ThemeEnum.scrim);
    return AnimatedBuilder(
      animation: study,
      builder: (context, _) {
        final value = study.value.clamp(0.0, 1.0);
        final dim = ColoredBox(color: scrim.withValues(alpha: SizeManager.pageDim * value));
        final sigma = SizeManager.backdropBlur * value;
        return IgnorePointer(
          ignoring: value < .5,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,

            /// no filter while closed, the page turns under it
            child: value == 0
                ? dim
                : BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                    child: dim,
                  ),
          ),
        );
      },
    );
  }
}
