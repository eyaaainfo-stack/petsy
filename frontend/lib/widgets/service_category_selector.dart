import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../models/sitter_service_catalog.dart';
import '../models/my_profile_data.dart';

// 🔵 esm el category (small_dog/guard_dog/cat) traduit - esta3mlneha
// houni w fel "Autre" (custom) zeda.
String categoryPriceLabel(String category) {
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

class _CustomServiceEntry {
  String id;
  final TextEditingController labelController = TextEditingController();
  // 🔵 ZID (feature "compatibilite entre animaux"): prix MNFASSEL l'kol
  // category (mch price+petType wa7dania) - key = category.
  final Map<String, TextEditingController> priceControllers = {};

  _CustomServiceEntry({required this.id});

  TextEditingController priceCtrl(String category) =>
      priceControllers.putIfAbsent(category, () => TextEditingController());

  void dispose() {
    labelController.dispose();
    for (final c in priceControllers.values) {
      c.dispose();
    }
  }
}

// ============================================================================
// ServiceCategorySelector (kifma tlab: "les services nhbhom fi des
// titre w ki tenzel alihom yethallou hedhom... ken yhb yzid service
// ekher")
// ============================================================================
// 🔵 Widget WA7ED, testa3mel fel create_sitter_profile.dart (signup) W
// update_profile_sitter.dart (édition) - accordion (ExpansionTile) 3ala
// kol category (Toilettage/Garde d'animaux/Promenade/Dressage), kol
// wa7da tafte7 3al sous-services tou3ha, + section "Autre" (custom,
// bla limite - "+" yzid, "x" ynaحhi).
//
// 🔵 ZID (feature "compatibilite entre animaux"): "acceptedCategories"
// - el categories (small_dog/guard_dog/cat) elli el sitter 5tarhom
// FEL BOX EL FOU9 (AcceptedCategoriesSelector). Kol service mkhtar,
// el sitter y7ott PRIX MNFASSEL l'KOL wa7da mel categories hedhom
// (mch petType cat/dog/both wa7dania kifma 9bal).
//
// Testa3mel via GlobalKey<ServiceCategorySelectorState> - el parent
// screen y3ayet .validate() / .getPayload() ki y-douss "Next"/"Update".
// ============================================================================
class ServiceCategorySelector extends StatefulWidget {
  final List<SitterServiceEntry> initialServices;
  final List<String> acceptedCategories;
  final ValueChanged<bool>? onChanged;

  const ServiceCategorySelector({
    super.key,
    this.initialServices = const [],
    this.acceptedCategories = const [],
    this.onChanged,
  });

  @override
  State<ServiceCategorySelector> createState() => ServiceCategorySelectorState();
}

class ServiceCategorySelectorState extends State<ServiceCategorySelector> {
  final Map<String, bool> _selected = {
    for (final cat in sitterServiceCatalog) for (final s in cat.services) s.id: false,
  };
  // 🔵 serviceId -> category -> controller (lazy - "_ctrl" ye5le9ha
  // ken ma3andha, bla ma nzid logique "sync" complexa ki el categories
  // el mkhtarin fel box el fou9 yetbedlou).
  final Map<String, Map<String, TextEditingController>> _priceControllers = {};
  final List<_CustomServiceEntry> _customEntries = [];
  final Set<String> _expandedCategories = {};
  bool triedSubmit = false;

  TextEditingController _ctrl(String serviceId, String category) {
    final serviceMap = _priceControllers.putIfAbsent(serviceId, () => {});
    return serviceMap.putIfAbsent(category, () => TextEditingController());
  }

  @override
  void initState() {
    super.initState();
    for (final entry in widget.initialServices) {
      if (isCustomServiceId(entry.serviceId)) {
        final custom = _CustomServiceEntry(id: entry.serviceId);
        custom.labelController.text = entry.customLabel ?? '';
        for (final p in entry.prices) {
          custom.priceCtrl(p.category).text = _formatPrice(p.price);
        }
        _customEntries.add(custom);
        continue;
      }
      if (!_selected.containsKey(entry.serviceId)) continue;
      _selected[entry.serviceId] = true;
      for (final p in entry.prices) {
        _ctrl(entry.serviceId, p.category).text = _formatPrice(p.price);
      }
      final category = sitterServiceCatalog.firstWhere((c) => c.services.any((s) => s.id == entry.serviceId));
      _expandedCategories.add(category.titleKey);
    }
  }

  String _formatPrice(double price) => price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2);

  @override
  void dispose() {
    for (final serviceMap in _priceControllers.values) {
      for (final c in serviceMap.values) {
        c.dispose();
      }
    }
    for (final e in _customEntries) {
      e.dispose();
    }
    super.dispose();
  }

  // --------------------------------------------------------------------
  // API publique (el parent screen yesta3melha - GlobalKey.currentState).
  // --------------------------------------------------------------------
  bool get hasAtLeastOneService => _selected.values.any((v) => v) || _customEntries.isNotEmpty;

  // Terja3 el translation key tel erreur (null lowkan kolchi sa7i7).
  String? validate() {
    if (widget.acceptedCategories.isEmpty) return 'sitter_accepted_categories_required_error';
    if (!hasAtLeastOneService) return 'sitter_service_required_error';
    // 🔵 ZID (kifma tlab: "mch chart enou nwafrou lel 3 types") -
    // n3awdou nesta3mlou nafs el logique tel _serviceHasError/
    // _customEntryHasError (l'a9al wa7da bark, mch lel categories el kol).
    for (final cat in sitterServiceCatalog) {
      for (final s in cat.services) {
        if (_selected[s.id] != true) continue;
        if (_serviceHasError(s.id)) return 'sitter_price_required_error';
      }
    }
    for (final entry in _customEntries) {
      if (entry.labelController.text.trim().isEmpty) return 'sitter_custom_service_name_required_error';
      if (_customEntryHasError(entry)) return 'sitter_price_required_error';
    }
    return null;
  }

  List<Map<String, dynamic>> getPayload() {
    final List<Map<String, dynamic>> payload = [];
    for (final cat in sitterServiceCatalog) {
      for (final s in cat.services) {
        if (_selected[s.id] == true) {
          payload.add({
            'serviceId': s.id,
            // 🔵 ZID (kifma tlab): GHIR el categories elli 3andhom
            // prix mzoud 7a9i9atan (mch el 3 el kol automatique) -
            // category متروكة فارغة = "el service hedha ma yban-lich
            // l'category hedhi".
            'prices': [
              for (final category in widget.acceptedCategories)
                if (_ctrl(s.id, category).text.trim().isNotEmpty)
                  {'category': category, 'price': double.parse(_ctrl(s.id, category).text.trim())},
            ],
          });
        }
      }
    }
    for (final entry in _customEntries) {
      payload.add({
        'serviceId': entry.id,
        'customLabel': entry.labelController.text.trim(),
        'prices': [
          for (final category in widget.acceptedCategories)
            if (entry.priceCtrl(category).text.trim().isNotEmpty)
              {'category': category, 'price': double.parse(entry.priceCtrl(category).text.trim())},
        ],
      });
    }
    return payload;
  }

  void markTriedSubmit() => setState(() => triedSubmit = true);

  void _toggleService(String id) {
    setState(() {
      _selected[id] = !(_selected[id] ?? false);
      if (_selected[id] == false) {
        _priceControllers[id]?.forEach((_, c) => c.clear());
      }
    });
    widget.onChanged?.call(hasAtLeastOneService);
  }

  void _addCustomEntry() {
    setState(() => _customEntries.add(_CustomServiceEntry(id: generateCustomServiceId())));
    widget.onChanged?.call(hasAtLeastOneService);
  }

  void _removeCustomEntry(int index) {
    setState(() {
      _customEntries[index].dispose();
      _customEntries.removeAt(index);
    });
    widget.onChanged?.call(hasAtLeastOneService);
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final cat in sitterServiceCatalog) _categoryTile(cat, sizes),
        SizedBox(height: sizes.screenHeight * 0.02),
        _customServicesSection(sizes),
      ],
    );
  }

  Widget _categoryTile(SitterServiceCategory cat, AppSizes sizes) {
    final int selectedCount = cat.services.where((s) => _selected[s.id] == true).length;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: ValueKey(cat.titleKey),
        initiallyExpanded: _expandedCategories.contains(cat.titleKey),
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.only(left: sizes.screenWidth * 0.02),
        leading: Icon(cat.icon, color: AppColors.vertpetsy),
        title: Text(
          cat.titleKey.tr(),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.screenWidth * 0.038),
        ),
        trailing: selectedCount > 0
            ? Container(
                padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.02, vertical: sizes.screenWidth * 0.006),
                decoration: BoxDecoration(color: AppColors.pinkpetsy, borderRadius: BorderRadius.circular(20)),
                child: Text('$selectedCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              )
            : const Icon(Icons.expand_more),
        children: [for (final s in cat.services) _serviceRow(s, sizes)],
      ),
    );
  }

  bool _serviceHasError(String serviceId) {
    if (widget.acceptedCategories.isEmpty) return true;
    // 🔵 ZID (kifma tlab: "mch chart enou nwafrou lel 3 types") - el
    // sitter ynajjam ye5tar service w y7ott prix l'BA3DH el categories
    // bark (mch lel kol) - lezmou GHIR "l'a9al wa7da" valide, w bla
    // 7atta category fiha text "ghalet" (entered ama mch ra9m).
    bool hasAtLeastOnePrice = false;
    for (final category in widget.acceptedCategories) {
      final text = _ctrl(serviceId, category).text.trim();
      if (text.isEmpty) continue; // optional - mch obligatoire l'kol category
      if (double.tryParse(text) == null) return true; // entered ama ghalet
      hasAtLeastOnePrice = true;
    }
    return !hasAtLeastOnePrice;
  }

  Widget _serviceRow(SitterServiceDef service, AppSizes sizes) {
    final bool isChecked = _selected[service.id] ?? false;
    final bool showError = triedSubmit && isChecked && _serviceHasError(service.id);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.006),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _toggleService(service.id),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: sizes.screenWidth * 0.012),
              child: Row(
                children: [
                  Checkbox(value: isChecked, activeColor: AppColors.vertpetsy, onChanged: (_) => _toggleService(service.id)),
                  Expanded(
                    child: Text(
                      service.labelKey.tr(),
                      style: TextStyle(
                        fontSize: sizes.screenWidth * 0.037,
                        fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 🔴 FIX (bug: "Assertion failed... _elements.contains(element)
          // is not true" - Flutter crash ki ta7ki 3ala checkbox). El
          // sebba: "AnimatedSize" (implicit animation) EL DA5EL fi
          // "ExpansionTile" (elli 3andou el animation tou3ou l'category
          // el kaملa) - 2 animations "implicit" mtada5lin f nefs el
          // wa9t ychwachou el element tree tel Flutter (bug ma3rouf,
          // AnimatedSize/AnimatedSwitcher DA5EL ExpansionTile). El 7all:
          // n7iw el animation el da5liya (conditional 3adi, bla animation
          // - el category el barrania (ExpansionTile) mazelt tetba3 wa7dha).
          if (isChecked)
            Padding(
              padding: EdgeInsets.only(left: sizes.screenWidth * 0.10, right: sizes.screenWidth * 0.02, bottom: sizes.screenHeight * 0.014),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.acceptedCategories.isEmpty)
                    Text('sitter_no_accepted_categories_hint'.tr(), style: TextStyle(color: AppColors.error, fontSize: sizes.screenWidth * 0.03))
                  else
                    for (final category in widget.acceptedCategories) _categoryPriceField(service.id, category, sizes),
                  if (showError && widget.acceptedCategories.isNotEmpty) ...[
                    SizedBox(height: sizes.screenHeight * 0.006),
                    Text('sitter_price_required_error'.tr(), style: TextStyle(color: AppColors.error, fontSize: sizes.screenWidth * 0.028)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _categoryPriceField(String serviceId, String category, AppSizes sizes) {
    return Padding(
      padding: EdgeInsets.only(bottom: sizes.screenHeight * 0.01),
      child: Row(
        children: [
          SizedBox(
            width: sizes.screenWidth * 0.26,
            child: Text(categoryPriceLabel(category), style: TextStyle(fontSize: sizes.screenWidth * 0.031)),
          ),
          Expanded(child: _priceField(_ctrl(serviceId, category), sizes)),
        ],
      ),
    );
  }

  Widget _priceField(TextEditingController controller, AppSizes sizes) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
      onChanged: (_) => setState(() {}),
      style: TextStyle(fontSize: sizes.screenWidth * 0.035),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'sitter_service_price_hint'.tr(),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: sizes.screenWidth * 0.033),
        suffixText: 'TND',
        suffixStyle: TextStyle(color: AppColors.vertpetsy, fontWeight: FontWeight.w600, fontSize: sizes.screenWidth * 0.032),
        contentPadding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.035, vertical: sizes.screenHeight * 0.012),
        filled: true,
        fillColor: AppColors.vertpetsy.withOpacity(0.07),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.vertpetsy.withOpacity(0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.vertpetsy, width: 1.8)),
      ),
    );
  }

  // --------------------------------------------------------------------
  // "Autre" (kifma tlab: "ken yhb yzid service ekher") - service custom,
  // el sitter yekteb esmou b ydik (bla limite 3adad - "+" yzid sef jdid).
  // --------------------------------------------------------------------
  Widget _customServicesSection(AppSizes sizes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _addCustomEntry,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.01),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, color: AppColors.pinkpetsy, size: sizes.screenWidth * 0.05),
                SizedBox(width: sizes.screenWidth * 0.02),
                Text(
                  'sitter_add_other_service_button'.tr(),
                  style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.w600, fontSize: sizes.screenWidth * 0.037),
                ),
              ],
            ),
          ),
        ),
        for (int i = 0; i < _customEntries.length; i++) _customServiceRow(i, sizes),
      ],
    );
  }

  bool _customEntryHasError(_CustomServiceEntry entry) {
    if (entry.labelController.text.trim().isEmpty) return true;
    if (widget.acceptedCategories.isEmpty) return true;
    // 🔵 ZID (kifma tlab): nafs raison tel _serviceHasError - l'a9al
    // wa7da bark, mch lel 3 categories el kol.
    bool hasAtLeastOnePrice = false;
    for (final category in widget.acceptedCategories) {
      final text = entry.priceCtrl(category).text.trim();
      if (text.isEmpty) continue;
      if (double.tryParse(text) == null) return true;
      hasAtLeastOnePrice = true;
    }
    return !hasAtLeastOnePrice;
  }

  Widget _customServiceRow(int index, AppSizes sizes) {
    final entry = _customEntries[index];
    final bool showError = triedSubmit && _customEntryHasError(entry);
    final bool labelMissing = entry.labelController.text.trim().isEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: sizes.screenHeight * 0.014),
      padding: EdgeInsets.all(sizes.screenWidth * 0.03),
      decoration: BoxDecoration(color: AppColors.pinkpetsy.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.pinkpetsy.withOpacity(0.25))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: entry.labelController,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(fontSize: sizes.screenWidth * 0.035),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'sitter_custom_service_name_hint'.tr(),
                    contentPadding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.03, vertical: sizes.screenHeight * 0.012),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _removeCustomEntry(index),
                icon: Icon(Icons.close, color: AppColors.error, size: sizes.screenWidth * 0.05),
              ),
            ],
          ),
          SizedBox(height: sizes.screenHeight * 0.01),
          if (widget.acceptedCategories.isEmpty)
            Text('sitter_no_accepted_categories_hint'.tr(), style: TextStyle(color: AppColors.error, fontSize: sizes.screenWidth * 0.03))
          else
            for (final category in widget.acceptedCategories)
              Padding(
                padding: EdgeInsets.only(bottom: sizes.screenHeight * 0.01),
                child: Row(
                  children: [
                    SizedBox(
                      width: sizes.screenWidth * 0.26,
                      child: Text(categoryPriceLabel(category), style: TextStyle(fontSize: sizes.screenWidth * 0.031)),
                    ),
                    Expanded(child: _priceField(entry.priceCtrl(category), sizes)),
                  ],
                ),
              ),
          if (showError) ...[
            SizedBox(height: sizes.screenHeight * 0.006),
            Text(
              labelMissing ? 'sitter_custom_service_name_required_error'.tr() : 'sitter_price_required_error'.tr(),
              style: TextStyle(color: AppColors.error, fontSize: sizes.screenWidth * 0.028),
            ),
          ],
        ],
      ),
    );
  }
}