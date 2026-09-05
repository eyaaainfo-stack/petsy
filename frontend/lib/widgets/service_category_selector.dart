import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../models/sitter_service_catalog.dart';
import '../models/my_profile_data.dart';
import 'outlined_button.dart';

// 🔵 "cat" / "dog" / "both" - esm el pet type mkhtar lel service.
enum SitterPetType { cat, dog, both }

class _CustomServiceEntry {
  String id;
  final TextEditingController labelController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  SitterPetType? petType;

  _CustomServiceEntry({required this.id});

  void dispose() {
    labelController.dispose();
    priceController.dispose();
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
// Testa3mel via GlobalKey<ServiceCategorySelectorState> - el parent
// screen y3ayet .validate() / .getPayload() ki y-douss "Next"/"Update".
// ============================================================================
class ServiceCategorySelector extends StatefulWidget {
  final List<SitterServiceEntry> initialServices;
  final ValueChanged<bool>? onChanged;

  const ServiceCategorySelector({super.key, this.initialServices = const [], this.onChanged});

  @override
  State<ServiceCategorySelector> createState() => ServiceCategorySelectorState();
}

class ServiceCategorySelectorState extends State<ServiceCategorySelector> {
  final Map<String, bool> _selected = {
    for (final cat in sitterServiceCatalog) for (final s in cat.services) s.id: false,
  };
  final Map<String, TextEditingController> _priceControllers = {
    for (final cat in sitterServiceCatalog) for (final s in cat.services) s.id: TextEditingController(),
  };
  final Map<String, SitterPetType?> _petTypes = {
    for (final cat in sitterServiceCatalog) for (final s in cat.services) s.id: null,
  };
  final List<_CustomServiceEntry> _customEntries = [];
  final Set<String> _expandedCategories = {};
  bool triedSubmit = false;

  @override
  void initState() {
    super.initState();
    for (final entry in widget.initialServices) {
      if (isCustomServiceId(entry.serviceId)) {
        final custom = _CustomServiceEntry(id: entry.serviceId);
        custom.labelController.text = entry.customLabel ?? '';
        custom.priceController.text = _formatPrice(entry.price);
        custom.petType = _parsePetType(entry.petType);
        _customEntries.add(custom);
        continue;
      }
      if (!_selected.containsKey(entry.serviceId)) continue;
      _selected[entry.serviceId] = true;
      _priceControllers[entry.serviceId]!.text = _formatPrice(entry.price);
      _petTypes[entry.serviceId] = _parsePetType(entry.petType);
      final category = sitterServiceCatalog.firstWhere((c) => c.services.any((s) => s.id == entry.serviceId));
      _expandedCategories.add(category.titleKey);
    }
  }

  String _formatPrice(double price) => price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2);

  SitterPetType? _parsePetType(String petType) {
    switch (petType) {
      case 'cat':
        return SitterPetType.cat;
      case 'dog':
        return SitterPetType.dog;
      case 'both':
        return SitterPetType.both;
      default:
        return null;
    }
  }

  @override
  void dispose() {
    for (final c in _priceControllers.values) {
      c.dispose();
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
    if (!hasAtLeastOneService) return 'sitter_service_required_error';
    for (final cat in sitterServiceCatalog) {
      for (final s in cat.services) {
        if (_selected[s.id] != true) continue;
        final priceText = _priceControllers[s.id]!.text.trim();
        if (priceText.isEmpty || double.tryParse(priceText) == null) return 'sitter_price_required_error';
        if (_petTypes[s.id] == null) return 'sitter_pet_type_required_error';
      }
    }
    for (final entry in _customEntries) {
      if (entry.labelController.text.trim().isEmpty) return 'sitter_custom_service_name_required_error';
      final priceText = entry.priceController.text.trim();
      if (priceText.isEmpty || double.tryParse(priceText) == null) return 'sitter_price_required_error';
      if (entry.petType == null) return 'sitter_pet_type_required_error';
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
            'price': double.parse(_priceControllers[s.id]!.text.trim()),
            'petType': _petTypes[s.id]!.name,
          });
        }
      }
    }
    for (final entry in _customEntries) {
      payload.add({
        'serviceId': entry.id,
        'customLabel': entry.labelController.text.trim(),
        'price': double.parse(entry.priceController.text.trim()),
        'petType': entry.petType!.name,
      });
    }
    return payload;
  }

  void markTriedSubmit() => setState(() => triedSubmit = true);

  void _toggleService(String id) {
    setState(() {
      _selected[id] = !(_selected[id] ?? false);
      if (_selected[id] == false) {
        _priceControllers[id]!.clear();
        _petTypes[id] = null;
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

  Widget _serviceRow(SitterServiceDef service, AppSizes sizes) {
    final bool isChecked = _selected[service.id] ?? false;
    final bool showError = triedSubmit &&
        isChecked &&
        (_priceControllers[service.id]!.text.trim().isEmpty ||
            double.tryParse(_priceControllers[service.id]!.text.trim()) == null ||
            _petTypes[service.id] == null);

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
                  _priceField(_priceControllers[service.id]!, sizes),
                  SizedBox(height: sizes.screenHeight * 0.012),
                  _petTypeRow(
                    selected: _petTypes[service.id],
                    onSelect: (t) => setState(() => _petTypes[service.id] = t),
                    sizes: sizes,
                  ),
                  if (showError) ...[
                    SizedBox(height: sizes.screenHeight * 0.006),
                    Text(
                      _priceControllers[service.id]!.text.trim().isEmpty || double.tryParse(_priceControllers[service.id]!.text.trim()) == null
                          ? 'sitter_price_required_error'.tr()
                          : 'sitter_pet_type_required_error'.tr(),
                      style: TextStyle(color: AppColors.error, fontSize: sizes.screenWidth * 0.028),
                    ),
                  ],
                ],
              ),
            ),
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

  Widget _petTypeRow({required SitterPetType? selected, required ValueChanged<SitterPetType> onSelect, required AppSizes sizes}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('sitter_pet_type_label'.tr(), style: TextStyle(fontSize: sizes.screenWidth * 0.030, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7))),
        SizedBox(height: sizes.screenHeight * 0.008),
        Row(
          children: [
            Expanded(child: CustomOutlinedButton(text: 'sitter_pet_type_cat'.tr(), isSelected: selected == SitterPetType.cat, height: sizes.screenHeight * 0.045, fontFactor: 0.34, onPressed: () => onSelect(SitterPetType.cat))),
            SizedBox(width: sizes.screenWidth * 0.02),
            Expanded(child: CustomOutlinedButton(text: 'sitter_pet_type_dog'.tr(), isSelected: selected == SitterPetType.dog, height: sizes.screenHeight * 0.045, fontFactor: 0.34, onPressed: () => onSelect(SitterPetType.dog))),
            SizedBox(width: sizes.screenWidth * 0.02),
            Expanded(child: CustomOutlinedButton(text: 'sitter_pet_type_both'.tr(), isSelected: selected == SitterPetType.both, height: sizes.screenHeight * 0.045, fontFactor: 0.34, onPressed: () => onSelect(SitterPetType.both))),
          ],
        ),
      ],
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

  Widget _customServiceRow(int index, AppSizes sizes) {
    final entry = _customEntries[index];
    final bool showError = triedSubmit &&
        (entry.labelController.text.trim().isEmpty ||
            entry.priceController.text.trim().isEmpty ||
            double.tryParse(entry.priceController.text.trim()) == null ||
            entry.petType == null);

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
          _priceField(entry.priceController, sizes),
          SizedBox(height: sizes.screenHeight * 0.012),
          _petTypeRow(selected: entry.petType, onSelect: (t) => setState(() => entry.petType = t), sizes: sizes),
          if (showError) ...[
            SizedBox(height: sizes.screenHeight * 0.006),
            Text(
              entry.labelController.text.trim().isEmpty
                  ? 'sitter_custom_service_name_required_error'.tr()
                  : (entry.priceController.text.trim().isEmpty || double.tryParse(entry.priceController.text.trim()) == null)
                      ? 'sitter_price_required_error'.tr()
                      : 'sitter_pet_type_required_error'.tr(),
              style: TextStyle(color: AppColors.error, fontSize: sizes.screenWidth * 0.028),
            ),
          ],
        ],
      ),
    );
  }
}