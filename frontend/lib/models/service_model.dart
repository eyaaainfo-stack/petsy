// ============================================================================
// ServiceModel
// ============================================================================
// 🔵 TODO: el diagramme mazel ma yweri "provider" (Gardien/Courier elli
// ye9dem el service) - nzid "providerId" ki tkoun el fikra wadhe7a aktar.
// ============================================================================
class ServiceModel {
  final String? id;
  final String ownerId;
  final String type;
  final String description;
  final double price;

  ServiceModel({
    this.id,
    required this.ownerId,
    required this.type,
    this.description = '',
    this.price = 0,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['_id'] as String?,
      ownerId: json['owner'] as String,
      type: json['type'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'owner': ownerId,
      'type': type,
      'description': description,
      'price': price,
    };
  }
}