import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import 'button.dart';

// ============================================================================
// LocationResult: el "value" elli LocationPickerScreen tarja3ha ba3d
// "Confirm" - lat/lng W esm el blasa (reverse-geocoding, Nominatim).
// ============================================================================
class LocationResult {
  final LatLng latLng;
  final String placeName;
  // 🔵 ZID: esm el wilaya (mel "address.state" tel Nominatim, RAW - mch
  // matché 3al 24 wilaya déjà) - el CALLER (user_create_profile.dart/
  // update_profile_owner.dart) howa elli ye3mel el match/comparaison
  // (3andou déjà "tunisiaGovernorates"), map.dart yeb9a generic.
  final String? rawStateName;

  const LocationResult({required this.latLng, required this.placeName, this.rawStateName});
}

// 🔵 helper interne bark (mch exposée barra el fichier) - "placeName" +
// "stateName" mel réponse Nominatim.
class _ReverseGeocodeResult {
  final String placeName;
  final String? stateName;
  const _ReverseGeocodeResult({required this.placeName, this.stateName});
}

// ============================================================================
// LocationPickerScreen
// ============================================================================
// Khariita interactive (OpenStreetMap). Feha 3 tri9at bch el user
// y5tar location:
//   1. Auto-locate: kif el écran yet7el, tjarreb ta5ou el GPS mte3
//      el device w tmachi lil temma direct.
//   2. Tap: el user ydouss fi ay blasa 3al khariita, marker yetbeddel.
//   3. Search: el user yekteb esm el blasa (recherche), yesta3mel
//      Nominatim (API majjaniya tel OpenStreetMap) bch yel9a el LatLng.
//   4. Coordonnées manuel: dialog sghira, el user ykteb latitude/
//      longitude direct.
// 🔴 FIX: 9bal, "Confirm" kan yrajja3 GHIR LatLng (esm el blasa TODO,
// mch mawjoud) - tawa yrajja3 LocationResult (lat/lng + esm el blasa,
// via reverse-geocoding Nominatim, ki tdouss "Confirm").
// ============================================================================
class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const LatLng _tunisCenter = LatLng(36.8065, 10.1815);

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  LatLng? _selectedLocation;
  bool _isLocating = false;
  bool _isSearching = false;
  bool _isConfirming = false; // 🔵 ZID: reverse-geocoding wa9t "Confirm"

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;

    // 🔵 Auto-locate: GHIR lowkan el user ma5tarch location mel 9bal
    // (lowkan raje3 y3addel wa7da mkhtara déjà, nkhalliwha kifha, ma
    // nghayrouhach automatique)
    if (_selectedLocation == null) {
      _goToCurrentLocation(silent: true);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _setLocation(LatLng latLng, {double zoom = 15.0}) {
    setState(() => _selectedLocation = latLng);
    _mapController.move(latLng, zoom);
  }

  // --------------------------------------------------------------------
  // 1️⃣ Auto-locate (GPS mte3 el device)
  // "silent": lowkan true (kif el écran yet7el automatique), ma
  // nwarriwch messages d'erreur (bch ma nkarhouch el user b'popup);
  // lowkan false (el user dass 3al icon "my location" b'yedou), nwarriwlou
  // el erreur lowkan fama.
  // --------------------------------------------------------------------
  Future<void> _goToCurrentLocation({bool silent = false}) async {
    setState(() => _isLocating = true);

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!silent) _showSnack('location_service_disabled_error'.tr());
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (!silent) _showSnack('location_permission_denied_error'.tr());
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (!mounted) return;
      _setLocation(LatLng(position.latitude, position.longitude));
    } catch (_) {
      if (!silent) _showSnack('location_error_generic'.tr());
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  // --------------------------------------------------------------------
  // 2️⃣ Search (Nominatim - API majjaniya tel OpenStreetMap, mate7tejch
  // API key. ⚠️ 3andha "usage policy": max 1 requête/seconde, w lezem
  // User-Agent - 7attaythom).
  // --------------------------------------------------------------------
  Future<void> _searchPlace(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => _isSearching = true);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeQueryComponent(query)}&format=json&limit=1',
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'com.example.petsy (Petsy Flutter App)'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body) as List<dynamic>;
        if (results.isEmpty) {
          _showSnack('search_no_results_error'.tr());
          return;
        }
        final lat = double.parse(results.first['lat'] as String);
        final lon = double.parse(results.first['lon'] as String);
        _setLocation(LatLng(lat, lon));
      } else {
        _showSnack('search_error_generic'.tr());
      }
    } catch (_) {
      _showSnack('search_error_generic'.tr());
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // --------------------------------------------------------------------
  // 3️⃣ Coordonnées manuel (dialog)
  // --------------------------------------------------------------------
  void _showManualCoordinatesDialog() {
    _latController.text = _selectedLocation?.latitude.toStringAsFixed(5) ?? '';
    _lngController.text = _selectedLocation?.longitude.toStringAsFixed(5) ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('enter_coordinates_title'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _latController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: InputDecoration(labelText: 'latitude_label'.tr()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _lngController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: InputDecoration(labelText: 'longitude_label'.tr()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('cancel_button'.tr()),
            ),
            TextButton(
              onPressed: () {
                final lat = double.tryParse(_latController.text.trim());
                final lng = double.tryParse(_lngController.text.trim());
                final bool valid = lat != null && lng != null && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;

                if (!valid) {
                  _showSnack('coordinates_invalid_error'.tr());
                  return;
                }
                _setLocation(LatLng(lat, lng));
                Navigator.pop(dialogContext);
              },
              child: Text('apply_button'.tr()),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------------------------
  // 🔵 ZID: reverse-geocoding (Nominatim "reverse") - mel lat/lng, njibou
  // esm el blasa (bel 7arf, mch ra9mat). Ki l'appel yefchel (bla internet,
  // etc.), nrajj3ou "lat, lng" kifha kif 9bal (fallback, mch crash).
  // --------------------------------------------------------------------
  Future<_ReverseGeocodeResult> _reverseGeocode(LatLng point) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${point.latitude}&lon=${point.longitude}&format=json&addressdetails=1&accept-language=fr',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'com.example.petsy (Petsy Flutter App)'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        final String? displayName = data['display_name'] as String?;
        // 🔵 "state" howa el 7a9el elli Nominatim yesta3milou lel
        // wilaya/gouvernorat fi Tounes (mathalan "state": "Sfax").
        final Map<String, dynamic>? address = data['address'] as Map<String, dynamic>?;
        final String? state = address?['state'] as String?;
        // 🔵 ZID: debugPrint UNCONDITIONNEL - bch nchoufou el "address"
        // el KAMLA elli Nominatim rajja3 (ken "state" mch fih Sfax,
        // n7ottou el 7a9el es-sa7i7 mel print hedha).
        debugPrint('🗺️ [reverseGeocode] address complet: ${jsonEncode(address)}');
        debugPrint('🗺️ [reverseGeocode] state extrait: "$state"');
        if (displayName != null && displayName.isNotEmpty) {
          return _ReverseGeocodeResult(placeName: displayName, stateName: state);
        }
      }
    } catch (_) {
      // fallback ta7t
    }
    return _ReverseGeocodeResult(
      placeName: '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
      stateName: null,
    );
  }

  Future<void> _onConfirmPressed() async {
    if (_selectedLocation == null) {
      _showSnack('select_location_hint'.tr());
      return;
    }

    setState(() => _isConfirming = true);
    final _ReverseGeocodeResult geocode = await _reverseGeocode(_selectedLocation!);
    if (!mounted) return;

    Navigator.of(context).pop(LocationResult(
      latLng: _selectedLocation!,
      placeName: geocode.placeName,
      rawStateName: geocode.stateName,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text('localization_label'.tr()),
        backgroundColor: AppColors.pinkpetsy,
        foregroundColor: Colors.white,
        actions: [
          // 4️⃣ Icon lel coordonnées manuel
          IconButton(
            icon: const Icon(Icons.edit_location_alt_outlined),
            tooltip: 'enter_coordinates_title'.tr(),
            onPressed: _showManualCoordinatesDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation ?? _tunisCenter,
              initialZoom: 13.0,
              onTap: (tapPosition, point) => _setLocation(point, zoom: _mapController.camera.zoom),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.petsy',
                // 🔵 zdineha: performance a7sen fel web (chrahtha fel
                // pubspec.yaml) - el tiles el mch me7tejinhom y-cancel-aw
                tileProvider: CancellableNetworkTileProvider(),
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 44,
                      height: 44,
                      child: Icon(Icons.location_on, color: AppColors.pinkpetsy, size: 44),
                    ),
                  ],
                ),
            ],
          ),

          // ------------------------------------------------------------
          // 🔍 Search bar (fouq el khariita, kifha kif Google Maps)
          // ------------------------------------------------------------
          Positioned(
            top: screenSize.height * 0.02,
            left: screenSize.width * 0.05,
            right: screenSize.width * 0.05,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(30),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: _searchPlace,
                decoration: InputDecoration(
                  hintText: 'search_place_hint'.tr(),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: _isSearching
                      ? Padding(
                          padding: const EdgeInsets.all(14),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.pinkpetsy),
                          ),
                        )
                      : Icon(Icons.search, color: AppColors.pinkpetsy),
                  suffixIcon: IconButton(
                    icon: _isLocating
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.vertpetsy),
                          )
                        : Icon(Icons.my_location, color: AppColors.vertpetsy),
                    tooltip: 'use_my_location_tooltip'.tr(),
                    onPressed: _isLocating ? null : () => _goToCurrentLocation(),
                  ),
                ),
              ),
            ),
          ),

          // Bouton "Confirm"
          Positioned(
            left: 0,
            right: 0,
            bottom: screenSize.height * 0.03,
            child: Center(
              child: CustomButton(
                text: _isConfirming ? 'loading_label'.tr() : 'confirm_location_button'.tr(),
                color: AppColors.pinkpetsy,
                widthFactor: 0.85,
                heightFactor: 0.065,
                fontFactor: 0.40,
                enabled: !_isConfirming,
                onPressed: _onConfirmPressed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}