import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../../constants/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../controllers/auth_session.dart';
import '../../../controllers/active_locations_controller.dart';

// ============================================================================
// SitterLocationMapScreen (feature "partage de localisation") - owner
// ============================================================================
// 🔵 ZID: khariita (OpenStreetMap, nafs tile layer mta3 map.dart) elli
// twarri el itinéraire mel adresse tel owner (GET /users/profile - el
// "location" mahfoudha fel profil, mch GPS live) l'adresse tel sitter
// (jeya mel ActiveSitterLocation, tawa fixe - sitter mahouch متحرك, howa
// stationnaire fi daro, chrahtha el design). El trajet metcalculé UNE
// SEULE FOIS (routing OSRM), mch "live tracking" - ma7tajch permission
// GPS background wla infra websocket.
// ============================================================================
class SitterLocationMapScreen extends StatefulWidget {
  final ActiveSitterLocation location;

  const SitterLocationMapScreen({super.key, required this.location});

  @override
  State<SitterLocationMapScreen> createState() => _SitterLocationMapScreenState();
}

class _SitterLocationMapScreenState extends State<SitterLocationMapScreen> {
  LatLng? _ownerLocation;
  List<LatLng> _routePoints = [];
  bool _isLoading = true;
  bool _routeError = false;

  // 🔴 FIX (kifma tlab: "lezemni na3mel mouvement mtaa takbir wla
  // tasghir bch tedhher el map, nhabha todhher toul") - 9bal, kunna
  // nbnou FlutterMap b'center par défaut, w MBA3D (postFrameCallback +
  // mapController.fitCamera) n"na77iw" el vue lel 2 markers - flutter_map
  // ma ye-triggerich toujours el téléchargement tel tiles el jodod ki
  // el camera tetbeddel PROGRAMMATIQUEMENT (bla geste tel user), fa
  // el tiles yeb9aw ma tzidech ma yban-ch 7atta el user ye5dem
  // pincer/zoom (event manuel, houwa eli yTRIGGERI el chargement).
  // Tawa: na7sebhom el center/zoom SA7I7 9BAL ma nbnou FlutterMap (bla
  // ay fitCamera mn ba3d) - el vue el sa7i7a tban mel FRAME EL AWEL.
  LatLng? _initialCenter;
  double _initialZoom = 13.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final owner = await _fetchOwnerLocation();
    if (!mounted) return;

    setState(() => _ownerLocation = owner);

    if (owner != null) {
      final sitter = LatLng(widget.location.lat, widget.location.lng);
      final route = await _fetchRoute(owner, sitter);
      if (!mounted) return;

      final mapSize = MediaQuery.of(context).size;
      setState(() {
        _routePoints = route;
        _routeError = route.isEmpty;
        _initialCenter = LatLng((owner.latitude + sitter.latitude) / 2, (owner.longitude + sitter.longitude) / 2);
        _initialZoom = _boundsZoom(owner, sitter, mapSize);
      });
    }

    setState(() => _isLoading = false);
  }

  // 🔵 FIX (kifma tlab: "walet awl ma todhher sghira barcha!!!") - el
  // heuristique el 9dima (distance -> zoom, des paliers fixes) kanet
  // trop prudente (tzoom-out aktar mel lezem). Tawa: calcul EXACT (nafs
  // l'algorithme "getBoundsZoomLevel" mosta3mel fel Google Maps JS API)
  // - ye5dem mel taille RÉELLE tel écran (MediaQuery), bch el 2 markers
  // yeb9aw tal3in KBAR w wadh7in (bla zoom-out zeyed bla lezma).
  double _boundsZoom(LatLng a, LatLng b, Size screenSize) {
    // 🔵 marge: el map ma tekhodch el screen KAMEL (AppBar + un peu de
    // padding visuel bch les markers ma yebqawch 3al 7affa).
    final mapWidth = screenSize.width - 40;
    final mapHeight = screenSize.height - 220;

    double latRad(double lat) {
      final sinVal = math.sin(lat * math.pi / 180);
      final radX2 = math.log((1 + sinVal) / (1 - sinVal)) / 2;
      return (radX2.clamp(-math.pi, math.pi)) / 2;
    }

    double zoomForFraction(double mapPx, double worldPx, double fraction) {
      if (fraction <= 0) return 21;
      return (math.log(mapPx / worldPx / fraction) / math.ln2);
    }

    final north = math.max(a.latitude, b.latitude);
    final south = math.min(a.latitude, b.latitude);
    final east = math.max(a.longitude, b.longitude);
    final west = math.min(a.longitude, b.longitude);

    final latFraction = (latRad(north) - latRad(south)) / math.pi;
    final lngDiff = east - west;
    final lngFraction = (lngDiff < 0 ? lngDiff + 360 : lngDiff) / 360;

    // 🔵 "* 0.82": marge ~18% (bch les 2 markers + le trajet ma
    // yetqass-ouch 3al 7affa exact tel écran).
    final latZoom = zoomForFraction(mapHeight, 256, latFraction == 0 ? 0.0001 : latFraction / 0.82);
    final lngZoom = zoomForFraction(mapWidth, 256, lngFraction == 0 ? 0.0001 : lngFraction / 0.82);

    final zoom = math.min(latZoom, lngZoom);
    return zoom.clamp(3.0, 17.0);
  }

  // 🔵 el adresse mahfoudha tel owner (profil) - MCH GPS live tel device.
  Future<LatLng?> _fetchOwnerLocation() async {
    try {
      final response = await ApiService.get('/users/profile', token: AuthSession.token);
      if (response.statusCode != 200) return null;
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final Map<String, dynamic>? user = data['user'] as Map<String, dynamic>?;
      final Map<String, dynamic>? loc = user?['location'] as Map<String, dynamic>?;
      final lat = (loc?['lat'] as num?)?.toDouble();
      final lng = (loc?['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      return LatLng(lat, lng);
    } catch (_) {
      return null;
    }
  }

  // 🔵 OSRM (routing majjani, mabni 3al OpenStreetMap - nafs l'esprit
  // Nominatim el mosta3mel déjà fel LocationPickerScreen, widgets/map.dart)
  // - trajet "driving" mel owner l'dar el sitter, marra wa7da bark
  // (mch recalculé kol X secondes - mafamech "live" houni).
  Future<List<LatLng>> _fetchRoute(LatLng from, LatLng to) async {
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic>? routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return [];

      final Map<String, dynamic> geometry = routes.first['geometry'] as Map<String, dynamic>;
      final List<dynamic> coords = geometry['coordinates'] as List<dynamic>;
      // 🔵 GeoJSON = [lng, lat] (l'3aks tel LatLng) - lezem el inversion.
      return coords.map((c) => LatLng((c as List)[1] as double, c[0] as double)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final sitter = LatLng(widget.location.lat, widget.location.lng);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.location.sitterName),
        backgroundColor: AppColors.vertpetsy,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: _initialCenter ?? _ownerLocation ?? sitter,
                    initialZoom: _initialZoom,
                  ),
                  children: [
                    TileLayer(
                      // 🔴 FIX (kifma tlab: "dhoretli API KEY REQUIRED")
                      // - CartoDB Voyager (dhorna, l'essai el 9dim) tawa
                      // ye7taj compte/clé (bدلou el policy). Tawa: OSM el
                      // direct (tile.openstreetmap.org) - majjani 100%,
                      // BLA clé, w BLA "{r}" (mafamech mochkla retina).
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.petsy',
                      tileProvider: CancellableNetworkTileProvider(),
                      errorTileCallback: (tile, error, stackTrace) {
                        debugPrint('🗺️ [SitterLocationMap] tile error: $error');
                      },
                    ),
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(points: _routePoints, strokeWidth: 5, color: AppColors.pinkpetsy),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: sitter,
                          width: 46,
                          height: 46,
                          child: Icon(Icons.pets, color: AppColors.vertpetsy, size: 40),
                        ),
                        if (_ownerLocation != null)
                          Marker(
                            point: _ownerLocation!,
                            width: 46,
                            height: 46,
                            child: Icon(Icons.home, color: AppColors.pinkpetsy, size: 40),
                          ),
                      ],
                    ),
                  ],
                ),
                if (_ownerLocation == null)
                  _InfoBanner(text: 'owner_location_missing_error'.tr()),
                if (_ownerLocation != null && _routeError)
                  _InfoBanner(text: 'route_unavailable_error'.tr()),
              ],
            ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13), textAlign: TextAlign.center),
        ),
      ),
    );
  }
}