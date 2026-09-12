import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/alert_provider.dart';
import '../state/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_upload_panel.dart';

/// Etape obligatoire imposee aux comptes pouvant declencher une alerte
/// (victime / les deux) tant qu'ils n'ont pas de photo de profil : les
/// secours doivent pouvoir identifier visuellement la personne sur le
/// terrain. L'ecran disparait automatiquement des que l'envoi reussit,
/// puisque AuthGate se reconstruit sur le changement de `user.avatarUrl`.
class RequireAvatarScreen extends StatelessWidget {
  const RequireAvatarScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    context.read<AlertProvider>().reset();
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Derniere etape'),
        actions: [
          TextButton(
            onPressed: () => _logout(context),
            child: const Text('Deconnexion'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accent500.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_rounded,
                      color: AppColors.accent400,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Ajoutez votre photo de profil pour continuer. Mettez "
                        "votre vraie photo, visage bien visible : en cas "
                        "d'alerte, elle permet aux secours de vous "
                        "reconnaitre rapidement sur le terrain.",
                        style: TextStyle(
                          color: AppColors.textPrimary.withValues(alpha: 0.9),
                          fontSize: 13.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const AvatarUploadPanel(
                allowRemove: false,
                showSectionLabel: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
