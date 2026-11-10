import 'dart:math' as math;

import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/prayer_times/sky_state.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/design/bm_sky.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/resources/theme_sky.dart';
import 'package:better_muslim/core/settings/appearance.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_switcher.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/title_glow.dart';
import 'package:better_muslim/features/home/view/widgets/countdown.dart';
import 'package:better_muslim/features/home/view/widgets/date_line.dart';
import 'package:better_muslim/features/home/view/widgets/location_pill.dart';
import 'package:better_muslim/features/home/view/widgets/next_prayer_card.dart';
import 'package:better_muslim/features/home/view/widgets/no_location_card.dart';
import 'package:better_muslim/features/home/view/widgets/now_block.dart';
import 'package:better_muslim/features/home/view/widgets/prayer_strip.dart';
import 'package:better_muslim/features/home/view/widgets/shortcuts_card.dart';
import 'package:better_muslim/features/home/view/widgets/sky_events.dart';
import 'package:better_muslim/features/home/view/widgets/sky_header.dart';
import 'package:better_muslim/features/home/view/widgets/sky_labels.dart';
import 'package:better_muslim/features/home/view/widgets/verse_card.dart';
import 'package:better_muslim/features/home/view_model/home_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  final _controller = ScrollController();
  final _view = GlobalKey();
  final _card = GlobalKey();
  final _events = GlobalKey<SkyEventsState>();
  final _flight = CardFlight();
  final _slots = (name: GlobalKey(), countdown: GlobalKey());
  final _collapsed = ValueNotifier(false);

  /// the flying layer is built only off the top, its countdown ticks only then
  final _aloft = ValueNotifier(false);

  /// from each slot in the bar to where the card's name and countdown start flying, null until
  /// both are laid out
  final _from = ValueNotifier<({Offset name, Offset countdown})?>(null);

  /// 0 to 1 from the card reaching the bar until its name reaches the bar's title
  late final _progress = AnimationController(vsync: this);
  var _start = 0.0;
  var _end = 0.0;

  /// the page is often too short for the card to reach the bar, so it's at least this tall
  final _height = ValueNotifier(0.0);

  /// the glass comes in for the last part of the flight, so the text lands on it
  static const _glassAt = .7;

  bool get _reduce => MediaQuery.disableAnimationsOf(context);

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;

    /// a new page height ends the scroll inside layout, sizes can't be read until it's done
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onScroll(notification);
      });
      return false;
    }
    final view = _view.currentContext?.findRenderObject();
    final card = _card.currentContext?.findRenderObject() as RenderBox?;
    final name = _flight.name.currentContext?.findRenderObject() as RenderBox?;
    if (view == null || card == null || !card.attached) return false;
    final ScrollMetrics(:pixels, :maxScrollExtent, :viewportDimension) = notification.metrics;
    final top = MediaQuery.paddingOf(context).top;
    final bar = SizeManager.appBar.r;
    _start = pixels + card.localToGlobal(Offset.zero, ancestor: view).dy - top - bar;
    final end = name == null
        ? _start
        : pixels +
              name.localToGlobal(name.size.center(Offset.zero), ancestor: view).dy -
              top -
              bar / 2;
    _end = math.min(end, maxScrollExtent);

    /// not exact from one scroll to the next, and a change lays the page out again
    final height = name == null ? 0.0 : viewportDimension + end;
    if ((height - _height.value).abs() > 1) _height.value = height;
    final span = _end - _start;
    final progress = span > 0
        ? ((pixels - _start) / span).clamp(0.0, 1.0)
        : (pixels >= _end ? 1.0 : 0.0);
    _progress.value = progress;
    _aloft.value = progress > 0;
    _collapsed.value = progress >= _glassAt;
    if (progress == 0) {
      _from.value = null;
      _flight.flying.value = false;
    } else {
      _measure();

      /// the slots are built in this frame the first time
      if (_from.value == null) WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
    if (notification is ScrollEndNotification && !_reduce) _snap();
    return false;
  }

  void _measure() {
    final view = _view.currentContext?.findRenderObject();
    Offset? center(GlobalKey key) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (view == null || box == null || !box.hasSize) return null;
      return box.localToGlobal(box.size.center(Offset.zero), ancestor: view);
    }

    final (name, slotName) = (center(_flight.name), center(_slots.name));
    final (countdown, slotCountdown) = (center(_flight.countdown), center(_slots.countdown));
    if (!mounted ||
        _progress.value == 0 ||
        name == null ||
        slotName == null ||
        countdown == null ||
        slotCountdown == null) {
      return;
    }

    /// taken back to the flight's start, so the text keeps pace with the card until it lands
    final rise = Offset(0, _progress.value * (_end - _start));
    _from.value = (name: name - slotName + rise, countdown: countdown - slotCountdown + rise);
    _flight.flying.value = !_reduce;
  }

  /// a flight halfway doesn't stay, the scroll settles to its start or end like the large titles
  void _snap() {
    final progress = _progress.value;
    if (progress <= .01 || progress >= .99) return;
    final to = progress < .5 ? _start : _end;
    Future.microtask(() {
      if (!_controller.hasClients) return;
      _controller.animateTo(to, duration: BmMotion.standard, curve: BmMotion.standardCurve);
    });
  }

  void _toTop() {
    if (MediaQuery.disableAnimationsOf(context)) return _controller.jumpTo(0);
    _controller.animateTo(0, duration: BmMotion.standard, curve: BmMotion.standardCurve);
  }

  @override
  void dispose() {
    _controller.dispose();
    _collapsed.dispose();
    _aloft.dispose();
    _from.dispose();
    _height.dispose();
    _flight.flying.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = ref.watch(locationProvider.select((location) => location != null));
    return ValueListenableBuilder<bool>(
      valueListenable: _collapsed,
      builder: (context, collapsed, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        /// the top of every sky is dark, so the status bar stays light in both modes until the bar
        /// shows, then it follows the bar's glass
        value: hasLocation && collapsed && !context.isThemeDark
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        child: child!,
      ),
      child: Scaffold(
        body: Stack(
          key: _view,
          children: [
            /// the card moves with the layout too, not only the scroll
            NotificationListener<ScrollMetricsNotification>(
              onNotification: (notification) => _onScroll(notification.asScrollUpdate()),
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: SingleChildScrollView(
                  controller: _controller,
                  child: ValueListenableBuilder<double>(
                    valueListenable: _height,
                    builder: (context, height, child) => ConstrainedBox(
                      constraints: BoxConstraints(minHeight: height),
                      child: child,
                    ),

                    /// the tab bar's glass covers the bottom, the shortcuts end above it
                    child: SafeArea(
                      top: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Sky(collapsed: _collapsed, events: _events),
                          HorizontalPadding(
                            key: _card,
                            padding: SpaceManager.screen,
                            child: BmSwitcher(
                              child: hasLocation
                                  ? NextPrayerCard(key: const ValueKey(true), flight: _flight)
                                  : const NoLocationCard(key: ValueKey(false)),
                            ),
                          ),
                          BmSwitcher(
                            child: hasLocation
                                ? const OnlyPadding(
                                    top: SpaceManager.s4,
                                    start: SpaceManager.stripSide,
                                    end: SpaceManager.stripSide,
                                    child: PrayerStrip(),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const OnlyPadding(
                            top: SpaceManager.homeCardGap,
                            start: SpaceManager.screen,
                            end: SpaceManager.screen,
                            child: VerseCard(),
                          ),
                          const OnlyPadding(
                            top: SpaceManager.homeCardGap,
                            start: SpaceManager.screen,
                            end: SpaceManager.screen,
                            bottom: SpaceManager.s4,
                            child: ShortcutsCard(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (hasLocation) ...[
              PositionedDirectional(
                top: 0,
                start: 0,
                end: 0,
                child: _Bar(collapsed: _collapsed, onTap: _toTop),
              ),
              PositionedDirectional(
                top: 0,
                start: 0,
                end: 0,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _aloft,
                  builder: (context, aloft, child) => aloft ? child! : const SizedBox.shrink(),
                  child: _FlyingPrayer(
                    progress: _progress,
                    collapsed: _collapsed,
                    from: _from,
                    slots: _slots,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// the compact bar the next prayer lands on, a tap goes back to the top. the sky's lit bottom
/// glows under its glass, clipped to the bar so the cards below keep their colors
class _Bar extends ConsumerWidget {
  const _Bar({required this.collapsed, required this.onTap});

  final ValueListenable<bool> collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(skyStateProvider);
    final theme = ref.watch(themeIdProvider);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final glow = TitleGlow.legible(
      state == null ? context.getColor(ThemeEnum.sky3) : themeSky(theme)[state]!.bottom,
      bg: context.getColor(ThemeEnum.bg),
      surface: context.getColor(ThemeEnum.surface),
      text: context.getColor(ThemeEnum.text),
    );
    return ClipRect(
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: glow),
        duration: reduce ? BmMotion.standard : BmMotion.skyChange,
        curve: reduce ? Curves.linear : BmMotion.sacred,
        builder: (context, glow, child) => ValueListenableBuilder<bool>(
          valueListenable: collapsed,
          builder: (context, collapsed, _) => TitleGlow(
            color: glow,
            visible: collapsed,
            child: IgnorePointer(
              ignoring: !collapsed,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: CompactAppBar(
                  StringsManager.tabHome,
                  back: false,
                  collapsed: collapsed,
                  titleChild: const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// the card's name and countdown flying into the bar's title with the scroll and staying there.
/// above the bar, so they aren't under its glass while they land
class _FlyingPrayer extends ConsumerWidget {
  const _FlyingPrayer({
    required this.progress,
    required this.collapsed,
    required this.from,
    required this.slots,
  });

  final Animation<double> progress;
  final ValueListenable<bool> collapsed;
  final ValueListenable<({Offset name, Offset countdown})?> from;
  final ({GlobalKey name, GlobalKey countdown}) slots;

  static const _separator = ' · ';

  /// the card's font gives way to the bar's in the last part, like the large titles
  static const _fontFrom = .7;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayer = ref.watch(nextPrayerProvider.select((next) => next?.$1));
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (prayer == null) return const SizedBox.shrink();
    final font = CurvedAnimation(parent: progress, curve: const Interval(_fontFrom, 1));
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: _Slot(
            slotKey: slots.name,
            progress: progress,
            from: from,
            pick: (from) => from.name,
            scale:
                (isArabic ? FontSizeManager.titleAr : FontSizeManager.cardTitle) /
                FontSizeManager.title,
            child: Stack(
              alignment: Alignment.center,
              children: [
                FadeTransition(
                  opacity: ReverseAnimation(font),
                  child: RegularText(
                    prayer.nameKey,
                    font: FontEnum.display,
                    fontSize: FontSizeManager.title,
                    maxLines: 1,
                  ),
                ),
                FadeTransition(opacity: font, child: SemiBoldText(prayer.nameKey, maxLines: 1)),
              ],
            ),
          ),
        ),
        FadeTransition(
          opacity: font,
          child: const RegularText(
            _separator,
            translate: false,
            fontSize: FontSizeManager.title,
            color: ThemeEnum.text2,
          ),
        ),
        _Slot(
          slotKey: slots.countdown,
          progress: progress,
          from: from,
          pick: (from) => from.countdown,
          scale: FontSizeManager.countdown / FontSizeManager.title,
          child: const Countdown(fontSize: FontSizeManager.title),
        ),
      ],
    );
    return IgnorePointer(
      child: SafeArea(
        bottom: false,
        child: RSizedBox(
          height: SizeManager.appBar,
          child: HorizontalPadding(
            padding: SpaceManager.s2 + SizeManager.hit,
            child: ValueListenableBuilder<bool>(
              valueListenable: collapsed,
              builder: (context, collapsed, child) => ValueListenableBuilder(
                valueListenable: from,
                builder: (context, from, child) => switch (reduce) {
                  true => AnimatedOpacity(
                    opacity: collapsed ? 1 : 0,
                    duration: BmMotion.micro,
                    child: child,
                  ),
                  false when from == null => Visibility.maintain(visible: false, child: child!),
                  false => child!,
                },
                child: child,
              ),
              child: Center(child: row),
            ),
          ),
        ),
      ),
    );
  }
}

/// one flying part: from the card's spot and size to its own in the bar
class _Slot extends StatelessWidget {
  const _Slot({
    required this.slotKey,
    required this.progress,
    required this.from,
    required this.pick,
    required this.scale,
    required this.child,
  });

  /// on the transform itself, so its center is the slot's and not where it flies
  final GlobalKey slotKey;
  final Animation<double> progress;
  final ValueListenable<({Offset name, Offset countdown})?> from;
  final Offset Function(({Offset name, Offset countdown}) from) pick;

  /// the card's size over the bar's
  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: Listenable.merge([progress, from]),
      builder: (context, child) {
        final rest = 1 - progress.value;
        final value = from.value;
        final shift = reduce || value == null ? Offset.zero : pick(value) * rest;
        final size = reduce ? 1.0 : 1 + (scale - 1) * rest;
        return Transform(
          key: slotKey,
          alignment: Alignment.center,
          transform: Matrix4.translationValues(shift.dx, shift.dy, 0)
            ..scaleByDouble(size, size, 1, 1),
          child: child,
        );
      },
      child: child,
    );
  }
}

/// the sky's box ends where the card starts, the painter goes on 60 pt under the card. it grows
/// with the header text, and the arc keeps its place from the box's bottom
class _Sky extends ConsumerWidget {
  const _Sky({required this.collapsed, required this.events});

  final ValueListenable<bool> collapsed;
  final GlobalKey<SkyEventsState> events;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasLocation = ref.watch(locationProvider.select((location) => location != null));

    /// above 1.0 the text reaches the arc's side, so the arc and its top label go under it
    final scaled = MediaQuery.textScalerOf(context).scale(1) > 1;

    /// around the whole stack, the text above the sky would take the hit from anything under it
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTapUp: (details) => events.currentState?.tap(details.localPosition),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: (SizeManager.homeSkyHeight - SpaceManager.homeCardOverlap).r,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: SkyHeader(overlap: SpaceManager.homeCardOverlap.r)),
            Positioned.fill(
              child: SkyEvents(key: events, collapsed: collapsed),
            ),
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: BmMotion.standard,
                layoutBuilder: (current, previous) =>
                    Stack(fit: StackFit.expand, children: [...previous, ?current]),
                child: hasLocation ? const SkyLabels() : null,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _HeaderText(),
                if (scaled)
                  RSizedBox.vertical(
                    BmSunArc.radius +
                        SkyHeader.labelRoom(context) +
                        SkyHeader.horizonAboveBottom(context),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderText extends ConsumerWidget {
  const _HeaderText();

  /// the pill's hit area is taller than its drawing, the paddings give that back
  static const _hitInset = (SizeManager.hit - SizeManager.locationPill) / 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasLocation = ref.watch(locationProvider.select((location) => location != null));
    final bright = ref.watch(skyBrightProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final clear = context.getColor(ThemeEnum.transparent);
    final scrim = context.getColor(ThemeEnum.skyScrim);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        /// a 0 → 38% black scrim behind the header text on the bright skies. it fades out
        /// below the text instead of ending on a hard line
        Positioned.fill(
          child: _Scrim(
            bright: bright,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [clear, scrim],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: -SizeManager.skyScrimFade.r,
          height: SizeManager.skyScrimFade.r,
          child: _Scrim(
            bright: bright,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [scrim, clear],
                ),
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const OnlyPadding(
              top: SpaceManager.skyTextTop - _hitInset,
              start: SpaceManager.skyTextSide,
              end: SpaceManager.s5,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [LocationPill(), DateLine()],
              ),
            ),
            BmSwitcher(
              child: hasLocation
                  ? OnlyPadding(
                      top: (isArabic ? SpaceManager.nowTopAr : SpaceManager.nowTop) - _hitInset,
                      start: SpaceManager.s5,
                      end: SpaceManager.s5,
                      child: const NowBlock(),
                    )
                  : const SizedBox.shrink(),
            ),
            const RSizedBox.vertical(SpaceManager.s4),
          ],
        ),
      ],
    );
  }
}

/// the bright skies' scrim fades with the sky instead of popping in
class _Scrim extends StatelessWidget {
  const _Scrim({required this.bright, required this.child});
  final bool bright;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: bright ? 1 : 0,
      duration: MediaQuery.disableAnimationsOf(context) ? BmMotion.micro : BmMotion.standard,
      child: child,
    );
  }
}
