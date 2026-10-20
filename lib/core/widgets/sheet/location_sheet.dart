import 'package:better_muslim/core/location/location_controller.dart';
import 'package:better_muslim/core/location/place.dart';
import 'package:better_muslim/core/location/place_list.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_tokens.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/search_field.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the pill and the no-location card both open it, "use my location" can start right away.
/// failed = location was just refused, the sheet opens saying so (milestone 10 FR-020). true when
/// a place was saved, so 4.11 goes on only then
Future<bool> showLocationSheet(
  BuildContext context, {
  bool useMyLocation = false,
  bool failed = false,
}) async =>
    await showBmSheet<bool>(
      context,
      builder: (_) => LocationSheet(useMyLocation: useMyLocation, failed: failed),
    ) ??
    false;

/// use my location, or the offline city search over the GeoNames list (R12)
class LocationSheet extends ConsumerStatefulWidget {
  const LocationSheet({this.useMyLocation = false, this.failed = false, super.key});
  final bool useMyLocation;
  final bool failed;

  @override
  ConsumerState<LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends ConsumerState<LocationSheet> {
  var _query = '';
  var _busy = false;
  late var _failed = widget.failed;

  @override
  void initState() {
    super.initState();
    if (widget.useMyLocation) _useMyLocation();
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    final done = await ref.read(locationControllerProvider).useAuto();
    if (!mounted) return;
    if (done) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _failed = true;
      });
    }
  }

  Future<void> _choose(Place place) async {
    await ref.read(locationControllerProvider).choose(place);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SymmetricPadding(
            horizontal: SpaceManager.screen,
            child: SemiBoldText(StringsManager.location),
          ),
          const RSizedBox.vertical(SpaceManager.s2),
          _UseMyLocationRow(busy: _busy, onTap: _useMyLocation),
          if (_failed)
            const SymmetricPadding(
              horizontal: SpaceManager.screen,
              child: RegularText(StringsManager.locationFailed, color: ThemeEnum.error),
            ),
          const RSizedBox.vertical(SpaceManager.s3),
          HorizontalPadding(
            padding: SpaceManager.screen,
            child: SearchField(
              hint: StringsManager.searchCity,
              onChanged: (query) => setState(() => _query = query),
            ),
          ),
          const RSizedBox.vertical(SpaceManager.s2),
          Flexible(
            child: _Results(query: _query, onChoose: _choose),
          ),
        ],
      ),
    );
  }
}

class _UseMyLocationRow extends StatelessWidget {
  const _UseMyLocationRow({required this.busy, required this.onTap});
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !busy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: busy ? null : onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: SizeManager.listRow.r),
          child: SymmetricPadding(
            horizontal: SpaceManager.screen,
            child: Row(
              children: [
                AnimatedOpacity(
                  opacity: busy ? BmOpacity.disabled : 1,
                  duration: const Duration(microseconds: 300),
                  child: BmIcon(
                    BmIconName.location,
                    size: SizeManager.iconList.r,
                    color: context.getColor(ThemeEnum.primary),
                  ),
                ),
                const RSizedBox.horizontal(SpaceManager.s3),
                Expanded(
                  child: AnimatedOpacity(
                    opacity: busy ? BmOpacity.disabled : 1,
                    duration: const Duration(microseconds: 300),
                    child: const MediumText(StringsManager.useMyLocation),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.query, required this.onChoose});
  final String query;
  final ValueChanged<Place> onChoose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref.watch(placeListProvider).value;
    if (places == null || query.trim().isEmpty) return const SizedBox.shrink();
    final results = places.search(query);
    if (results.isEmpty) {
      return const SymmetricPadding(
        horizontal: SpaceManager.screen,
        vertical: SpaceManager.s4,
        child: RegularText(StringsManager.noPlacesFound, color: ThemeEnum.text2),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: results.length,
      itemBuilder: (context, index) =>
          _PlaceRow(place: results[index], onTap: () => onChoose(results[index])),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({required this.place, required this.onTap});
  final Place place;
  final VoidCallback onTap;

  static const _separator = ' · ';

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    /// the latin name when the list has no arabic one (milestone 2 FR-003)
    final name = (isArabic ? place.nameAr : null) ?? place.name;
    final region = (isArabic ? place.regionAr : null) ?? place.region;
    final country = (isArabic ? place.countryAr : null) ?? place.country;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: SizeManager.listRow.r),
          child: SymmetricPadding(
            horizontal: SpaceManager.screen,
            vertical: SpaceManager.s2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MediumText(name, translate: false),
                RegularText(
                  [?region, country].join(_separator),
                  translate: false,
                  color: ThemeEnum.text2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
