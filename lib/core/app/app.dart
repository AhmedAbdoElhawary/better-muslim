import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:better_muslim/core/audio/ui_sounds.dart';
import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/location/location_controller.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/design/bm_text.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/appearance.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/screen_util_init.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();

    /// after the first frame, so the saved location's times show before any gps work (FR-007)
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(locationControllerProvider).refresh(),
    );
    ref.listenManual(
      settingsProvider.select(
        (settings) => (haptics: settings.value?.haptics, uiSounds: settings.value?.uiSounds),
      ),
      (_, flags) {
        BmHaptics.enabled = flags.haptics ?? true;
        BmSounds.enabled = flags.uiSounds ?? false;
      },
      fireImmediately: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeId = ref.watch(themeIdProvider);
    final reduceMotion = ref.watch(
      settingsProvider.select((settings) => settings.value?.reduceMotion ?? false),
    );
    return AppScreenUtilInit(
      child: MaterialApp.router(
        onGenerateTitle: (context) => context.tr(StringsManager.appName),
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(themeId),
        darkTheme: AppTheme.dark(themeId),
        themeMode: ref.watch(themeModeProvider),
        themeAnimationDuration: BmMotion.standard,
        themeAnimationCurve: BmMotion.standardCurve,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: ref.watch(routerProvider),

        /// the in-app switch joins the os flag here, so every widget reads one flag (R4)
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: MediaQuery.disableAnimationsOf(context) || reduceMotion),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: bmMaxTextScale,
            child: ColoredBox(
              color: context.getColor(ThemeEnum.bg),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: SizeManager.maxContentWidth.w),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
