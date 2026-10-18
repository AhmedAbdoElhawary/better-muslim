import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/home/view/widgets/dev_readout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDev = ref.watch(flavorProvider.select((config) => config.flavor.isDev));
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: AllPadding(
            padding: SpaceManager.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RegularText(
                  StringsManager.tabHome,
                  font: FontEnum.display,
                  fontSize: FontSizeManager.largeTitle,
                  height: LineHeightManager.largeTitle,
                ),
                if (isDev) ...[const RSizedBox.vertical(SpaceManager.s6), const DevReadout()],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
