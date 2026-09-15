import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/alert.dart';
import '../services/socket_service.dart';

/// Alertes declenchees par des amis ayant active le partage de position
/// (voir AuthProvider.updateLocationSharing). Lecture seule : contrairement
/// a AlertProvider, il n'y a ici aucune action possible (pas d'acceptation/
/// resolution), juste de quoi savoir qu'un proche a un probleme et ou.
class FriendAlertsProvider extends ChangeNotifier {
  final SocketService socketService;
  FriendAlertsProvider({required this.socketService});

  final Map<int, EmergencyAlert> _byId = {};
  io.Socket? _boundSocket;

  List<EmergencyAlert> get active =>
      _byId.values.where((a) => a.isActive).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  void attachSocket() {
    final socket = socketService.socket;
    if (socket == null || identical(socket, _boundSocket)) return;
    _boundSocket = socket;

    socket.on('friend:alert', _onUpdate);
    socket.on('friend:alert-update', _onUpdate);
  }

  void _onUpdate(dynamic data) {
    if (data is! Map) return;
    final alert = EmergencyAlert.fromJson(Map<String, dynamic>.from(data));
    if (alert.isActive) {
      _byId[alert.id] = alert;
    } else {
      _byId.remove(alert.id);
    }
    notifyListeners();
  }

  void reset() {
    _byId.clear();
    _boundSocket = null;
  }
}
