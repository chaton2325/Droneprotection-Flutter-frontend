class AppUser {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String? avatarUrl;
  final String username;
  final bool shareLocationWithFriends;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.username,
    this.phone,
    this.avatarUrl,
    this.shareLocationWithFriends = false,
  });

  bool get canTrigger => role == 'victim' || role == 'both';
  bool get canRespond => role == 'responder' || role == 'both';
  bool get isAdmin => role == 'admin';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      avatarUrl: json['avatar_url'] as String?,
      username: json['username'] as String,
      shareLocationWithFriends: json['share_location_with_friends'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'avatar_url': avatarUrl,
      'username': username,
      'share_location_with_friends': shareLocationWithFriends,
    };
  }
}
