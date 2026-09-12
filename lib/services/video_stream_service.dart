import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'socket_service.dart';

/// Diffuse la ou les cameras de la victime au repondant assigne, en
/// parallele du micro ([AudioStreamService]) : capture une photo JPEG a
/// intervalle rapproche par camera disponible (pas de flux video encode -
/// Socket.IO + base64 ne s'y prete pas), envoyee au fil de l'eau.
///
/// Tente d'ouvrir avant + arriere simultanement : peu d'appareils Android le
/// permettent materiellement (une seule session Camera2 a la fois sur la
/// plupart des modeles), certains iPhone recents si. Si l'ouverture
/// simultanee echoue, repli sur la camera arriere seule (jamais l'avant
/// seule : c'est l'environnement autour de la victime qui importe le plus
/// pour les secours). `takePicture()` via ce plugin (Camera2 / AVFoundation
/// directs, pas l'app Camera du systeme) ne declenche pas de son
/// d'obturateur : la capture reste discrete.
///
/// Meme modele d'autorisation que l'audio : verifiee cote serveur a
/// l'ouverture (`alert:video-start`), seule la victime peut demarrer, seul
/// le repondant assigne recoit les images.
class VideoStreamService {
  static const Duration frameInterval = Duration(milliseconds: 700);

  final SocketService socketService;
  VideoStreamService(this.socketService);

  CameraController? _backController;
  CameraController? _frontController;
  Timer? _timer;
  bool _backBusy = false;
  bool _frontBusy = false;
  int? _currentAlertId;
  bool _active = false;
  bool _dualCamera = false;

  bool get isActive => _active;
  bool get isDualCamera => _dualCamera;

  // Le plugin `camera` ne supporte que Android / iOS / web : sur desktop on
  // se contente de ne rien diffuser (comme la camera d'image_picker ailleurs
  // dans l'app).
  bool get _supportsCamera =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  Future<bool> start(int alertId) async {
    if (_active) return true;
    if (!_supportsCamera) return false;
    if (socketService.socket == null) return false;

    final authorized = await _requestServerAuthorization(alertId);
    if (!authorized) return false;

    List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } catch (_) {
      return false;
    }

    final back = _findByDirection(cameras, CameraLensDirection.back);
    final front = _findByDirection(cameras, CameraLensDirection.front);
    if (back == null) return false;

    try {
      final controller = CameraController(
        back,
        ResolutionPreset.low,
        enableAudio: false,
      );
      await controller.initialize();
      _backController = controller;
    } catch (_) {
      _backController = null;
      return false;
    }

    _dualCamera = false;
    if (front != null) {
      try {
        final controller = CameraController(
          front,
          ResolutionPreset.low,
          enableAudio: false,
        );
        await controller.initialize();
        _frontController = controller;
        _dualCamera = true;
      } catch (_) {
        // Ouverture simultanee refusee par le materiel (cas courant sur
        // Android) : on continue avec la seule camera arriere.
        _frontController = null;
      }
    }

    _currentAlertId = alertId;
    _active = true;
    _timer = Timer.periodic(frameInterval, (_) => _captureTick());
    return true;
  }

  CameraDescription? _findByDirection(
    List<CameraDescription> cameras,
    CameraLensDirection direction,
  ) {
    for (final camera in cameras) {
      if (camera.lensDirection == direction) return camera;
    }
    return null;
  }

  Future<bool> _requestServerAuthorization(int alertId) {
    final completer = Completer<bool>();
    socketService.socket!.emitWithAck(
      'alert:video-start',
      alertId,
      ack: (dynamic response) {
        final ok = response is Map && response['ok'] == true;
        if (!completer.isCompleted) completer.complete(ok);
      },
    );
    return completer.future.timeout(
      const Duration(seconds: 6),
      onTimeout: () => false,
    );
  }

  void _captureTick() {
    if (!_active) return;
    if (!_backBusy) _captureAndSend('back', _backController);
    if (_frontController != null && !_frontBusy) {
      _captureAndSend('front', _frontController);
    }
  }

  Future<void> _captureAndSend(
    String slot,
    CameraController? controller,
  ) async {
    if (controller == null || !controller.value.isInitialized) return;
    if (slot == 'back') {
      _backBusy = true;
    } else {
      _frontBusy = true;
    }
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      if (_active && _currentAlertId != null) {
        socketService.emit('alert:video-chunk', {
          'alertId': _currentAlertId,
          'camera': slot,
          'data': base64Encode(bytes),
          'mimeType': 'image/jpeg',
        });
      }
    } catch (_) {
      // Une capture ratee ponctuelle (autofocus en cours, etc.) ne doit pas
      // interrompre le flux.
    } finally {
      if (slot == 'back') {
        _backBusy = false;
      } else {
        _frontBusy = false;
      }
    }
  }

  Future<void> stop() async {
    if (!_active) return;
    _timer?.cancel();
    _timer = null;

    final alertId = _currentAlertId;
    _active = false;
    _dualCamera = false;
    _currentAlertId = null;

    final back = _backController;
    final front = _frontController;
    _backController = null;
    _frontController = null;
    await back?.dispose();
    await front?.dispose();

    if (alertId != null) {
      socketService.emit('alert:video-stop', alertId);
    }
  }

  void dispose() {
    _timer?.cancel();
    _backController?.dispose();
    _frontController?.dispose();
  }
}
