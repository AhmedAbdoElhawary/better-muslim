import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/core/widgets/bm_dialog.dart';
import 'package:better_muslim/core/widgets/bm_switcher.dart';
import 'package:better_muslim/core/widgets/share/swatch.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/sheet_title.dart';
import 'package:better_muslim/core/widgets/text_field.dart';
import 'package:better_muslim/features/quran/data/quran_store.dart';
import 'package:better_muslim/features/quran/domain/bookmark.dart';
import 'package:better_muslim/features/quran/domain/category.dart';
import 'package:better_muslim/features/quran/presentation/providers/saved_providers.dart';
import 'package:better_muslim/features/quran/presentation/view/bookmark_actions.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/ribbon.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/saved_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the ayah sheet's Bookmark and the top bar's: pick a category, make one, or remove the
/// bookmark. a long press on a category edits it
Future<void> showBookmarkPicker(BuildContext context, {AyahKey? ayah, int? page}) => showBmSheet(
  context,
  builder: (_) => _BookmarkPicker(ayah: ayah, page: page),
);

extension on CategoryColor {
  String get label => switch (this) {
    CategoryColor.primary => StringsManager.colorPrimary,
    CategoryColor.green => StringsManager.colorGreen,
    CategoryColor.teal => StringsManager.colorTeal,
    CategoryColor.blue => StringsManager.colorBlue,
    CategoryColor.violet => StringsManager.colorViolet,
    CategoryColor.rose => StringsManager.colorRose,
    CategoryColor.amber => StringsManager.colorAmber,
    CategoryColor.slate => StringsManager.colorSlate,
  };
}

class _BookmarkPicker extends ConsumerStatefulWidget {
  const _BookmarkPicker({this.ayah, this.page});

  /// one of them is set, a page bookmark has no ayah
  final AyahKey? ayah;
  final int? page;

  @override
  ConsumerState<_BookmarkPicker> createState() => _BookmarkPickerState();
}

class _BookmarkPickerState extends ConsumerState<_BookmarkPicker> {
  var _form = false;

  /// null on the form is a new category
  Category? _editing;

  Provider<Bookmark?> get _bookmark => switch (widget.ayah) {
    final ayah? => ayahBookmarkProvider(ayah),
    null => pageBookmarkProvider(widget.page!),
  };

  Future<void> _pick(int category) async {
    final store = ref.read(quranStoreProvider);
    BmHaptics.selection();
    if (ref.read(_bookmark) case final bookmark?) {
      await store.setCategory(bookmark.id, category);
    } else if (widget.ayah case final ayah?) {
      final page = (await ref.read(quranAssetsProvider.future)).pageOf(ayah);
      await store.addAyah(ayah, page, category: category);
    } else {
      await store.addPage(widget.page!, category: category);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _remove(Bookmark bookmark) async {
    await removeBookmark(context, ref, bookmark);
    if (mounted) Navigator.of(context).pop();
  }

  void _open(Category? category) => setState(() {
    _form = true;
    _editing = category;
  });

  void _back() => setState(() => _form = false);

  /// a new category takes the bookmark at once, an edited one goes back to the list
  Future<void> _save(String name, CategoryColor color) async {
    final store = ref.read(quranStoreProvider);
    if (_editing case final category?) {
      final isDefault = category.id == AppDatabase.defaultCategory;

      /// the default keeps following the app's language until I give it my own name
      final kept =
          isDefault && (name.trim().isEmpty || name == context.tr(StringsManager.bookmarks));
      await store.updateCategory(category.id, kept ? null : name, color);
      _back();
      return;
    }
    await _pick(await store.addCategory(name, color));
  }

  Future<void> _delete(Category category) async {
    final confirmed = await showBmDialog(
      context,
      title: StringsManager.deleteCategoryTitle,
      body: StringsManager.deleteCategoryBody,
      action: StringsManager.delete,
    );
    if (!confirmed) return;
    await ref.read(quranStoreProvider).deleteCategory(category.id);
    _back();
  }

  @override
  Widget build(BuildContext context) {
    final bookmark = ref.watch(_bookmark);
    final assets = ref.watch(quranAssetsProvider).value;
    if (assets == null) return const SizedBox.shrink();
    final ayah = widget.ayah;
    final editing = _editing;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: BottomPadding(
          padding: SpaceManager.s6,
          child: BmSwitcher(
            child: _form
                ? _CategoryForm(
                    key: ValueKey(editing?.id),
                    category: editing,
                    onSave: _save,
                    onDelete: editing == null || editing.id == AppDatabase.defaultCategory
                        ? null
                        : () => _delete(editing),
                  )
                : Column(
                    key: const ValueKey('list'),
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SheetTitle(
                        savedReference(
                          context,
                          ref,
                          assets,
                          ayah: ayah,
                          page: ayah == null ? widget.page! : assets.pageOf(ayah),
                        ),
                        translate: false,
                      ),
                      _Categories(
                        ticked: bookmark?.category,
                        onPick: _pick,
                        onEdit: _open,
                        onNew: () => _open(null),
                      ),
                      if (bookmark != null) ...[
                        const RSizedBox.vertical(SpaceManager.s4),
                        HorizontalPadding(
                          padding: SpaceManager.s5,
                          child: BmButton.text(
                            StringsManager.removeBookmark,
                            color: ThemeEnum.error,
                            onPressed: () => _remove(bookmark),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// each category with its color, name and count, then New category
class _Categories extends ConsumerWidget {
  const _Categories({
    required this.ticked,
    required this.onPick,
    required this.onEdit,
    required this.onNew,
  });

  final int? ticked;
  final ValueChanged<int> onPick;
  final ValueChanged<Category> onEdit;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final bookmarks = ref.watch(bookmarksProvider).value ?? const [];
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final category in categories)
          _Row(
            key: ValueKey(category.id),
            leading: RibbonShape(
              color: category.color.theme,
              width: SizeManager.savedRibbonW,
              height: SizeManager.savedRibbonH,
              notch: SizeManager.savedRibbonNotch,
            ),
            title: categoryName(context, category),
            count: context.formatDigits(
              '${bookmarks.where((bookmark) => bookmark.category == category.id).length}',
              digits,
            ),
            ticked: category.id == ticked,
            onTap: () => onPick(category.id),
            onLongPress: () => onEdit(category),
          ),
        _Row(
          leading: BmIcon.ui(BmUiIcon.plus, size: SizeManager.iconList.r),
          title: context.tr(StringsManager.newCategory),
          onTap: onNew,
        ),
      ],
    );
  }
}

/// the list row's 52 pt, the whole row is the hit target
class _Row extends StatelessWidget {
  const _Row({
    required this.leading,
    required this.title,
    required this.onTap,
    this.count,
    this.ticked = false,
    this.onLongPress,
    super.key,
  });

  final Widget leading;

  /// already in the app's language
  final String title;
  final String? count;
  final bool ticked;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final count = this.count;
    return Semantics(
      button: true,
      selected: ticked,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: SizeManager.listRow.r),
          child: SymmetricPadding(
            horizontal: SpaceManager.s5,
            vertical: SpaceManager.s2,
            child: Row(
              children: [
                RSizedBox(
                  width: SizeManager.iconList,
                  child: Center(child: leading),
                ),
                const RSizedBox.horizontal(SpaceManager.listRowGap),
                Expanded(
                  child: RegularText(title, translate: false, fontSize: FontSizeManager.body),
                ),
                if (count != null) ...[
                  const RSizedBox.horizontal(SpaceManager.listRowGap),
                  RegularText(
                    count,
                    translate: false,
                    fontSize: FontSizeManager.secondary,
                    color: ThemeEnum.text3,
                  ),
                ],
                const RSizedBox.horizontal(SpaceManager.listRowGap),
                RSizedBox.square(
                  dimension: SizeManager.iconChevron,
                  child: ticked
                      ? BmIcon.ui(
                          BmUiIcon.check,
                          size: SizeManager.iconChevron.r,
                          color: context.getColor(ThemeEnum.primary),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// New category, or the same form filled in to rename, recolor or delete one
class _CategoryForm extends StatefulWidget {
  const _CategoryForm({required this.onSave, this.category, this.onDelete, super.key});

  final Category? category;
  final void Function(String name, CategoryColor color) onSave;

  /// null for a new one and for "Bookmarks", which is never deleted
  final VoidCallback? onDelete;

  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  late var _color = widget.category?.color ?? CategoryColor.primary;
  String? _name;

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final onDelete = widget.onDelete;
    final name = _name ??= category == null ? '' : categoryName(context, category);
    final isDefault = category?.id == AppDatabase.defaultCategory;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetTitle(category == null ? StringsManager.newCategory : StringsManager.editCategory),
        HorizontalPadding(
          padding: SpaceManager.s5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BmTextField(
                label: StringsManager.bookmarkName,
                hint: StringsManager.categoryHint,
                initial: name,
                autofocus: category == null,
                textInputAction: TextInputAction.done,
                onChanged: (name) => setState(() => _name = name),
              ),
              const RSizedBox.vertical(SpaceManager.s5),
              const RegularText(StringsManager.color, color: ThemeEnum.text2),
              const RSizedBox.vertical(SpaceManager.s3),
              Wrap(
                spacing: SpaceManager.shareSwatchGap.r,
                runSpacing: SpaceManager.s4.r,
                children: [
                  for (final color in CategoryColor.values)
                    Swatch(
                      label: color.label,
                      selected: color == _color,
                      onTap: () => setState(() => _color = color),
                      fill: ColoredBox(color: context.getColor(color.theme)),
                    ),
                ],
              ),
              const RSizedBox.vertical(SpaceManager.s6),

              /// only the default may be left empty, it then shows "Bookmarks"
              BmButton.primary(
                StringsManager.save,
                busy: !isDefault && name.trim().isEmpty,
                onPressed: () => widget.onSave(name, _color),
              ),
              if (onDelete != null) ...[
                const RSizedBox.vertical(SpaceManager.s2),
                BmButton.text(
                  StringsManager.deleteCategory,
                  color: ThemeEnum.error,
                  onPressed: onDelete,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
