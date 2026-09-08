import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../models/alert.dart';
import '../state/alert_provider.dart';
import '../theme/app_theme.dart';
import 'status_pill.dart';

class AlertStatusCard extends StatelessWidget {
  final EmergencyAlert alert;
  const AlertStatusCard({super.key, required this.alert});

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
        if (alert.responderPhone != null && !isPending) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.call_rounded, size: 18),
            label: Text(alert.responderPhone!),
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
