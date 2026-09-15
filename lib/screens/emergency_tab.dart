import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alert.dart';
import '../state/alert_provider.dart';
import '../state/friend_alerts_provider.dart';
import '../theme/app_theme.dart';
import '../utils/time.dart';
import '../widgets/alert_status_card.dart';
import '../widgets/sos_button.dart';

class EmergencyTab extends StatelessWidget {
  const EmergencyTab({super.key});

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();
    final friendAlerts = context.watch<FriendAlertsProvider>().active;
    final current = alertProvider.current;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            for (final alert in friendAlerts) _FriendAlertBanner(alert: alert),
            current != null && current.isActive
                ? AlertStatusCard(alert: current)
                : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Bienvenue dans l'application qui vous permet de solliciter "
                        "de l'aide d'urgence en cas de danger immédiat :",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _Step(
                        number: '1',
                        text: 'Appuyer secrètement sur le bouton',
                      ),
                      _Step(
                        number: '2',
                        text:
                            "L'alerte est envoyée avec votre localisation exacte",
                      ),
                      _Step(
                        number: '3',
                        text: 'Un drone est envoyé à votre rescousse',
                      ),
                      _Step(
                        number: '4',
                        text:
                            'Attendez sur place et ne faites rien pour vous mettre '
                            'davantage en danger',
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  SosButton(
                    busy: alertProvider.triggering,
                    onConfirmed: () =>
                        context.read<AlertProvider>().triggerAlert(),
                  ),
                  if (alertProvider.errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.brand500.withValues(alpha: 0.1),
                        border: Border.all(
                          color: AppColors.brand500.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        alertProvider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.brand400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _FriendAlertBanner extends StatelessWidget {
  final EmergencyAlert alert;
  const _FriendAlertBanner({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.brand500.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.brand500.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: AppColors.brand400, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${alert.victimName} a declenche une alerte',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.brand400,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${alert.locationName ?? "${alert.latitude?.toStringAsFixed(4)}, ${alert.longitude?.toStringAsFixed(4)}"} - ${timeAgo(alert.createdAt)}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;
  final bool isLast;

  const _Step({required this.number, required this.text, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brand500.withValues(alpha: 0.15),
              border: Border.all(
                color: AppColors.brand500.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.brand400,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
