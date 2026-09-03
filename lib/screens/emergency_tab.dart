import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/alert_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/alert_status_card.dart';
import '../widgets/sos_button.dart';

class EmergencyTab extends StatelessWidget {
  const EmergencyTab({super.key});

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();
    final current = alertProvider.current;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: current != null && current.isActive
            ? AlertStatusCard(alert: current)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SosButton(
                    busy: alertProvider.triggering,
                    onConfirmed: () => context.read<AlertProvider>().triggerAlert(),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Maintenez le bouton',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "En cas de danger, maintenez appuye pour declencher une alerte.\n"
                    'Votre position sera envoyee automatiquement a tous les repondants inscrits.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                  ),
                  if (alertProvider.errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.brand500.withValues(alpha: 0.1),
                        border: Border.all(color: AppColors.brand500.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        alertProvider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.brand400, fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
