import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';

/// Position en direct de l'utilisateur courant, independante des alertes :
/// tant que [enabled] est vrai ET que l'app est au premier plan, envoie la
/// position au serveur a intervalle regulier. Voir RootShell pour le
/// rattachement au cycle de vie de l'app (onForeground/onBackground) - c'est
/// ce qui fait que le partage s'arrete tout seul en arriere-plan, sans que
/// l'utilisateur ait besoin de retoucher le reglage.
class LiveLocationProvider extends ChangeNotifier {
  final AuthService authService;
  final LocationService locationService;

  LiveLocationProvider({required this.authService, required this.locationService});

  static const _pushInterval = Duration(seconds: 20);

  bool enabled = false;
  bool _foreground = true;
  bool sending = false;
  String? errorMessage;
  Timer? _timer;

  /// A appeler quand on connait l'etat serveur (apres login/restauration de
  /// session) pour reprendre l'envoi si c'etait deja actif.
  void syncFromUser(bool liveLocationSharing) {
    enabled = liveLocationSharing;
    _applyState();
  }

  Future<bool> setEnabled(bool value) async {
    if (value) {
      // Verifie la permission/le service avant d'activer cote serveur, pour
      // ne pas se retrouver avec le partage marque actif alors qu'aucune
      // position ne pourra jamais etre envoyee.
      try {
        await locationService.getCurrentPosition();
      } catch (err) {
        errorMessage = err.toString();
        notifyListeners();
        return false;
      }
    }
    try {
      final user = await authService.updateLiveLocationSharing(value);
      enabled = user.liveLocationSharing;
      errorMessage = null;
      _applyState();
      notifyListeners();
      return true;
    } catch (err) {
      errorMessage = err.toString().replaceFirst('ApiException: ', '');
      notifyListeners();
      return false;
    }
  }

  void onForeground() {
    _foreground = true;
    _applyState();
  }

  void onBackground() {
    _foreground = false;
    _applyState();
  }

  void _applyState() {
    if (enabled && _foreground) {
      _start();
    } else {
      _stop();
    }
  }

  void _start() {
    if (_timer != null) return;
    _pushOnce();
    _timer = Timer.periodic(_pushInterval, (_) => _pushOnce());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _pushOnce() async {
    if (sending) return;
    sending = true;
    try {
      final position = await locationService.getCurrentPosition();
      final active = await authService.pushLiveLocation(
        position.latitude,
        position.longitude,
      );
      if (!active) {
        // Le serveur ne pense plus le partage actif (ex: desactive depuis un
        // autre appareil) : on s'arrete localement plutot que de continuer a
        // envoyer des positions dans le vide.
        enabled = false;
        _stop();
        notifyListeners();
      }
    } catch (_) {
      // Best-effort : un echec ponctuel (GPS, reseau) ne doit pas interrompre
      // le cycle, on reessaiera au prochain tick.
    } finally {
      sending = false;
    }
  }

  void reset() {
    enabled = false;
    _stop();
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }
}
