// ============================================================================
// ReservationModel
// ============================================================================
class ReservationModel {
  final String? id;
  final String serviceId;
  final String status; // pending / confirmed / completed / cancelled
  final DateTime? startDate;
  final DateTime? endDate;

  ReservationModel({
    this.id,
    required this.serviceId,
    this.status = 'pending',
    this.startDate,
    this.endDate,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['_id'] as String?,
      serviceId: json['service'] as String,
      status: json['status'] as String? ?? 'pending',
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'] as String) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service': serviceId,
      'status': status,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }
}