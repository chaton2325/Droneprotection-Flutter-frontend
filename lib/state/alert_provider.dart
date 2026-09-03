import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config.dart';
import '../models/alert.dart';
import '../services/alert_service.dart';
import '../services/location_service.dart';
import '../services/socket_service.dart';

class AlertProvider extends ChangeNotifier {
  final AlertService alertService;
  final LocationService locationService;
  final SocketService socketService;

  AlertProvider({
    required this.alertService,
    required this.locationService,
    required this.socketService,
  });

  EmergencyAlert? current;
  List<EmergencyAlert> history = [];

  bool triggering = false;
  bool loadingHistory = false;
  String? errorMessage;

  Timer? _locationTimer;
  io.Socket? _boundSocket;

  /// Attache les listeners socket une seule fois par instance de connexion
  /// (une nouvelle instance est creee a chaque login).
  void attachSocket() {
    final socket = socketService.socket;
    if (socket == null || identical(socket, _boundSocket)) return;
    _boundSocket = socket;

    socket.on('alert:accepted', (data) => _onRemoteUpdate(data));
    socket.on('alert:resolved', (data) => _onRemoteUpdate(data));
    socket.on('alert:cancelled', (data) => _onRemoteUpdate(data));
    socket.on('alert:location', (data) => _onRemoteUpdate(data));
  }

  void _onRemoteUpdate(dynamic data) {
    if (data is! Map) return;
    final alert = EmergencyAlert.fromJson(Map<String, dynamic>.from(data));
    if (current == null || alert.id != current!.id) return;

    current = alert;
    if (!alert.isActive) {
      _stopLocationLoop();
    }
    notifyListeners();
  }

  Future<bool> triggerAlert({String? message}) async {
    errorMessage = null;
    triggering = true;
    notifyListeners();

    try {
      final position = await locationService.getCurrentPosition();
      final alert = await alertService.create(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        message: message,
      );
      current = alert;
      _startLocationLoop();
      return true;
    } catch (err) {
      errorMessage = err.toString().replaceFirst('ApiException: ', '');
      return false;
    } finally {
      triggering = false;
      notifyListeners();
    }
  }

  void _startLocationLoop() {
    _stopLocationLoop();
    _locationTimer = Timer.periodic(AppConfig.locationUpdateInterval, (_) async {
      final alert = current;
      if (alert == null || !alert.isActive) {
        _stopLocationLoop();
        return;
      }
      try {
        final position = await locationService.getCurrentPosition();
        final updated = await alertService.sendLocation(
          alert.id,
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
        );
        current = updated;
        notifyListeners();
      } catch (_) {
        // Une erreur ponctuelle de localisation ne doit pas interrompre le flux.
      }
    });
  }

  void _stopLocationLoop() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> cancelCurrent() async {
    final alert = current;
    if (alert == null) return;
    current = await alertService.cancel(alert.id);
    _stopLocationLoop();
    notifyListeners();
  }

  Future<void> resolveCurrent() async {
    final alert = current;
    if (alert == null) return;
    current = await alertService.resolve(alert.id);
    _stopLocationLoop();
    notifyListeners();
  }

  void clearCurrent() {
    current = null;
    _stopLocationLoop();
    notifyListeners();
  }

  Future<void> loadHistory() async {
    loadingHistory = true;
    notifyListeners();
    try {
      history = await alertService.listMine();
    } catch (_) {
      // On garde l'historique precedent en cas d'echec reseau ponctuel.
    } finally {
      loadingHistory = false;
      notifyListeners();
    }
  }

  void reset() {
    _stopLocationLoop();
    _boundSocket = null;
    current = null;
    history = [];
  }

  @override
  void dispose() {
    _stopLocationLoop();
    super.dispose();
  }
}
