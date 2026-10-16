import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:flutter/material.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: AllPadding(
          padding: SpaceManager.screen,
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: RegularText(
              StringsManager.tabMore,
              font: FontEnum.display,
              fontSize: FontSizeManager.largeTitle,
              height: LineHeightManager.largeTitle,
            ),
          ),
        ),
      ),
    );
  }
}
