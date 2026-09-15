class EmergencyAlert {
  final int id;
  final String status; // pending | accepted | resolved | cancelled
  final String? message;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? locationName;
  final int userId;
  final String victimName;
  final String? victimPhone;
  final int? acceptedBy;
  final String? responderName;
  final String? responderPhone;
  final String? responderAvatarUrl;
  final String? acceptedAt;
  final String? resolvedAt;
  final String createdAt;
  final String updatedAt;

  const EmergencyAlert({
    required this.id,
    required this.status,
    required this.userId,
    required this.victimName,
    required this.createdAt,
    required this.updatedAt,
    this.message,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.locationName,
    this.victimPhone,
    this.acceptedBy,
    this.responderName,
    this.responderPhone,
    this.responderAvatarUrl,
    this.acceptedAt,
    this.resolvedAt,
  });

  bool get isActive => status == 'pending' || status == 'accepted';

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    double? asDouble(dynamic value) {
      if (value == null) return null;
      return (value as num).toDouble();
    }

    return EmergencyAlert(
      id: json['id'] as int,
      status: json['status'] as String,
      message: json['message'] as String?,
      latitude: asDouble(json['latitude']),
      longitude: asDouble(json['longitude']),
      accuracy: asDouble(json['accuracy']),
      locationName: json['location_name'] as String?,
      userId: json['user_id'] as int,
      victimName: json['victim_name'] as String,
      victimPhone: json['victim_phone'] as String?,
      acceptedBy: json['accepted_by'] as int?,
      responderName: json['responder_name'] as String?,
      responderPhone: json['responder_phone'] as String?,
      responderAvatarUrl: json['responder_avatar_url'] as String?,
      acceptedAt: json['accepted_at'] as String?,
      resolvedAt: json['resolved_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}
