import '../models/friend.dart';
import '../models/friend_request.dart';
import 'api_client.dart';

class FriendRequests {
  final List<FriendRequest> incoming;
  final List<FriendRequest> outgoing;
  const FriendRequests({required this.incoming, required this.outgoing});
}

class FriendsService {
  final ApiClient _client;
  FriendsService(this._client);

  Future<List<Friend>> search(String query) async {
    final data = await _client.get('/users/search', query: {'q': query});
    return (data['users'] as List)
        .map((json) => Friend.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Friend>> listFriends() async {
    final data = await _client.get('/friends');
    return (data['friends'] as List)
        .map((json) => Friend.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<FriendRequests> listRequests() async {
    final data = await _client.get('/friends/requests');
    return FriendRequests(
      incoming: (data['incoming'] as List)
          .map((json) => FriendRequest.fromJson(json as Map<String, dynamic>))
          .toList(),
      outgoing: (data['outgoing'] as List)
          .map((json) => FriendRequest.fromJson(json as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> sendRequest(String username) async {
    await _client.post('/friends/requests', body: {'username': username});
  }

  Future<void> accept(int requestId) async {
    await _client.post('/friends/requests/$requestId/accept');
  }

  Future<void> cancelOrDecline(int requestId) async {
    await _client.delete('/friends/requests/$requestId');
  }
}
