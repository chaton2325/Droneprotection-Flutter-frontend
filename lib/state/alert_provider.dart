import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config.dart';
import '../models/alert.dart';
import '../services/alert_service.dart';
import '../services/audio_stream_service.dart';
import '../services/location_service.dart';
import '../services/socket_service.dart';
import '../services/video_stream_service.dart';

class AlertProvider extends ChangeNotifier {
  final AlertService alertService;
  final LocationService locationService;
  final SocketService socketService;
  final AudioStreamService audioStreamService;
  final VideoStreamService videoStreamService;

  AlertProvider({
    required this.alertService,
    required this.locationService,
    required this.socketService,
    required this.audioStreamService,
    required this.videoStreamService,
  });

  EmergencyAlert? current;
  List<EmergencyAlert> history = [];

  bool triggering = false;
  bool loadingHistory = false;
  String? errorMessage;

  // Micro ouvert automatiquement des qu'un repondant accepte l'alerte (voir
  // AudioStreamService) : indique si le flux est actif pour l'UI, et une
  // erreur non bloquante (ex: permission micro refusee).
  bool micActive = false;
  String? micErrorMessage;

  // Camera(s) ouvertes automatiquement en meme temps que le micro (voir
  // VideoStreamService) : videoDualCamera indique si avant+arriere ont pu
  // etre ouvertes simultanement, ou si on est replie sur l'arriere seule.
  bool videoActive = false;
  bool videoDualCamera = false;
  String? videoErrorMessage;

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

    final wasAccepted = current!.status == 'accepted';
    current = alert;

    if (!wasAccepted && alert.status == 'accepted') {
      _startAudioStream(alert.id);
      _startVideoStream(alert.id);
    }
    if (!alert.isActive) {
      _stopLocationLoop();
      _stopAudioStream();
      _stopVideoStream();
    }
    notifyListeners();
  }

  Future<void> _startAudioStream(int alertId) async {
    micErrorMessage = null;
    try {
      final started = await audioStreamService.start(alertId);
      micActive = started;
      if (!started) {
        micErrorMessage =
            "Micro indisponible (permission refusee ?) - le repondant n'entendra pas l'audio.";
      }
    } catch (_) {
      micActive = false;
      micErrorMessage = "Impossible d'ouvrir le micro.";
    }
    notifyListeners();
  }

  Future<void> _stopAudioStream() async {
    if (!micActive) return;
    await audioStreamService.stop();
    micActive = false;
    notifyListeners();
  }

  Future<void> _startVideoStream(int alertId) async {
    videoErrorMessage = null;
    try {
      final started = await videoStreamService.start(alertId);
      videoActive = started;
      videoDualCamera = started && videoStreamService.isDualCamera;
      if (!started) {
        videoErrorMessage =
            "Camera indisponible (permission refusee ?) - le repondant ne verra pas d'image.";
      }
    } catch (_) {
      videoActive = false;
      videoDualCamera = false;
      videoErrorMessage = "Impossible d'ouvrir la camera.";
    }
    notifyListeners();
  }

  Future<void> _stopVideoStream() async {
    if (!videoActive) return;
    await videoStreamService.stop();
    videoActive = false;
    videoDualCamera = false;
    notifyListeners();
  }

  /// Recupere l'alerte active de l'utilisateur depuis le backend, si elle existe.
  ///
  /// Necessaire car [current] ne vit qu'en memoire : si le telephone s'eteint
  /// (batterie, redemarrage...) pendant qu'une alerte est en cours, l'app perd
  /// cet etat au relancement et affiche a nouveau le bouton SOS normal alors
  /// que l'alerte est toujours active cote backend et suivie par les
  /// repondants. On la restaure ici et on reprend l'envoi de position.
  Future<void> restoreActiveAlert() async {
    if (current != null) return;
    try {
      final mine = await alertService.listMine();
      final active = mine.where((a) => a.isActive);
      if (active.isEmpty) return;
      current =
          active.first; // listMine() est trie created_at DESC cote backend.
      _startLocationLoop();
      if (current!.status == 'accepted') {
        _startAudioStream(current!.id);
        _startVideoStream(current!.id);
      }
      notifyListeners();
    } catch (_) {
      // Pas de reseau au demarrage : on retentera au prochain appel (ex: reouverture de l'onglet).
    }
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
      _resolveLocationName(alert.id, position.latitude, position.longitude);
      return true;
    } catch (err) {
      errorMessage = err.toString().replaceFirst('ApiException: ', '');
      return false;
    } finally {
      triggering = false;
      notifyListeners();
    }
  }

  /// Ne bloque jamais le declenchement de l'alerte (latence critique) : le
  /// nom de lieu est resolu en arriere-plan et remonte des qu'il est pret,
  /// via le meme endpoint que les mises a jour de position.
  Future<void> _resolveLocationName(int alertId, double lat, double lng) async {
    final name = await locationService.reverseGeocode(lat, lng);
    if (name == null) return;
    final alert = current;
    if (alert == null || alert.id != alertId) return;
    try {
      current = await alertService.sendLocation(
        alertId,
        latitude: lat,
        longitude: lng,
        accuracy: alert.accuracy,
        locationName: name,
      );
      notifyListeners();
    } catch (_) {
      // Le prochain tick de la boucle de position reessaiera sans le nom si
      // celui-ci echoue ; ce n'est pas critique.
    }
  }

  void _startLocationLoop() {
    _stopLocationLoop();
    _locationTimer = Timer.periodic(AppConfig.locationUpdateInterval, (
      _,
    ) async {
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
    _stopAudioStream();
    _stopVideoStream();
    notifyListeners();
  }

  Future<void> resolveCurrent() async {
    final alert = current;
    if (alert == null) return;
    current = await alertService.resolve(alert.id);
    _stopLocationLoop();
    _stopAudioStream();
    _stopVideoStream();
    notifyListeners();
  }

  void clearCurrent() {
    current = null;
    _stopLocationLoop();
    _stopAudioStream();
    _stopVideoStream();
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
    _stopAudioStream();
    _stopVideoStream();
    _boundSocket = null;
    current = null;
    history = [];
  }

  @override
  void dispose() {
    _stopLocationLoop();
    audioStreamService.dispose();
    videoStreamService.dispose();
    super.dispose();
  }
}
