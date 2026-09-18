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

  /// Retourne un message d'erreur en cas d'echec (null si la demande est
  /// bien partie) : l'appelant s'en sert pour afficher un modal de resultat.
  Future<String?> sendRequest(String username) async {
    try {
      await friendsService.sendRequest(username);
      // Ce contact ne doit plus apparaitre comme "a ajouter" : une relation
      // existe desormais avec lui (voir aussi le filtre cote backend qui
      // l'exclura des prochaines recherches).
      searchResults =
          searchResults.where((p) => p.username != username).toList();
      await load();
      return null;
    } catch (err) {
      final message = err.toString().replaceFirst('ApiException: ', '');
      errorMessage = message;
      notifyListeners();
      return message;
    }
  }

  /// Ces trois methodes retournent, comme sendRequest, un message d'erreur
  /// en cas d'echec (null si l'action a reussi) : l'appelant s'en sert pour
  /// afficher un modal de resultat au lieu de compter sur le seul bandeau
  /// errorMessage, facile a manquer.
  Future<String?> accept(int requestId) async {
    try {
      await friendsService.accept(requestId);
      await load();
      return null;
    } catch (err) {
      final message = err.toString().replaceFirst('ApiException: ', '');
      errorMessage = message;
      notifyListeners();
      return message;
    }
  }

  Future<String?> cancelOrDecline(int requestId) async {
    try {
      await friendsService.cancelOrDecline(requestId);
      await load();
      return null;
    } catch (err) {
      final message = err.toString().replaceFirst('ApiException: ', '');
      errorMessage = message;
      notifyListeners();
      return message;
    }
  }

  Future<String?> removeFriend(Friend friend) async {
    final friendshipId = friend.friendshipId;
    if (friendshipId == null) return 'Impossible de retirer cet ami.';
    try {
      await friendsService.removeFriend(friendshipId);
      await load();
      return null;
    } catch (err) {
      final message = err.toString().replaceFirst('ApiException: ', '');
      errorMessage = message;
      notifyListeners();
      return message;
    }
  }
}
