import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDev = ref.watch(flavorProvider.select((config) => config.flavor.isDev));
    return Scaffold(
      body: SafeArea(
        child: AllPadding(
          padding: SpaceManager.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RegularText(
                StringsManager.tabMore,
                font: FontEnum.display,
                fontSize: FontSizeManager.largeTitle,
                height: LineHeightManager.largeTitle,
              ),
              const RSizedBox.vertical(SpaceManager.s4),
              // TODO: replaced by the 4.09 Qibla tile in milestone 9.
              BmButton.secondary(StringsManager.qibla, onPressed: () => context.push(Routes.qibla)),
              const RSizedBox.vertical(SpaceManager.s3),
              // TODO: replaced by the 4.09 Duas tile in milestone 9.
              BmButton.secondary(StringsManager.duas, onPressed: () => context.push(Routes.duas)),
              if (isDev) const _DevRow(),
            ],
          ),
        ),
      ),
    );
  }
}

/// dev builds only, until milestone 9 builds the real more page
class _DevRow extends StatelessWidget {
  const _DevRow();

  static const _label = 'Notifications (dev)';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push(Routes.devNotifications),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: SizeManager.listRow.r),
          child: const Align(
            alignment: AlignmentDirectional.centerStart,
            child: RegularText(
              _label,
              translate: false,
              fontSize: FontSizeManager.body,
              color: ThemeEnum.accent,
            ),
          ),
        ),
      ),
    );
  }
}
