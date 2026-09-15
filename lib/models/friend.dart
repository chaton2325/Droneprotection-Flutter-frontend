class Friend {
  final int id;
  final String username;
  final String fullName;
  final String? avatarUrl;

  const Friend({
    required this.id,
    required this.username,
    required this.fullName,
    this.avatarUrl,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as int,
      username: json['username'] as String,
      fullName: json['full_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
