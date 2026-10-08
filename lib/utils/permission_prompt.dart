import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Demande les autorisations utiles a une alerte (localisation, micro,
/// camera). Si l'une d'elles est refusee, propose d'ouvrir les reglages de
/// l'application : apres un premier refus Android/iOS ne redemandent plus,
/// l'utilisateur doit l'activer manuellement.
Future<void> ensureEmergencyPermissions(BuildContext context) async {
  final wanted = {
    Permission.locationWhenInUse: 'la localisation',
    Permission.microphone: 'le micro',
    Permission.camera: 'la camera',
  };

  final denied = <String>[];
  for (final entry in wanted.entries) {
    var status = await entry.key.status;
    if (!status.isGranted) status = await entry.key.request();
    if (!status.isGranted && !status.isLimited) denied.add(entry.value);
  }

  if (denied.isEmpty || !context.mounted) return;

  final openSettings = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Autorisation requise'),
      content: Text(
        "Pour que les secours puissent vous localiser, vous entendre et vous "
        "voir, activez ${denied.join(', ')} dans les parametres de "
        "l'application.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Plus tard'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Ouvrir les parametres'),
        ),
      ],
    ),
  );

  if (openSettings == true) await openAppSettings();
}
