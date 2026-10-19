import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/search_field.dart';
import 'package:better_muslim/features/duas/model/dua.dart';
import 'package:better_muslim/features/duas/view/widgets/category_rows.dart';
import 'package:better_muslim/features/duas/view/widgets/clip_guard.dart';
import 'package:better_muslim/features/duas/view/widgets/dua_card.dart';
import 'package:better_muslim/features/duas/view/widgets/dua_cards.dart';
import 'package:better_muslim/features/duas/view/widgets/dua_chips.dart';
import 'package:better_muslim/features/duas/view/widgets/empty_state.dart';
import 'package:better_muslim/features/duas/view_model/duas_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 4.14, pushed from more with no tab bar. it scrolls, so large text never cuts it
class DuasPage extends ConsumerWidget {
  const DuasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ClipGuard(
        child: Column(
          children: [
            const CompactAppBar(StringsManager.duas),
            Expanded(
              child: SingleChildScrollView(
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const RSizedBox.vertical(SpaceManager.s2),
                      HorizontalPadding(
                        padding: SpaceManager.screen,
                        child: SearchField(
                          hint: StringsManager.searchDuas,
                          onChanged: ref.read(duaQueryProvider.notifier).change,
                        ),
                      ),

                      /// the tree's 12 and 16 around the chips, less their 44 pt hit box
                      const RSizedBox.vertical(SpaceManager.s2),
                      const DuaChips(),
                      const RSizedBox.vertical(SpaceManager.s3),
                      const _Content(),
                      const RSizedBox.vertical(SpaceManager.screen),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// the chip's card and rows, the saved duas, or the search results while there is a query
class _Content extends ConsumerWidget {
  const _Content();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searching = ref.watch(duaQueryProvider.select((query) => query.trim().isNotEmpty));
    final chip = ref.watch(duaChipProvider);
    return HorizontalPadding(
      padding: SpaceManager.screen,
      child: searching
          ? const _Results()
          : chip == DuaChip.saved
          ? const _Saved()
          : const _ChipView(),
    );
  }
}

class _ChipView extends ConsumerWidget {
  const _ChipView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:card, :cardCategory, :rows) = ref.watch(duasViewProvider);
    if (card == null || cardCategory == null) {
      return const EmptyState(title: StringsManager.noDuasFound);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DuaCard(dua: card, category: cardCategory),
        if (rows.isNotEmpty) ...[
          const RSizedBox.vertical(SpaceManager.duaRowsTop),
          CategoryRows(rows),
        ],
      ],
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(duaResultsProvider);
    if (results.isEmpty) {
      return const EmptyState(
        title: StringsManager.noDuasFound,
        body: StringsManager.noDuasFoundBody,
      );
    }
    return DuaCards(results);
  }
}

class _Saved extends ConsumerWidget {
  const _Saved();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedDuasProvider);
    if (saved.isEmpty) {
      return const EmptyState(title: StringsManager.noSavedTitle, body: StringsManager.noSavedBody);
    }
    return DuaCards(saved);
  }
}
