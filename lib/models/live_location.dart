class LiveLocationUpdate {
  final int id;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final double latitude;
  final double longitude;
  final String updatedAt;

  const LiveLocationUpdate({
    required this.id,
    required this.username,
    required this.fullName,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
    this.avatarUrl,
  });

  factory LiveLocationUpdate.fromJson(Map<String, dynamic> json) {
    return LiveLocationUpdate(
      id: json['id'] as int,
      username: json['username'] as String,
      fullName: json['full_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      updatedAt: json['updated_at'] as String,
    );
  }
}
