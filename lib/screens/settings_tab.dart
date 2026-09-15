import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/alert_provider.dart';
import '../state/auth_provider.dart';
import '../state/friend_alerts_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_upload_panel.dart';
import 'friends_screen.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  Future<void> _logout(BuildContext context) async {
    context.read<AlertProvider>().reset();
    context.read<FriendAlertsProvider>().reset();
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

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
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.people_outline_rounded),
            title: const Text('Amis et famille'),
            subtitle: const Text(
              'Ajouter des proches, gerer les demandes',
              style: TextStyle(fontSize: 12.5),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FriendsScreen()),
            ),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: user?.shareLocationWithFriends ?? false,
            onChanged: (value) => auth.updateLocationSharing(value),
            title: const Text('Partager ma position avec mes amis'),
            subtitle: const Text(
              'En cas de declenchement du SOS, vos amis acceptes voient en '
              'direct que vous avez un probleme et ou vous vous trouvez.',
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
