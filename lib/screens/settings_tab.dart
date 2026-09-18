import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/alert_provider.dart';
import '../state/auth_provider.dart';
import '../state/friend_alerts_provider.dart';
import '../state/friend_live_location_provider.dart';
import '../state/live_location_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_upload_panel.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  Future<void> _logout(BuildContext context) async {
    context.read<AlertProvider>().reset();
    context.read<FriendAlertsProvider>().reset();
    context.read<LiveLocationProvider>().reset();
    context.read<FriendLiveLocationProvider>().reset();
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final liveLocation = context.watch<LiveLocationProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AvatarUploadPanel(
            subtitleBuilder: (context, user) => Column(
              children: [
                const SizedBox(height: 14),
                Text(
                  user?.fullName ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user != null ? '@${user.username}' : '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          const Divider(color: AppColors.surface2),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: liveLocation.enabled,
            onChanged: (value) => liveLocation.setEnabled(value),
            title: const Text('Partager ma position en direct'),
            subtitle: const Text(
              "Tant que l'application est ouverte au premier plan, le pilote "
              "de drone peut voir ou vous vous trouvez et ouvrir l'itineraire "
              "avec Maps. S'arrete automatiquement des que vous fermez "
              "l'application ou la mettez en arriere-plan.",
              style: TextStyle(fontSize: 12.5),
            ),
          ),
          if (liveLocation.errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brand500.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.brand500.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                liveLocation.errorMessage!,
                style: const TextStyle(color: AppColors.brand400, fontSize: 12.5),
              ),
            ),
          ],
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: user?.shareLocationWithFriends ?? false,
            onChanged: (value) => auth.updateLocationSharing(value),
            title: const Text('Partager ma position avec mes amis'),
            subtitle: const Text(
              'En cas de declenchement du SOS, ou si la position en direct '
              'ci-dessus est active, vos amis acceptes voient ou vous vous '
              'trouvez et peuvent ouvrir l\'itineraire.',
              style: TextStyle(fontSize: 12.5),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.surface2),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brand400,
                side: const BorderSide(color: AppColors.brand500),
              ),
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Deconnexion'),
            ),
          ),
        ],
      ),
    );
  }
}
