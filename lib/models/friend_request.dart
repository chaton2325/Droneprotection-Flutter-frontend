import 'friend.dart';

/// Une demande d'ami en attente. `person` est le demandeur (liste des
/// demandes recues) ou le destinataire (liste des demandes envoyees) selon
/// la liste d'origine - voir FriendsService.listRequests.
class FriendRequest {
  final int id;
  final Friend person;
  final String createdAt;

  const FriendRequest({
    required this.id,
    required this.person,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['request_id'] as int,
      person: Friend.fromJson(json),
      createdAt: json['created_at'] as String,
    );
  }
}
