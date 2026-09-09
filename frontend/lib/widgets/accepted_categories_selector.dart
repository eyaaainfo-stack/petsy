import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

// ============================================================================
// AcceptedCategoriesSelector (feature "compatibilite entre animaux")
// ============================================================================
// 🔵 ZID: el sitter ye5tar GHIR el categories (small_dog/guard_dog/cat)
// elli ye9bel ye5dem m3ahom - checkbox bark, BLA prix houni (el prix
// ye7taj l'kol SERVICE mnfassel - chraht fel ServiceCategorySelector,
// widgets/service_category_selector.dart). Nafs API publique
// (validate()/getPayload()/markTriedSubmit()) tel ServiceCategorySelector
// - bch el parent screen ynajjam yesta3milha b'NAFS el pattern.
//
// 🔵 ZID: "onChanged" - ki el selection tetbeddel (checkbox), el parent
// screen ye7taj ye3raf FORAN (mch ghir 3end el submit) bch yeb3ath el
// categories el jdad l'ServiceCategorySelector (elli yban BA3DHA fel
// écran, w ye7taj ye3raf categories chnowa bch ywarri prix l'kol wa7da).
//
// 🔵 ZID (kifma tlab): had el selector yban 9BAL "Services Offered"
// fel écran - el sitter ye5tar category 9bal ma ye5tar services.
// ============================================================================
class AcceptedCategoriesSelector extends StatefulWidget {
  // 🔵 ZID: bch update_profile_sitter.dart ynajjam ym3ammar el widget
  // mel data el 7aliya.
  final List<String> initialCategories;
  final ValueChanged<Set<String>>? onChanged;

  const AcceptedCategoriesSelector({super.key, this.initialCategories = const [], this.onChanged});

  @override
  State<AcceptedCategoriesSelector> createState() => AcceptedCategoriesSelectorState();
}

class AcceptedCategoriesSelectorState extends State<AcceptedCategoriesSelector> {
  static const List<String> _categories = ['small_dog', 'guard_dog', 'cat'];

  final Set<String> _selected = {};
  bool triedSubmit = false;

  @override
  void initState() {
    super.initState();
    for (final category in widget.initialCategories) {
      if (_categories.contains(category)) _selected.add(category);
    }
  }

  void markTriedSubmit() => setState(() => triedSubmit = true);

  // 🔵 terja3 el error key (mch traduite) - null lowkan kol chay behi.
  String? validate() {
    if (_selected.isEmpty) return 'sitter_accepted_categories_required_error';
    return null;
  }

  List<String> getPayload() => _selected.toList();

  String _labelKey(String category) {
    switch (category) {
      case 'small_dog':
        return 'pet_category_small_dog_label';
      case 'guard_dog':
        return 'pet_category_guard_dog_label';
      case 'cat':
        return 'cat_label';
      default:
        return category;
    }
  }

  Widget _categoryRow(String category, AppSizes sizes) {
    final bool isSelected = _selected.contains(category);
    return Padding(
      padding: EdgeInsets.only(bottom: sizes.screenHeight * 0.012),
      child: InkWell(
        onTap: () => setState(() {
          if (!_selected.remove(category)) _selected.add(category);
          widget.onChanged?.call(_selected);
        }),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: sizes.screenWidth * 0.05,
              height: sizes.screenWidth * 0.05,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.vertpetsy, width: 1.6),
                color: isSelected ? AppColors.vertpetsy : Colors.transparent,
              ),
              child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            SizedBox(width: sizes.screenWidth * 0.025),
            Text(_labelKey(category).tr(), style: TextStyle(fontSize: sizes.screenWidth * 0.036)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final bool showError = triedSubmit && validate() != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._categories.map((c) => _categoryRow(c, sizes)),
        if (showError)
          Padding(
            padding: EdgeInsets.only(top: sizes.screenHeight * 0.004),
            child: Text(
              validate()!.tr(),
              style: TextStyle(color: AppColors.error, fontSize: sizes.screenWidth * 0.03),
            ),
          ),
      ],
    );
  }
}