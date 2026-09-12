import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/alert_provider.dart';
import '../state/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_upload_panel.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  Future<void> _logout(BuildContext context) async {
    context.read<AlertProvider>().reset();
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
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
                  user?.email ?? '',
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
