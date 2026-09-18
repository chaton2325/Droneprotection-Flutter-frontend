class Friend {
  final int id;
  final String username;
  final String fullName;
  final String? avatarUrl;

  /// Id de la relation d'amitie (table friendships), present uniquement pour
  /// les amis deja acceptes (voir FriendsService.listFriends) - c'est ce qui
  /// permet de retirer un ami via FriendsService.removeFriend.
  final int? friendshipId;

  const Friend({
    required this.id,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    this.friendshipId,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as int,
      username: json['username'] as String,
      fullName: json['full_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      friendshipId: json['friendship_id'] as int?,
    );
  }
}
