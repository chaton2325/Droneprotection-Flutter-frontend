import 'package:flutter/foundation.dart';
import '../models/friend.dart';
import '../models/friend_request.dart';
import '../services/friends_service.dart';

class FriendsProvider extends ChangeNotifier {
  final FriendsService friendsService;
  FriendsProvider({required this.friendsService});

  List<Friend> friends = [];
  List<FriendRequest> incoming = [];
  List<FriendRequest> outgoing = [];
  List<Friend> searchResults = [];

  bool loading = false;
  bool searching = false;
  String? errorMessage;

  Future<void> load() async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        friendsService.listFriends(),
        friendsService.listRequests(),
      ]);
      friends = results[0] as List<Friend>;
      final requests = results[1] as FriendRequests;
      incoming = requests.incoming;
      outgoing = requests.outgoing;
    } catch (err) {
      errorMessage = err.toString().replaceFirst('ApiException: ', '');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      searchResults = [];
      notifyListeners();
      return;
    }
    searching = true;
    notifyListeners();
    try {
      searchResults = await friendsService.search(query.trim());
    } catch (err) {
      errorMessage = err.toString().replaceFirst('ApiException: ', '');
    } finally {
      searching = false;
      notifyListeners();
    }
  }

  Future<void> sendRequest(String username) async {
    try {
      await friendsService.sendRequest(username);
      await load();
    } catch (err) {
      errorMessage = err.toString().replaceFirst('ApiException: ', '');
      notifyListeners();
    }
  }

  Future<void> accept(int requestId) async {
    try {
      await friendsService.accept(requestId);
      await load();
    } catch (err) {
      errorMessage = err.toString().replaceFirst('ApiException: ', '');
      notifyListeners();
    }
  }

  Future<void> cancelOrDecline(int requestId) async {
    try {
      await friendsService.cancelOrDecline(requestId);
      await load();
    } catch (err) {
      errorMessage = err.toString().replaceFirst('ApiException: ', '');
      notifyListeners();
    }
  }
}
