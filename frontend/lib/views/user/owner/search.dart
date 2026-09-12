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
import '../../../models/pet_summary.dart';
import '../../../repositories/pet_repository.dart';
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
  // 🔵 ZID (kifma tlab): "filtre disponible - nekhtar date/wa9t/pets" -
  // pets el owner, mjabdin lazy (ghir ki el user yeftah el sheet lel
  // premiere fois - bla ma na3mlou appel API ma3andouch lezmtou fel
  // écran search kollou).
  List<PetSummary> _ownerPets = [];
  bool _ownerPetsLoaded = false;
  bool _isLoadingOwnerPets = false;

  static const List<String> _residenceTypes = ['apartment', 'house', 'countryHouse'];
  static const Map<String, String> _residenceLabelKeys = {
    'apartment': 'sitter_residence_apartment',
    'house': 'sitter_residence_house',
    'countryHouse': 'sitter_residence_country_house',
  };
  // 🔵 ZID (feature "filtre categorie de pet")
  String _petCategoryLabel(String category) {
    switch (category) {
      case 'small_dog':
        return 'pet_category_small_dog_label'.tr();
      case 'guard_dog':
        return 'pet_category_guard_dog_label'.tr();
      case 'cat':
        return 'cat_label'.tr();
      default:
        return category;
    }
  }
  static const List<double> _distanceOptions = [5, 10, 20, 50];
  static const List<int> _memberSinceOptions = [3, 6, 12];
  // 🔴 FIX (kifma tlab: "les note mch deja dispo?") - filtre "Note"
  // 7a9i9i tawa (kan désactivé b'ghalta - el data el 7a9i9iya déjà
  // mawjouda mel backend, chraht fel userController.js/searchSitters).
  static const List<double> _ratingOptions = [4.5, 4.0, 3.5, 3.0];
  // 🔵 ZID (feature "filtres search: age/categorie/prestations")
  static const List<int> _ageOptions = [18, 25, 35, 45];
  static const List<int> _completedBookingsOptions = [1, 5, 10, 20];
  static const List<String> _petCategories = ['small_dog', 'guard_dog', 'cat'];

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
        // 🔴 FIX: kanet ma tab3athch "rating/reviewsCount" (w tawa
        // "age/completedBookingsCount") - fa kol tap 3al favori kan
        // ymassa7 hedhi el 9iem (yرجعو 0/null) mel UI (bla ma tban
        // el bug 7ata l'ay wa9t el data ma3adech tetجدد mel backend).
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
          isVerified: sitter.isVerified,
          rating: sitter.rating,
          reviewsCount: sitter.reviewsCount,
          age: sitter.age,
          completedBookingsCount: sitter.completedBookingsCount,
        );
      }
    });
    await _favoritesController.toggleFavorite(sitter.id);
  }

  // 🔵 ZID (kifma tlab): pets el owner (lel sheet "disponibilité") -
  // lazy, tetجab GHIR ken el user yeftah el sheet lel premiere marra.
  Future<void> _ensureOwnerPetsLoaded() async {
    if (_ownerPetsLoaded || _isLoadingOwnerPets) return;
    setState(() => _isLoadingOwnerPets = true);
    final pets = await PetRepository.fetchOwnerPets();
    if (!mounted) return;
    setState(() {
      _ownerPets = pets;
      _ownerPetsLoaded = true;
      _isLoadingOwnerPets = false;
    });
  }

  // --------------------------------------------------------------------
  // 🔴 FIX (kifma tlab: "les filtres lkol khallihomli fi boutons filtres
  // tht el recherche") - Date/Heure/Animaux tawa 3 BOUTONS mfar9in (nafs
  // sef el filtres el o5rin), mch chip WA7DA tefte7 sheet fiha el 3
  // hajet. Date w Heure: picker natif DIRECT (bla sheet, kifma "gender"/
  // "distance" ye3malou toggle direct). Animaux: sheet sghira (multi-
  // select bark, mafamech date/heure fiha). El "AND" (mch OR) baqi ye5dem
  // fel backend (searchSitters, filter.acceptedPetCategories = { $all:
  // [...] }) - houni ghir njam3ou el categories mel pets el mkhtarin.
  // --------------------------------------------------------------------
  Future<void> _pickAvailabilityDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _filters.availabilityDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    _updateFilters(_filters.copyWith(availabilityDate: picked));
  }

  Future<void> _pickAvailabilityTime() async {
    final initial = (_filters.availabilityHour != null && _filters.availabilityMinute != null)
        ? TimeOfDay(hour: _filters.availabilityHour!, minute: _filters.availabilityMinute!)
        : TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    _updateFilters(_filters.copyWith(availabilityHour: picked.hour, availabilityMinute: picked.minute));
  }

  Future<void> _showAvailabilityPetsSheet() async {
    await _ensureOwnerPetsLoaded();
    if (!mounted) return;
    final sizes = AppSizes.of(context);
    Set<String> tempPetIds = {..._filters.availabilityPetIds};

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            // 🔵 el categories el mfar9a mel pets el mkhtarin (bla doublons)
            // - houni ghir lel hint eli twarri lel user "AND" active wla la.
            final Set<String> selectedCategories = {
              for (final pet in _ownerPets)
                if (tempPetIds.contains(pet.id) && pet.category != null) pet.category!,
            };

            return DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.3,
              maxChildSize: 0.85,
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
                      Text('availability_pets_label'.tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize)),
                      SizedBox(height: sizes.screenHeight * 0.015),
                      if (_isLoadingOwnerPets)
                        const Center(child: CircularProgressIndicator())
                      else if (_ownerPets.isEmpty)
                        Text('availability_no_pets_hint'.tr(), style: TextStyle(color: Colors.grey.shade600, fontSize: sizes.myProfileBodyFontSize * 0.85))
                      else
                        Wrap(
                          spacing: sizes.screenWidth * 0.02,
                          runSpacing: sizes.screenHeight * 0.008,
                          children: [
                            for (final pet in _ownerPets)
                              if (pet.id != null)
                                InkWell(
                                  onTap: () => setSheetState(() {
                                    if (tempPetIds.contains(pet.id)) {
                                      tempPetIds.remove(pet.id);
                                    } else {
                                      tempPetIds.add(pet.id!);
                                    }
                                  }),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.032, vertical: sizes.screenHeight * 0.008),
                                    decoration: BoxDecoration(
                                      color: tempPetIds.contains(pet.id) ? AppColors.pinkpetsy : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: tempPetIds.contains(pet.id) ? AppColors.pinkpetsy : Colors.transparent),
                                    ),
                                    child: Text(
                                      pet.name,
                                      style: TextStyle(
                                        color: tempPetIds.contains(pet.id) ? Colors.white : null,
                                        fontWeight: tempPetIds.contains(pet.id) ? FontWeight.w700 : FontWeight.normal,
                                        fontSize: sizes.myProfileBodyFontSize * 0.85,
                                      ),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      // 🔵 ZID: n3allmou el user b'transparence "3lech
                      // el résultats na9sou" ki ye5tar pets mel 2
                      // categories differentes (AND, mch OR).
                      if (selectedCategories.length > 1) ...[
                        SizedBox(height: sizes.screenHeight * 0.012),
                        Text(
                          'availability_multi_category_hint'.tr(),
                          style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.75, color: AppColors.pinkpetsy, fontStyle: FontStyle.italic),
                        ),
                      ],

                      SizedBox(height: sizes.screenHeight * 0.03),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                _updateFilters(_filters.copyWith(availabilityPetIds: {}, availabilityPetCategories: []));
                              },
                              child: Text('availability_clear_button'.tr()),
                            ),
                          ),
                          SizedBox(width: sizes.screenWidth * 0.03),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.pinkpetsy),
                              onPressed: () {
                                final categories = <String>{
                                  for (final pet in _ownerPets)
                                    if (tempPetIds.contains(pet.id) && pet.category != null) pet.category!,
                                }.toList();
                                Navigator.of(sheetContext).pop();
                                _updateFilters(_filters.copyWith(availabilityPetIds: tempPetIds, availabilityPetCategories: categories));
                              },
                              child: Text('apply_button'.tr(), style: const TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
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
  // 🔴 FIX (kifma tlab: "les note mch deja dispo?") -
  // _showRatingNotAvailable etna77et - el filtre "Note" tawa 7a9i9i
  // (chouf _showAllFiltersSheet, yesta3mel _filterPillTile<double>
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
                // Filtres (kifma tlab: "les filtres hedhom lkol nhebhom
                // fi bouton bark kif nenzel alih w houa yethaalou") -
                // BOUTON WA7ED bark (mch 12 chips mfar9in) - cliqui 3lih
                // yeftah panel wa7ed fih el filtres el kol (accordion,
                // kol wa7ed yeftah/yeghlaq b'rou7ou, bla ma el panel
                // el kaملa teghleq).
                // ----------------------------------------------------
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: sizes.bookingHorizontalPadding),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _filterChip(
                      sizes: sizes,
                      label: _activeFiltersCount == 0 ? 'filters_label'.tr() : 'filters_count_label'.tr(namedArgs: {'count': '$_activeFiltersCount'}),
                      active: _activeFiltersCount > 0,
                      icon: Icons.tune,
                      onTap: _showAllFiltersSheet,
                    ),
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

  // 🔵 ZID: 3adad el filtres el active (bch el badge 3al bouton "Filtres"
  // ywarri 3adad, mathalan "Filtres (3)").
  int get _activeFiltersCount {
    int count = 0;
    if (_filters.gender != null) count++;
    if (_filters.city != null) count++;
    if (_filters.maxDistanceKm != null) count++;
    if (_filters.minRating != null) count++;
    if (_filters.residenceType != null) count++;
    if (_filters.minMemberMonths != null) count++;
    if (_filters.minAge != null) count++;
    if (_filters.availabilityDate != null) count++;
    if (_filters.availabilityHour != null) count++;
    if (_filters.availabilityPetIds.isNotEmpty) count++;
    if (_filters.acceptedPetCategory != null) count++;
    if (_filters.minCompletedBookings != null) count++;
    return count;
  }

  // 🔴 FIX (kifma tlab: "les filtres hedhom lkol nhebhom fi bouton bark
  // kif nenzel alih w houa yethaalou") - panel wa7ed (DraggableScroll
  // ableSheet, kifha kif el mockup: back arrow fou9, ba3dha kol filtre
  // f'satr b'rou7ou, cliqui 3lih yeftah accordion (ExpansionTile) fih
  // el options - el panel el kaملa TAB9A me7loula 7atta el user ye5tar
  // barcha filtres (mch tghaleq ba3d kol selection kifma kanet 9bal).
  Future<void> _showAllFiltersSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        // 🔵 ZID: declaré HOUNI (barra el StatefulBuilder.builder) bch
        // ma yet-reset-ch kol "setSheetState" (nafs pattern _showDurationPopup).
        final Set<String> expandedKeys = {};
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final sizes = AppSizes.of(context);
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.02, vertical: sizes.screenHeight * 0.008),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => Navigator.of(sheetContext).pop(),
                            ),
                            Text('filters_label'.tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: EdgeInsets.symmetric(horizontal: sizes.bookingHorizontalPadding),
                          children: [
                            _filterPillTile<String>(
                              sizes: sizes,
                              filterKey: 'gender',
                              title: 'gender_label'.tr(),
                              selected: _filters.gender,
                              options: [
                                _FilterOption(null, 'filter_any_label'.tr()),
                                _FilterOption('male', 'male_label'.tr()),
                                _FilterOption('female', 'female_label'.tr()),
                              ],
                              expandedKeys: expandedKeys,
                              setSheetState: setSheetState,
                              onSelected: (value) {
                                _updateFilters(_filters.copyWith(gender: value, clearGender: value == null));
                                setSheetState(() {});
                              },
                            ),
                            _filterPillTile<String>(
                              sizes: sizes,
                              filterKey: 'city',
                              title: 'city_filter_label'.tr(),
                              selected: _filters.city,
                              options: [
                                _FilterOption(null, 'filter_any_label'.tr()),
                                for (final gov in tunisiaGovernorates) _FilterOption(gov, gov),
                              ],
                              expandedKeys: expandedKeys,
                              setSheetState: setSheetState,
                              onSelected: (value) {
                                _updateFilters(_filters.copyWith(city: value, clearCity: value == null));
                                setSheetState(() {});
                              },
                            ),
                            _filterPillTile<double>(
                              sizes: sizes,
                              filterKey: 'distance',
                              title: 'distance_filter_label'.tr(),
                              selected: _filters.maxDistanceKm,
                              options: [
                                _FilterOption(null, 'filter_any_label'.tr()),
                                for (final km in _distanceOptions) _FilterOption(km, '≤ ${km.toStringAsFixed(0)} km'),
                              ],
                              expandedKeys: expandedKeys,
                              setSheetState: setSheetState,
                              onSelected: (value) {
                                _updateFilters(_filters.copyWith(maxDistanceKm: value, clearMaxDistanceKm: value == null));
                                setSheetState(() {});
                              },
                            ),
                            _filterPillTile<double>(
                              sizes: sizes,
                              filterKey: 'rating',
                              title: 'rating_filter_label'.tr(),
                              selected: _filters.minRating,
                              options: [
                                _FilterOption(null, 'filter_any_label'.tr()),
                                for (final r in _ratingOptions) _FilterOption(r, '≥ ${r.toStringAsFixed(1)} ★'),
                              ],
                              expandedKeys: expandedKeys,
                              setSheetState: setSheetState,
                              onSelected: (value) {
                                _updateFilters(_filters.copyWith(minRating: value, clearMinRating: value == null));
                                setSheetState(() {});
                              },
                            ),
                            _filterPillTile<String>(
                              sizes: sizes,
                              filterKey: 'residence',
                              title: 'residence_filter_label'.tr(),
                              selected: _filters.residenceType,
                              options: [
                                _FilterOption(null, 'filter_any_label'.tr()),
                                for (final type in _residenceTypes) _FilterOption(type, _residenceLabelKeys[type]!.tr()),
                              ],
                              expandedKeys: expandedKeys,
                              setSheetState: setSheetState,
                              onSelected: (value) {
                                _updateFilters(_filters.copyWith(residenceType: value, clearResidenceType: value == null));
                                setSheetState(() {});
                              },
                            ),
                            _filterPillTile<int>(
                              sizes: sizes,
                              filterKey: 'memberSince',
                              title: 'member_since_filter_label'.tr(),
                              selected: _filters.minMemberMonths,
                              options: [
                                _FilterOption(null, 'filter_any_label'.tr()),
                                for (final months in _memberSinceOptions) _FilterOption(months, 'member_since_months_value'.tr(namedArgs: {'months': months.toString()})),
                              ],
                              expandedKeys: expandedKeys,
                              setSheetState: setSheetState,
                              onSelected: (value) {
                                _updateFilters(_filters.copyWith(minMemberMonths: value, clearMinMemberMonths: value == null));
                                setSheetState(() {});
                              },
                            ),
                            _filterPillTile<int>(
                              sizes: sizes,
                              filterKey: 'age',
                              title: 'age_filter_label'.tr(),
                              selected: _filters.minAge,
                              options: [
                                _FilterOption(null, 'filter_any_label'.tr()),
                                for (final age in _ageOptions) _FilterOption(age, 'age_filter_value'.tr(namedArgs: {'age': age.toString()})),
                              ],
                              expandedKeys: expandedKeys,
                              setSheetState: setSheetState,
                              onSelected: (value) {
                                _updateFilters(_filters.copyWith(minAge: value, clearMinAge: value == null));
                                setSheetState(() {});
                              },
                            ),
                            // 🔵 Date/Heure/Animaux: nafs style "pill" ama
                            // bla accordion (tap direct yeftah native picker/
                            // sheet mnfassel, mch options inline).
                            _filterPillButton(
                              sizes: sizes,
                              title: _filters.availabilityDate == null ? 'availability_date_label'.tr() : '${_filters.availabilityDate!.day}/${_filters.availabilityDate!.month}',
                              active: _filters.availabilityDate != null,
                              onTap: () async {
                                await _pickAvailabilityDate();
                                setSheetState(() {});
                              },
                              onClear: () {
                                _updateFilters(_filters.copyWith(clearAvailabilityDate: true));
                                setSheetState(() {});
                              },
                            ),
                            _filterPillButton(
                              sizes: sizes,
                              title: (_filters.availabilityHour == null || _filters.availabilityMinute == null)
                                  ? 'availability_time_label'.tr()
                                  : TimeOfDay(hour: _filters.availabilityHour!, minute: _filters.availabilityMinute!).format(context),
                              active: _filters.availabilityHour != null,
                              onTap: () async {
                                await _pickAvailabilityTime();
                                setSheetState(() {});
                              },
                              onClear: () {
                                _updateFilters(_filters.copyWith(clearAvailabilityTime: true));
                                setSheetState(() {});
                              },
                            ),
                            _filterPillButton(
                              sizes: sizes,
                              title: _filters.availabilityPetIds.isEmpty ? 'availability_pets_label'.tr() : 'availability_pets_count_label'.tr(namedArgs: {'count': _filters.availabilityPetIds.length.toString()}),
                              active: _filters.availabilityPetIds.isNotEmpty,
                              onTap: () async {
                                await _showAvailabilityPetsSheet();
                                setSheetState(() {});
                              },
                              onClear: () {
                                _updateFilters(_filters.copyWith(availabilityPetIds: {}));
                                setSheetState(() {});
                              },
                            ),
                            _filterPillTile<String>(
                              sizes: sizes,
                              filterKey: 'petCategory',
                              title: 'pet_category_filter_label'.tr(),
                              selected: _filters.acceptedPetCategory,
                              options: [
                                _FilterOption(null, 'filter_any_label'.tr()),
                                for (final cat in _petCategories) _FilterOption(cat, _petCategoryLabel(cat)),
                              ],
                              expandedKeys: expandedKeys,
                              setSheetState: setSheetState,
                              onSelected: (value) {
                                _updateFilters(_filters.copyWith(acceptedPetCategory: value, clearAcceptedPetCategory: value == null));
                                setSheetState(() {});
                              },
                            ),
                            _filterPillTile<int>(
                              sizes: sizes,
                              filterKey: 'completedBookings',
                              title: 'completed_bookings_filter_label'.tr(),
                              selected: _filters.minCompletedBookings,
                              options: [
                                _FilterOption(null, 'filter_any_label'.tr()),
                                for (final count in _completedBookingsOptions)
                                  _FilterOption(count, 'completed_bookings_filter_value'.tr(namedArgs: {'count': count.toString()})),
                              ],
                              expandedKeys: expandedKeys,
                              setSheetState: setSheetState,
                              onSelected: (value) {
                                _updateFilters(_filters.copyWith(minCompletedBookings: value, clearMinCompletedBookings: value == null));
                                setSheetState(() {});
                              },
                            ),
                            SizedBox(height: sizes.screenHeight * 0.02),
                          ],
                        ),
                      ),
                      // 🔵 ZID (kifma tlab: "zidni bouton ala el filtre
                      // lkol - nefsakh el filtre eli khtrthom wla
                      // appliquer") - footer fixe (barra el scroll):
                      // "Effacer tout" (reset kol el filtres l'"Any")
                      // + "Appliquer" (yeghleq el panel - el résultats
                      // deja mta7dthin live, kol selection ta3mel
                      // _runSearch() automatique).
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: sizes.bookingHorizontalPadding, vertical: sizes.screenHeight * 0.012),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _activeFiltersCount == 0
                                    ? null
                                    : () {
                                        _updateFilters(const SitterSearchFilters());
                                        setSheetState(() {});
                                      },
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.016),
                                  side: BorderSide(color: AppColors.pinkpetsy.withOpacity(0.5)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                child: Text('clear_all_filters_button'.tr(), style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            SizedBox(width: sizes.screenWidth * 0.03),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.of(sheetContext).pop(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.pinkpetsy,
                                  padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.016),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                child: Text('apply_filters_button'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // 🔴 FIX (kifma tlab: "ma nhbhomch ashem, kol nhbhom b nfs el design
  // el kdim les boutons") - "pill" (rounded, border rose, chevron) nafs
  // style _filterChip el 9dim, ama FULL WIDTH (satr b'rou7ou, mch chip
  // s8ir) - tap yeftah/yeghleq el options ta7tou (accordion, ama bel
  // style "boutons" mch el default Material ExpansionTile).
  Widget _filterPillTile<T>({
    required AppSizes sizes,
    required String filterKey,
    required String title,
    required T? selected,
    required List<_FilterOption<T>> options,
    required Set<String> expandedKeys,
    required void Function(void Function()) setSheetState,
    required ValueChanged<T?> onSelected,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color inactiveTextColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    final bool active = selected != null;
    final bool isExpanded = expandedKeys.contains(filterKey);
    String? selectedLabel;
    for (final option in options) {
      if (option.value == selected && selected != null) {
        selectedLabel = option.label;
        break;
      }
    }

    return Padding(
      padding: EdgeInsets.only(bottom: sizes.screenHeight * 0.012),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setSheetState(() {
              if (isExpanded) {
                expandedKeys.remove(filterKey);
              } else {
                expandedKeys.add(filterKey);
              }
            }),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.045, vertical: sizes.screenHeight * 0.015),
              decoration: BoxDecoration(
                color: active ? AppColors.pinkpetsy : (isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(24),
                border: active ? null : Border.all(color: AppColors.pinkpetsy.withOpacity(0.5), width: 1.2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedLabel ?? title,
                      style: TextStyle(color: active ? Colors.white : inactiveTextColor, fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 0.9),
                    ),
                  ),
                  // 🔵 ZID (kifma tlab: "zidni bouton nefsakh el filtre")
                  // - "X" yban GHIR ki el filtre active (selected !=
                  // null) - tap yfassakh el filtre (mba3thou l'"Any")
                  // bla ma ye7taj ye7ell el options w ye5tar "Peu importe".
                  if (active) ...[
                    InkWell(
                      onTap: () {
                        onSelected(null);
                        setSheetState(() {});
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: EdgeInsets.all(sizes.screenWidth * 0.008),
                        child: Icon(Icons.close, color: Colors.white, size: sizes.myProfileBodyFontSize),
                      ),
                    ),
                    SizedBox(width: sizes.screenWidth * 0.01),
                  ],
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: active ? Colors.white : AppColors.pinkpetsy,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: EdgeInsets.only(top: sizes.screenHeight * 0.008, left: sizes.screenWidth * 0.02),
              child: Column(
                children: [
                  for (final option in options)
                    RadioListTile<T?>(
                      value: option.value,
                      groupValue: selected,
                      activeColor: AppColors.pinkpetsy,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(option.label, style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.85)),
                      onChanged: onSelected,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 🔵 ZID: "pill" bla accordion (l'Date/Heure/Animaux - tap yeftah
  // native picker/sheet mnfassel direct, mch options inline) - nafs
  // style el pill el fou9 bالضبط (bch el design ykoun consistent).
  Widget _filterPillButton({
    required AppSizes sizes,
    required String title,
    required bool active,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color inactiveTextColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    return Padding(
      padding: EdgeInsets.only(bottom: sizes.screenHeight * 0.012),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.045, vertical: sizes.screenHeight * 0.015),
          decoration: BoxDecoration(
            color: active ? AppColors.pinkpetsy : (isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(24),
            border: active ? null : Border.all(color: AppColors.pinkpetsy.withOpacity(0.5), width: 1.2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(title, style: TextStyle(color: active ? Colors.white : inactiveTextColor, fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 0.9)),
              ),
              // 🔵 ZID (kifma tlab: "fel date wel heure ken nhb nefsakhhom
              // zidni bouton nefsakh el filtre") - Date/Heure ma3andhomch
              // option "Any" fel picker natif (bla ha, el "X" el 7al el
              // wa7id bech el user yfassa5 el valeur mel jdid).
              if (active && onClear != null) ...[
                InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: EdgeInsets.all(sizes.screenWidth * 0.008),
                    child: Icon(Icons.close, color: Colors.white, size: sizes.myProfileBodyFontSize),
                  ),
                ),
                SizedBox(width: sizes.screenWidth * 0.01),
              ],
              Icon(Icons.chevron_right, color: active ? Colors.white : AppColors.pinkpetsy),
            ],
          ),
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
  Widget _filterChip({required AppSizes sizes, required String label, required bool active, required VoidCallback onTap, IconData? icon}) {
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
            if (icon != null) ...[
              Icon(icon, color: active ? Colors.white : AppColors.pinkpetsy, size: sizes.bookingPillFont * 1.2),
              SizedBox(width: sizes.screenWidth * 0.014),
            ],
            Text(label, style: TextStyle(color: active ? Colors.white : inactiveTextColor, fontSize: sizes.bookingPillFont, fontWeight: FontWeight.w600)),
            if (icon == null) ...[
              SizedBox(width: sizes.screenWidth * 0.01),
              Icon(Icons.keyboard_arrow_down, color: active ? Colors.white : AppColors.pinkpetsy, size: sizes.bookingPillFont * 1.3),
            ],
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