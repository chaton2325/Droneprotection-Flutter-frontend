import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Demande les autorisations utiles a une alerte (localisation, micro,
/// camera). En cas de refus on n'affiche aucune redirection vers les reglages
/// (guideline Apple 5.1.1(iv)) : l'ecran d'autorisations obligatoires
/// (PermissionGate) prend le relais et laisse l'utilisateur decider.
Future<void> ensureEmergencyPermissions(BuildContext context) async {
  for (final p in [
    Permission.locationWhenInUse,
    Permission.microphone,
    Permission.camera,
  ]) {
    final status = await p.status;
    if (!status.isGranted) await p.request();
  }
}
