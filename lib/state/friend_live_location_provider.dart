import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/live_location.dart';
import '../services/socket_service.dart';

/// Positions en direct des amis ayant partage leur position (reglage
/// "Partager ma position en direct" + "avec mes amis"). Lecture seule,
/// alimentee uniquement par socket : le serveur ne pousse ces evenements
/// qu'aux amis autorises (voir broadcastLiveLocation cote backend), pas de
/// filtrage supplementaire necessaire ici.
class FriendLiveLocationProvider extends ChangeNotifier {
  final SocketService socketService;
  FriendLiveLocationProvider({required this.socketService});

  final Map<int, LiveLocationUpdate> _byFriendId = {};
  io.Socket? _boundSocket;

  LiveLocationUpdate? forFriend(int id) => _byFriendId[id];

  void attachSocket() {
    final socket = socketService.socket;
    if (socket == null || identical(socket, _boundSocket)) return;
    _boundSocket = socket;
    socket.on('friend:live-location', _onUpdate);
    socket.on('friend:live-location-stopped', _onStopped);
  }

  void _onUpdate(dynamic data) {
    if (data is! Map) return;
    final update = LiveLocationUpdate.fromJson(Map<String, dynamic>.from(data));
    _byFriendId[update.id] = update;
    notifyListeners();
  }

  void _onStopped(dynamic data) {
    if (data is! Map) return;
    final id = data['id'];
    if (id is! int) return;
    _byFriendId.remove(id);
    notifyListeners();
  }

  void reset() {
    _byFriendId.clear();
    _boundSocket = null;
  }
}
