import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../models/alert.dart';
import '../state/friend_alerts_provider.dart';
import '../theme/app_theme.dart';
import '../utils/maps_launcher.dart';
import '../utils/time.dart';
import '../widgets/status_pill.dart';

/// Onglet "Alertes" de la barre de navigation principale : alertes actives
/// declenchees par des amis ayant active le partage de position (voir
/// SettingsTab). Purement informatif - la liste se met a jour toute seule
/// via FriendAlertsProvider (socket `friend:alert` / `friend:alert-update`)
/// et un ami disparait de cette liste des que son alerte est resolue ou
/// annulee (EmergencyAlert.isActive redevient false).
class FriendAlertsTab extends StatelessWidget {
  const FriendAlertsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final alerts = context.watch<FriendAlertsProvider>().active;

    if (alerts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shield_moon_outlined,
                color: AppColors.textSecondary,
                size: 40,
              ),
              const SizedBox(height: 12),
              const Text(
                "Aucune alerte de vos amis pour le moment.",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                "Vous serez prevenu ici des qu'un proche ayant partage sa "
                "position declenche le SOS.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return _FriendAlertCard(
          alert: alert,
          onOpenMaps: () => openInMaps(
            context,
            latitude: alert.latitude!,
            longitude: alert.longitude!,
          ),
          onDirections: () => openInMaps(
            context,
            latitude: alert.latitude!,
            longitude: alert.longitude!,
            directions: true,
          ),
        );
      },
    );
  }
}

class _FriendAlertCard extends StatelessWidget {
  final EmergencyAlert alert;
  final VoidCallback onOpenMaps;
  final VoidCallback onDirections;

  const _FriendAlertCard({
    required this.alert,
    required this.onOpenMaps,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = AppConfig.resolveAvatarUrl(alert.victimAvatarUrl);
    final hasLocation = alert.latitude != null && alert.longitude != null;
    final locationLabel = alert.locationName ??
        (hasLocation
            ? '${alert.latitude!.toStringAsFixed(4)}, ${alert.longitude!.toStringAsFixed(4)}'
            : 'Position pas encore recue');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brand500.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.brand500.withValues(alpha: 0.15),
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null
                    ? const Icon(Icons.person_rounded, color: AppColors.brand400)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${alert.victimName} a declenche une alerte',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.brand400,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        StatusPill(status: alert.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locationLabel,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                    Text(
                      timeAgo(alert.createdAt),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasLocation ? onOpenMaps : null,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Ouvrir dans Maps'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand500,
                  ),
                  onPressed: hasLocation ? onDirections : null,
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: const Text('Itineraire'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
