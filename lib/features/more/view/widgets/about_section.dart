import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/system/system_channel.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// acknowledgements, and the version that does nothing on tap (FR-033, FR-034)
class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const GroupedSection(label: StringsManager.sectionAbout, children: [_VersionRow()]);
  }
}

class _VersionRow extends StatefulWidget {
  const _VersionRow();

  @override
  State<_VersionRow> createState() => _VersionRowState();
}

class _VersionRowState extends State<_VersionRow> {
  final _version = SystemChannel.version();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _version,
      builder: (context, snapshot) => NavRow(
        icon: BmIcon.ui(BmUiIcon.more_h, size: SizeManager.iconList.r),
        title: StringsManager.version,
        value: snapshot.data,
        translateValue: false,
      ),
    );
  }
}
