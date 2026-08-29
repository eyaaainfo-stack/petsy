import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../widgets/back_button.dart';
import '../../../controllers/favorites_controller.dart';
import '../sitter/view_profile_sitter.dart';

// ============================================================================
// MyFavouritesScreen ("My Favourites") - owner
// ============================================================================
// 🔵 Wsulha mel sidebar (owner) - GET /api/users/favorites (data 7a9i9iya,
// mch mock). Dass 3al heart -> yna77i mel favoris (toggle, nafs API
// mte3 el card fel Home).
// ============================================================================
class MyFavouritesScreen extends StatefulWidget {
  const MyFavouritesScreen({super.key});

  @override
  State<MyFavouritesScreen> createState() => _MyFavouritesScreenState();
}

class _MyFavouritesScreenState extends State<MyFavouritesScreen> {
  final FavoritesController _controller = FavoritesController();
  List<FavoriteSitter> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final favorites = await _controller.fetchMyFavorites();
    if (!mounted) return;
    setState(() {
      _favorites = favorites;
      _isLoading = false;
    });
  }

  Future<void> _onUnfavoritePressed(FavoriteSitter sitter) async {
    // 🔵 optimistic: na77iha mel liste FI EL LAHDHA
    setState(() => _favorites.removeWhere((s) => s.id == sitter.id));

    final result = await _controller.toggleFavorite(sitter.id);
    if (!mounted) return;

    if (result != false) {
      // 🔴 el appel fechel (result null) WALA rajja3 "true" b'ghalta
      // (kan lezmou ykoun false, tна77يناها) - n3awdou njibou el liste
      // mel jdid bch el UI ye39ed sa7i7 100% (bدل ma nحاول n3awd
      // n7ottها manuellement).
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final Color mutedTextColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65) ?? Colors.grey;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _load,
              color: AppColors.pinkpetsy,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: EdgeInsets.symmetric(horizontal: sizes.favHorizontalPadding),
                      children: [
                        SizedBox(height: sizes.favTopGap),
                        Center(
                          child: Text('my_favourites_title'.tr(), style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.bold, fontSize: sizes.myProfileNameFontSize)),
                        ),
                        SizedBox(height: sizes.myProfileSectionGap),

                        if (_favorites.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.15),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.favorite_border, color: mutedTextColor.withOpacity(0.5), size: sizes.favEmptyStateIcon),
                                  SizedBox(height: sizes.screenHeight * 0.015),
                                  Text('no_favourites_yet_label'.tr(), style: TextStyle(color: mutedTextColor)),
                                ],
                              ),
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _favorites.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: sizes.favCardSpacing,
                              mainAxisSpacing: sizes.favCardSpacing,
                              childAspectRatio: 0.78,
                            ),
                            itemBuilder: (context, index) => _favoriteCard(sizes: sizes, sitter: _favorites[index], mutedTextColor: mutedTextColor),
                          ),

                        SizedBox(height: sizes.myProfileBottomGap),
                      ],
                    ),
            ),

            const CustomBackButton(),
          ],
        ),
      ),
    );
  }

  Widget _favoriteCard({required AppSizes sizes, required FavoriteSitter sitter, required Color mutedTextColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ViewProfileSitterScreen(sitterId: sitter.id, distanceKm: sitter.distanceKm)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.all(sizes.screenWidth * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔵 photo taakhod l'espace elli fadhel (Expanded), 9alb el
            // favoris tawa ma3moulch fou9ha - houwa jem el esm (taht).
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  color: AppColors.vertpetsy.withOpacity(0.18),
                  child: sitter.photoUrl != null
                      ? Image.network(sitter.photoUrl!, fit: BoxFit.cover)
                      : Icon(Icons.person, color: AppColors.vertpetsy, size: sizes.screenWidth * 0.12),
                ),
              ),
            ),
            SizedBox(height: sizes.screenWidth * 0.015),

            // 🔵 el esm 3al yesar w el 9alb (favoris) 3al yemin, fi nefs
            // el sef - kifma el card mte3 el sitters fel profile owner.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    sitter.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.screenWidth * 0.034),
                  ),
                ),
                GestureDetector(
                  onTap: () => _onUnfavoritePressed(sitter),
                  child: Icon(Icons.favorite, color: AppColors.pinkpetsy, size: sizes.screenWidth * 0.045),
                ),
              ],
            ),

            SizedBox(height: sizes.screenWidth * 0.005),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: mutedTextColor, size: sizes.screenWidth * 0.032),
                    SizedBox(width: sizes.screenWidth * 0.01),
                    Text(
                      sitter.distanceKm != null ? '${sitter.distanceKm}km' : '-',
                      style: TextStyle(fontSize: sizes.screenWidth * 0.028, color: mutedTextColor),
                    ),
                  ],
                ),
                Text(
                  sitter.startingPrice != null ? '${sitter.startingPrice!.toStringAsFixed(0)} DT' : '-',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.screenWidth * 0.032),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}