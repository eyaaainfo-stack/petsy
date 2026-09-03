import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../widgets/back_button.dart';
import '../../../widgets/verified_badge.dart';
import '../../../controllers/sitter_search_controller.dart';
import '../../../controllers/favorites_controller.dart';
import '../../../controllers/user_create_profile_controller.dart' show tunisiaGovernorates;
import '../sitter/view_profile_sitter.dart';

// ============================================================================
// SearchScreen ("search.dart") - owner
// ============================================================================
// 🔵 Wsulha mel barre "search" (profile_owner.dart, kanet UI bark bla
// mant9) - GET /api/users/sitters/search: autocomplete LIVE (esm, kifma
// el insta/fb) + filtres (gender/city/distance/win yoskon/kadeh 3ndou
// fel app).
//
// 🔴 "les etoiles" (rating): mafamech système reviews 7a9i9i mrakez
// fel backend l'hin (chrahtha view_profile_sitter.dart, "Reviews (0)"
// dima) - el filtre houni mawjoud fel UI (kifma tlab) lakin ma
// yfiltriwch 7a9i9atan, ghir n3allmou el user "mazel ma tsawwabch".
// ============================================================================
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _queryFocusNode = FocusNode();
  final SitterSearchController _searchController = SitterSearchController();
  final FavoritesController _favoritesController = FavoritesController();

  Timer? _debounce;
  List<SitterSearchResult> _results = [];
  bool _isLoading = false;
  bool _hasSearchedOnce = false;
  SitterSearchFilters _filters = const SitterSearchFilters();

  static const List<String> _residenceTypes = ['apartment', 'house', 'countryHouse'];
  static const Map<String, String> _residenceLabelKeys = {
    'apartment': 'sitter_residence_apartment',
    'house': 'sitter_residence_house',
    'countryHouse': 'sitter_residence_country_house',
  };
  static const List<double> _distanceOptions = [5, 10, 20, 50];
  static const List<int> _memberSinceOptions = [3, 6, 12];
  // 🔴 FIX (kifma tlab: "les note mch deja dispo?") - filtre "Note"
  // 7a9i9i tawa (kan désactivé b'ghalta - el data el 7a9i9iya déjà
  // mawjouda mel backend, chraht fel userController.js/searchSitters).
  static const List<double> _ratingOptions = [4.5, 4.0, 3.5, 3.0];

  @override
  void initState() {
    super.initState();
    _queryController.addListener(_onQueryChanged);
    // 🔵 el user ejja mel bouton "search" - autofocus direct (bch
    // el keyboard yeftah automatique, kifma el insta).
    WidgetsBinding.instance.addPostFrameCallback((_) => _queryFocusNode.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.removeListener(_onQueryChanged);
    _queryController.dispose();
    _queryFocusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _runSearch);
  }

  Future<void> _runSearch() async {
    // 🔵 lowkan bla query W bla filtres - ma na3mlouch appel (résultat
    // fadhi, écran "vide" - kifma el insta 9bal ma tekteb 7atta 7arf).
    if (_queryController.text.trim().isEmpty && _filters.isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
        _hasSearchedOnce = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    final results = await _searchController.search(query: _queryController.text, filters: _filters);
    if (!mounted) return;
    setState(() {
      _results = results;
      _isLoading = false;
      _hasSearchedOnce = true;
    });
  }

  void _updateFilters(SitterSearchFilters newFilters) {
    setState(() => _filters = newFilters);
    _runSearch();
  }

  Future<void> _toggleFavorite(SitterSearchResult sitter) async {
    setState(() {
      final index = _results.indexWhere((s) => s.id == sitter.id);
      if (index != -1) {
        _results[index] = SitterSearchResult(
          id: sitter.id,
          fullName: sitter.fullName,
          city: sitter.city,
          photoUrl: sitter.photoUrl,
          gender: sitter.gender,
          residenceType: sitter.residenceType,
          memberSince: sitter.memberSince,
          distanceKm: sitter.distanceKm,
          isFavorite: !sitter.isFavorite,
        );
      }
    });
    await _favoritesController.toggleFavorite(sitter.id);
  }

  // --------------------------------------------------------------------
  // Bottom sheet générique: liste d'options b single-select (radio-style),
  // terja3 el option el mkhtara (wela null lowkan el user 3andel "Any").
  // --------------------------------------------------------------------
  // 🔴 FIX (kifma tlab: "Mazelet el ville tjini fiha barre" - el bande
  // jaune/noire "BOTTOM OVERFLOWED") - el Column kanet bla ay scroll
  // (mafamech ListView/ScrollView) - m3a liste twila (24 gouvernorat
  // lel "Ville") el Column te7ذef 3ala l'espace disponible fel bottom
  // sheet w overflow. Tawa: DraggableScrollableSheet (nafs pattern
  // el CIN popup/détail avis - déjà mjarreb, mch overflow ay wa9t,
  // el user ynajjam ye5tar el liste tkabber wla y-scroll fiha).
  Future<void> _showFilterSheet<T>({
    required String title,
    required List<_FilterOption<T>> options,
    required T? selected,
    required ValueChanged<T?> onSelected,
  }) async {
    final sizes = AppSizes.of(context);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.02, horizontal: sizes.bookingHorizontalPadding),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(bottom: sizes.screenHeight * 0.015),
                      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize)),
                  SizedBox(height: sizes.screenHeight * 0.012),
                  for (final option in options)
                    InkWell(
                      onTap: () {
                        onSelected(option.value);
                        Navigator.of(sheetContext).pop();
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.012),
                        child: Row(
                          children: [
                            Icon(
                              option.value == selected ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: option.value == selected ? AppColors.pinkpetsy : Colors.grey,
                              size: sizes.myProfileBodyFontSize,
                            ),
                            SizedBox(width: sizes.screenWidth * 0.03),
                            Expanded(child: Text(option.label, style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.9))),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 🔴 FIX (kifma tlab: "les note mch deja dispo?") -
  // _showRatingNotAvailable etna77et - el filtre "Note" tawa 7a9i9i
  // (chouf el chip fel build(), yesta3mel _showFilterSheet<double>
  // nafs mant9 el filtres l'okhrin el kol).

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final Color mutedTextColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65) ?? Colors.grey;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: sizes.bookingTopGap + sizes.screenHeight * 0.045),

                // ----------------------------------------------------
                // Search bar (nafs style tel profile_owner.dart)
                // ----------------------------------------------------
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: sizes.bookingHorizontalPadding),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.vertpetsy.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _queryController,
                      focusNode: _queryFocusNode,
                      decoration: InputDecoration(
                        hintText: 'search_hint'.tr(),
                        hintStyle: TextStyle(color: mutedTextColor, fontSize: sizes.screenWidth * 0.035),
                        prefixIcon: Icon(Icons.search, color: AppColors.vertpetsy),
                        suffixIcon: _queryController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close, color: mutedTextColor),
                                onPressed: () => _queryController.clear(),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.018),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: sizes.screenHeight * 0.014),

                // ----------------------------------------------------
                // Filtres (chips - kol wa7ed yeftah bottom sheet)
                // ----------------------------------------------------
                // 🔴 FIX (kifma tlab: "ma hbhomch hakk bel ordh... nhbhom
                // fi blasa okhra bhya w en meme temps ypdhhrou lkol") -
                // kanet ListView horizontal (scroll, fadhel wa7ed
                // ma7chouch/ma yban ghir b'scroll) - tawa Wrap: kol
                // el filtres el 6 ybanou fi nefs el wa9t, ydourou
                // 3ala satrin (wrap) ken el 3ard ma yosa3homch f'satr
                // wa7ed - mafamech scroll, mafamech 7aja tetfa9ad.
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: sizes.bookingHorizontalPadding),
                  child: Wrap(
                    spacing: sizes.screenWidth * 0.02,
                    runSpacing: sizes.screenHeight * 0.01,
                    children: [
                      _filterChip(
                        sizes: sizes,
                        label: _filters.gender == null ? 'gender_label'.tr() : (_filters.gender == 'male' ? 'male_label'.tr() : 'female_label'.tr()),
                        active: _filters.gender != null,
                        onTap: () => _showFilterSheet<String>(
                          title: 'gender_label'.tr(),
                          selected: _filters.gender,
                          options: [
                            _FilterOption(null, 'filter_any_label'.tr()),
                            _FilterOption('male', 'male_label'.tr()),
                            _FilterOption('female', 'female_label'.tr()),
                          ],
                          onSelected: (value) => _updateFilters(_filters.copyWith(gender: value, clearGender: value == null)),
                        ),
                      ),
                      _filterChip(
                        sizes: sizes,
                        label: _filters.city ?? 'city_filter_label'.tr(),
                        active: _filters.city != null,
                        onTap: () => _showFilterSheet<String>(
                          title: 'city_filter_label'.tr(),
                          selected: _filters.city,
                          options: [
                            _FilterOption(null, 'filter_any_label'.tr()),
                            for (final gov in tunisiaGovernorates) _FilterOption(gov, gov),
                          ],
                          onSelected: (value) => _updateFilters(_filters.copyWith(city: value, clearCity: value == null)),
                        ),
                      ),
                      _filterChip(
                        sizes: sizes,
                        label: _filters.maxDistanceKm == null ? 'distance_filter_label'.tr() : '≤ ${_filters.maxDistanceKm!.toStringAsFixed(0)} km',
                        active: _filters.maxDistanceKm != null,
                        onTap: () => _showFilterSheet<double>(
                          title: 'distance_filter_label'.tr(),
                          selected: _filters.maxDistanceKm,
                          options: [
                            _FilterOption(null, 'filter_any_label'.tr()),
                            for (final km in _distanceOptions) _FilterOption(km, '≤ ${km.toStringAsFixed(0)} km'),
                          ],
                          onSelected: (value) => _updateFilters(_filters.copyWith(maxDistanceKm: value, clearMaxDistanceKm: value == null)),
                        ),
                      ),
                      _filterChip(
                        sizes: sizes,
                        label: _filters.minRating == null ? 'rating_filter_label'.tr() : '≥ ${_filters.minRating!.toStringAsFixed(1)} ★',
                        active: _filters.minRating != null,
                        onTap: () => _showFilterSheet<double>(
                          title: 'rating_filter_label'.tr(),
                          selected: _filters.minRating,
                          options: [
                            _FilterOption(null, 'filter_any_label'.tr()),
                            for (final r in _ratingOptions) _FilterOption(r, '≥ ${r.toStringAsFixed(1)} ★'),
                          ],
                          onSelected: (value) => _updateFilters(_filters.copyWith(minRating: value, clearMinRating: value == null)),
                        ),
                      ),
                      _filterChip(
                        sizes: sizes,
                        label: _filters.residenceType == null ? 'residence_filter_label'.tr() : _residenceLabelKeys[_filters.residenceType]!.tr(),
                        active: _filters.residenceType != null,
                        onTap: () => _showFilterSheet<String>(
                          title: 'residence_filter_label'.tr(),
                          selected: _filters.residenceType,
                          options: [
                            _FilterOption(null, 'filter_any_label'.tr()),
                            for (final type in _residenceTypes) _FilterOption(type, _residenceLabelKeys[type]!.tr()),
                          ],
                          onSelected: (value) => _updateFilters(_filters.copyWith(residenceType: value, clearResidenceType: value == null)),
                        ),
                      ),
                      _filterChip(
                        sizes: sizes,
                        label: _filters.minMemberMonths == null ? 'member_since_filter_label'.tr() : 'member_since_months_value'.tr(namedArgs: {'months': _filters.minMemberMonths.toString()}),
                        active: _filters.minMemberMonths != null,
                        onTap: () => _showFilterSheet<int>(
                          title: 'member_since_filter_label'.tr(),
                          selected: _filters.minMemberMonths,
                          options: [
                            _FilterOption(null, 'filter_any_label'.tr()),
                            for (final months in _memberSinceOptions) _FilterOption(months, 'member_since_months_value'.tr(namedArgs: {'months': months.toString()})),
                          ],
                          onSelected: (value) => _updateFilters(_filters.copyWith(minMemberMonths: value, clearMinMemberMonths: value == null)),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: sizes.screenHeight * 0.014),

                // ----------------------------------------------------
                // Résultats
                // ----------------------------------------------------
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : !_hasSearchedOnce
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: sizes.bookingHorizontalPadding),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.search, color: mutedTextColor.withOpacity(0.4), size: sizes.bookingEmptyStateIcon),
                                    SizedBox(height: sizes.screenHeight * 0.015),
                                    Text('search_start_typing_label'.tr(), style: TextStyle(color: mutedTextColor), textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            )
                          : _results.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: sizes.bookingHorizontalPadding),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.search_off, color: mutedTextColor.withOpacity(0.4), size: sizes.bookingEmptyStateIcon),
                                        SizedBox(height: sizes.screenHeight * 0.015),
                                        Text('search_no_results_label'.tr(), style: TextStyle(color: mutedTextColor), textAlign: TextAlign.center),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: EdgeInsets.symmetric(horizontal: sizes.bookingHorizontalPadding, vertical: sizes.screenHeight * 0.01),
                                  itemCount: _results.length,
                                  separatorBuilder: (_, __) => SizedBox(height: sizes.screenHeight * 0.012),
                                  itemBuilder: (context, index) => _sitterRow(sizes: sizes, sitter: _results[index], mutedTextColor: mutedTextColor),
                                ),
                ),
              ],
            ),

            const CustomBackButton(),
          ],
        ),
      ),
    );
  }

  // 🔴 FIX (kifma tlab: "el filtre mahomch lisible lkoll") - kanet text
  // rose 3ala background rose b'opacity 0.10 (contraste WCAG ~2.9:1,
  // ta7t el 4.5:1 el minimum) - tawa: fond theme-aware (gris/blanc
  // transparent, mch rose fadhi) + bordure rose ahfef (accent bark) +
  // text b'loun el thème (dark/light) - contraste behi fi mode sombre
  // W light el 2.
  //
  // 🔴 FIX (kifma tlab: "ma hbhomch hakk bel ordh... nhbhom yban lkol
  // fi nefs el wa9t") - el liste kanet ListView horizontal (scroll) -
  // tawa Wrap (chouf fou9, fel build()) - el filtres el kol ybanou
  // direct, mafamech scroll wla 7aja tetfa9ad.
  Widget _filterChip({required AppSizes sizes, required String label, required bool active, required VoidCallback onTap}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color inactiveTextColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.032, vertical: sizes.screenHeight * 0.008),
        decoration: BoxDecoration(
          color: active ? AppColors.pinkpetsy : (isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(20),
          border: active ? null : Border.all(color: AppColors.pinkpetsy.withOpacity(0.35), width: 1.2),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: active ? Colors.white : inactiveTextColor, fontSize: sizes.bookingPillFont, fontWeight: FontWeight.w600)),
            SizedBox(width: sizes.screenWidth * 0.01),
            Icon(Icons.keyboard_arrow_down, color: active ? Colors.white : AppColors.pinkpetsy, size: sizes.bookingPillFont * 1.3),
          ],
        ),
      ),
    );
  }

  Widget _sitterRow({required AppSizes sizes, required SitterSearchResult sitter, required Color mutedTextColor}) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ViewProfileSitterScreen(sitterId: sitter.id, distanceKm: sitter.distanceKm)),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.008),
        child: Row(
          children: [
            // 🔵 ZID (kifma tlab: "el tick bhdha pdp hta el users
            // lokhrin yrawha") - Stack barra el ClipRRect bch el badge
            // ma yet9assch (clipBehavior: none).
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(sizes.bookingAvatarSize * 1.1 / 2),
                  child: Container(
                    width: sizes.bookingAvatarSize * 1.1,
                    height: sizes.bookingAvatarSize * 1.1,
                    color: AppColors.vertpetsy.withOpacity(0.18),
                    child: sitter.photoUrl != null
                        ? Image.network(sitter.photoUrl!, fit: BoxFit.cover)
                        : Icon(Icons.person, color: AppColors.vertpetsy, size: sizes.bookingAvatarSize * 0.6),
                  ),
                ),
                if (sitter.isVerified)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: VerifiedBadge(size: sizes.bookingAvatarSize * 0.3),
                  ),
              ],
            ),
            SizedBox(width: sizes.screenWidth * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sitter.fullName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 0.9)),
                  SizedBox(height: sizes.screenHeight * 0.002),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: sizes.myProfileBodyFontSize * 0.65, color: mutedTextColor),
                      SizedBox(width: sizes.screenWidth * 0.008),
                      Text(
                        sitter.distanceKm != null ? '${sitter.city} · ${sitter.distanceKm}km' : sitter.city,
                        style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.75, color: mutedTextColor),
                      ),
                      // 🔴 FIX (kifma tlab: "les note mch deja dispo?") -
                      // note twarri houni (ken 3andou avis 3ala l'a9al
                      // wa7ed - reviewsCount > 0) - bch el filtre "Note"
                      // ykoun mfahhem 3al résultats.
                      if (sitter.reviewsCount > 0) ...[
                        SizedBox(width: sizes.screenWidth * 0.02),
                        Icon(Icons.star_rounded, size: sizes.myProfileBodyFontSize * 0.75, color: Colors.amber),
                        SizedBox(width: sizes.screenWidth * 0.004),
                        Text(
                          sitter.rating.toStringAsFixed(1),
                          style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.75, color: mutedTextColor, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _toggleFavorite(sitter),
              child: Icon(
                sitter.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: AppColors.pinkpetsy,
                size: sizes.myProfileBodyFontSize * 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterOption<T> {
  final T? value;
  final String label;
  const _FilterOption(this.value, this.label);
}