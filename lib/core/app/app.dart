import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_text.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/widgets/adaptive/screen_util_init.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScreenUtilInit(
      child: MaterialApp.router(
        onGenerateTitle: (context) => context.tr(StringsManager.appName),
        debugShowCheckedModeBanner: false,
        // TODO: read the chosen theme and mode from settings (milestone 9)
        theme: AppTheme.light(BmThemeId.qiyamEmerald),
        darkTheme: AppTheme.dark(BmThemeId.qiyamEmerald),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: ref.watch(routerProvider),
        builder: (context, child) => MediaQuery.withClampedTextScaling(
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
    );
  }
}
