import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../controllers/active_locations_controller.dart';
import 'sitter_location_map_screen.dart';

// ============================================================================
// ActiveLocationsScreen (feature "partage de localisation") - owner
// ============================================================================
// 🔵 ZID: bouton "Localisation" fel sidebar (owner) - liste el bookings
// ACTIFS bark (status accepted + sitter 9bel ychourek + fenetre T-2h
// avant checkIn, chrahtha getActiveSitterLocations, bookingController.js).
// Privacy by design: AUCUN historique houni - un booking termé (checkout
// confirmé wla service refusé) mayban-ch fel liste, mch "supprimé" -
// ghir el backend ma yrajja3ouch fel query (dynamique, mch flag mahfoudh).
// ============================================================================
class ActiveLocationsScreen extends StatefulWidget {
  const ActiveLocationsScreen({super.key});

  @override
  State<ActiveLocationsScreen> createState() => _ActiveLocationsScreenState();
}

class _ActiveLocationsScreenState extends State<ActiveLocationsScreen> {
  final ActiveLocationsController _controller = ActiveLocationsController();
  List<ActiveSitterLocation> _locations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final locations = await _controller.fetchActiveLocations();
    if (!mounted) return;
    setState(() {
      _locations = locations;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mutedTextColor = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: Text('active_locations_title'.tr()),
        backgroundColor: AppColors.vertpetsy,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.vertpetsy,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _locations.isEmpty
                ? ListView(
                    padding: const EdgeInsets.symmetric(vertical: 120),
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.location_off_outlined, size: 64, color: mutedTextColor),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'active_locations_empty'.tr(),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: mutedTextColor, fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _locations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final loc = _locations[index];
                      return _SitterLocationCard(
                        location: loc,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => SitterLocationMapScreen(location: loc)),
                          );
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class _SitterLocationCard extends StatelessWidget {
  final ActiveSitterLocation location;
  final VoidCallback onTap;

  const _SitterLocationCard({required this.location, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(18),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.vertpetsy.withOpacity(0.15),
                backgroundImage: location.sitterPhotoUrl != null ? NetworkImage(location.sitterPhotoUrl!) : null,
                child: location.sitterPhotoUrl == null
                    ? Icon(Icons.person, color: AppColors.vertpetsy, size: 28)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(location.sitterName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    if (location.sitterLocationName.isNotEmpty)
                      Text(
                        location.sitterLocationName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65), fontSize: 13),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.map_outlined, size: 18),
                label: Text('view_itinerary_button'.tr()),
                style: TextButton.styleFrom(foregroundColor: AppColors.pinkpetsy),
              ),
            ],
          ),
        ),
      ),
    );
  }
}