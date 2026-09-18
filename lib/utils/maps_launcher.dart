import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

/// Ouvre Google Maps (app installee ou navigateur) sur une position donnee,
/// ou lance directement l'itineraire selon [directions]. Utilise par l'onglet
/// Alertes et par la position en direct des amis.
Future<void> openInMaps(
  BuildContext context, {
  required double latitude,
  required double longitude,
  bool directions = false,
}) async {
  final uri = directions
      ? Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
        )
      : Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');

  bool launched = false;
  try {
    launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    launched = false;
  }
  if (!launched && context.mounted) {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        icon: const Icon(Icons.error_rounded, color: AppColors.brand500, size: 40),
        title: const Text('Impossible d\'ouvrir Maps'),
        content: const Text(
          "Aucune application de cartes n'est disponible sur cet appareil.",
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
