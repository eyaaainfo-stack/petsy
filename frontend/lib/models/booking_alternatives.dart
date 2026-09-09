// ============================================================================
// BookingAlternatives (feature "compatibilite entre animaux")
// ============================================================================
// 🔵 ZID: data holder l'nateeja tel GET /bookings/alternatives - ki
// createBooking/respond/confirmCandidate yرجعو 409 (conflit category/
// capacite), request_a_book.dart yeste5dem hedhi el classes bch ywarri
// popup ("Khyar A": horaire ekher 3and nefs el sitter, "Khyar B":
// sitters okhrin).
// ============================================================================
class AlternativeSlot {
  final DateTime checkIn;
  final DateTime checkOut;

  const AlternativeSlot({required this.checkIn, required this.checkOut});

  factory AlternativeSlot.fromJson(Map<String, dynamic> json) {
    return AlternativeSlot(
      checkIn: DateTime.parse(json['checkIn'] as String).toLocal(),
      checkOut: DateTime.parse(json['checkOut'] as String).toLocal(),
    );
  }
}

class AlternativeSitter {
  final String sitterId;
  final String fullName;
  final String? photoUrl;
  final String? city;
  // 🔵 'free' (fadhi kaملement) wala 'joinGroup' (ynajjam yzid, < 5)
  final String type;
  final int existingCount;
  // 🔵 ZID (feature "compatibilite entre animaux"): tarif had sitter
  // l'category el mtaleba (null lowkan, 7ala nadra, ma7dedouch).
  final double? price;

  const AlternativeSitter({
    required this.sitterId,
    required this.fullName,
    this.photoUrl,
    this.city,
    required this.type,
    required this.existingCount,
    this.price,
  });

  bool get isJoinGroup => type == 'joinGroup';

  factory AlternativeSitter.fromJson(Map<String, dynamic> json) {
    return AlternativeSitter(
      sitterId: json['sitterId'] as String,
      fullName: json['fullName'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      city: json['city'] as String?,
      type: json['type'] as String? ?? 'free',
      existingCount: (json['existingCount'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble(),
    );
  }
}

class BookingAlternatives {
  final String? category;
  final List<AlternativeSlot> sameSitterSlots;
  final List<AlternativeSitter> otherSitters;

  const BookingAlternatives({
    this.category,
    this.sameSitterSlots = const [],
    this.otherSitters = const [],
  });

  bool get isEmpty => sameSitterSlots.isEmpty && otherSitters.isEmpty;

  factory BookingAlternatives.fromJson(Map<String, dynamic> json) {
    return BookingAlternatives(
      category: json['category'] as String?,
      sameSitterSlots: (json['sameSitterSlots'] as List<dynamic>? ?? [])
          .map((e) => AlternativeSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
      otherSitters: (json['otherSitters'] as List<dynamic>? ?? [])
          .map((e) => AlternativeSitter.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}