import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// every package's license paragraphs, by package name, read once from flutter's registry
Future<Map<String, List<LicenseParagraph>>> _readLicenses() async {
  final byPackage = <String, List<LicenseParagraph>>{};
  await for (final entry in LicenseRegistry.licenses) {
    for (final package in entry.packages) {
      byPackage.putIfAbsent(package, () => []).addAll(entry.paragraphs);
    }
  }
  return Map.fromEntries(byPackage.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
}

/// one row per package, built from the grouped rows instead of material's license page (R14)
class LicensesPage extends StatefulWidget {
  const LicensesPage({super.key});

  @override
  State<LicensesPage> createState() => _LicensesPageState();
}

class _LicensesPageState extends State<LicensesPage> {
  final _licenses = _readLicenses();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const CompactAppBar(StringsManager.openSourceLicenses),
          Expanded(
            child: FutureBuilder(
              future: _licenses,
              builder: (context, snapshot) => ListView(
                padding: REdgeInsets.all(SpaceManager.screen),
                children: [
                  if (snapshot.data case final licenses?)
                    GroupedSection(
                      children: [
                        for (final package in licenses.keys)
                          NavRow(
                            title: package,
                            translateTitle: false,
                            onTap: () => context.push(Routes.license(package)),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PackageLicensePage extends StatefulWidget {
  const PackageLicensePage(this.package, {super.key});
  final String package;

  @override
  State<PackageLicensePage> createState() => _PackageLicensePageState();
}

class _PackageLicensePageState extends State<PackageLicensePage> {
  final _licenses = _readLicenses();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CompactAppBar(widget.package, translate: false),
          Expanded(
            child: FutureBuilder(
              future: _licenses,
              builder: (context, snapshot) {
                final paragraphs = snapshot.data?[widget.package] ?? const [];
                return ListView.builder(
                  padding: REdgeInsets.all(SpaceManager.screen),
                  itemCount: paragraphs.length,
                  itemBuilder: (context, index) => _Paragraph(paragraphs[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.paragraph);
  final LicenseParagraph paragraph;

  @override
  Widget build(BuildContext context) {
    final centered = paragraph.indent == LicenseParagraph.centeredIndent;
    return OnlyPadding(
      start: centered ? 0 : paragraph.indent * SpaceManager.s4,
      bottom: SpaceManager.s3,
      child: RegularText(
        paragraph.text,
        translate: false,
        color: ThemeEnum.text2,
        textAlign: centered ? TextAlign.center : null,
      ),
    );
  }
}
