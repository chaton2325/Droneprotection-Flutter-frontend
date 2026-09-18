import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../models/alert.dart';
import '../screens/chat_screen.dart';
import '../state/alert_provider.dart';
import '../theme/app_theme.dart';
import 'status_pill.dart';

class AlertStatusCard extends StatelessWidget {
  final EmergencyAlert alert;
  const AlertStatusCard({super.key, required this.alert});

  Future<void> _callResponder(BuildContext context, String phone) async {
    bool launched = false;
    try {
      launched = await launchUrl(Uri.parse('tel:$phone'));
    } catch (_) {
      launched = false;
    }
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible de lancer l'appel sur cet appareil.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = alert.status == 'pending';
    final responderAvatarUrl = AppConfig.resolveAvatarUrl(
      alert.responderAvatarUrl,
    );
    final alertProvider = context.watch<AlertProvider>();

    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isPending ? AppColors.brand500 : AppColors.warn500)
                .withValues(alpha: 0.15),
            border: Border.all(
              color: (isPending ? AppColors.brand500 : AppColors.warn500)
                  .withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: !isPending && responderAvatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    responderAvatarUrl,
                    width: 92,
                    height: 92,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(
                  isPending ? Icons.campaign_rounded : Icons.security_rounded,
                  color: isPending ? AppColors.brand400 : AppColors.warn400,
                  size: 40,
                ),
        ),
        const SizedBox(height: 20),
        Text(
          isPending ? 'Alerte envoyee' : 'Intervention en cours',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        StatusPill(status: alert.status),
        const SizedBox(height: 16),
        Text(
          isPending
              ? "Votre position est partagee en direct avec tous les repondants inscrits. Restez en ligne."
              : '${alert.responderName ?? "Un repondant"} a accepte votre alerte et se dirige vers vous.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
        if (alert.status == 'accepted') ...[
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (alert.responderPhone != null) ...[
                TextButton.icon(
                  onPressed: () => _callResponder(context, alert.responderPhone!),
                  icon: const Icon(Icons.call_rounded, size: 18),
                  label: Text(alert.responderPhone!),
                ),
                const SizedBox(width: 8),
              ],
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(alertId: alert.id),
                  ),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('Message'),
              ),
            ],
          ),
        ],
        if (alert.status == 'accepted') ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:
                  (alertProvider.micActive
                          ? AppColors.ok500
                          : AppColors.warn500)
                      .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color:
                    (alertProvider.micActive
                            ? AppColors.ok500
                            : AppColors.warn500)
                        .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  alertProvider.micActive
                      ? Icons.mic_rounded
                      : Icons.mic_off_rounded,
                  size: 14,
                  color: alertProvider.micActive
                      ? AppColors.ok400
                      : AppColors.warn400,
                ),
                const SizedBox(width: 6),
                Text(
                  alertProvider.micActive
                      ? 'Micro ouvert pour le repondant'
                      : (alertProvider.micErrorMessage ??
                            'Ouverture du micro...'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: alertProvider.micActive
                        ? AppColors.ok400
                        : AppColors.warn400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:
                  (alertProvider.videoActive
                          ? AppColors.ok500
                          : AppColors.warn500)
                      .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color:
                    (alertProvider.videoActive
                            ? AppColors.ok500
                            : AppColors.warn500)
                        .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  alertProvider.videoActive
                      ? Icons.videocam_rounded
                      : Icons.videocam_off_rounded,
                  size: 14,
                  color: alertProvider.videoActive
                      ? AppColors.ok400
                      : AppColors.warn400,
                ),
                const SizedBox(width: 6),
                Text(
                  alertProvider.videoActive
                      ? (alertProvider.videoDualCamera
                            ? 'Cameras avant + arriere ouvertes'
                            : 'Camera arriere ouverte pour le repondant')
                      : (alertProvider.videoErrorMessage ??
                            'Ouverture de la camera...'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: alertProvider.videoActive
                        ? AppColors.ok400
                        : AppColors.warn400,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.read<AlertProvider>().cancelCurrent(),
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ok500,
                ),
                onPressed: () => context.read<AlertProvider>().resolveCurrent(),
                child: const Text('Je suis en securite'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
