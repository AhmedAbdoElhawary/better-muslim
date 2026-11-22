import 'package:better_muslim/core/azkar/azkar_content.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/empty_state.dart';
import 'package:better_muslim/core/widgets/title_glow.dart';
import 'package:better_muslim/features/duas/view/widgets/clip_guard.dart';
import 'package:better_muslim/features/duas/view/widgets/dua_cards.dart';
import 'package:better_muslim/features/duas/view_model/duas_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// a category's duas as cards. no png, built from the 4.14 card
class DuaCategoryPage extends ConsumerWidget {
  const DuaCategoryPage(this.id, {super.key});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(duasContentProvider).value ?? const [];
    final category = categories.where((category) => category.id == id).firstOrNull;
    final language = Localizations.localeOf(context).languageCode;
    return Scaffold(
      body: TitleGlow(
        child: ClipGuard(
          child: Column(
            children: [
              CompactAppBar(
                category?.name.inLanguage(language) ?? StringsManager.duas,
                translate: category == null,
                heroTag: Routes.duaCategory(id),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: REdgeInsets.all(SpaceManager.screen),
                  child: SafeArea(
                    top: false,
                    child: category == null
                        ? const EmptyState(title: StringsManager.noDuasFound)
                        : DuaCards([for (final dua in category.duas) (dua, category)]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
