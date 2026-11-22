import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/system/system_channel.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:better_muslim/features/more/model/contact.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// credits, and the version that does nothing on tap (FR-033, FR-034)
class AboutSection extends StatelessWidget {
  const AboutSection({this.contact = Contact.mine, super.key});
  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final privacyPolicy = contact.privacyPolicyUrl;
    return GroupedSection(
      label: StringsManager.sectionAbout,
      children: [
        NavRow(
          icon: BmIcon.ui(BmUiIcon.note, size: SizeManager.iconList.r),
          title: StringsManager.credits,
          heroTag: Routes.credits,
          onTap: () => context.push(Routes.credits),
        ),
        if (privacyPolicy != null)
          NavRow(
            icon: BmIcon.ui(BmUiIcon.contents, size: SizeManager.iconList.r),
            title: StringsManager.privacyPolicy,
            onTap: () => SystemChannel.openUrl(privacyPolicy),
          ),
        const _VersionRow(),
      ],
    );
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
