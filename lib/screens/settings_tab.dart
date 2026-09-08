import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../config.dart';
import '../state/alert_provider.dart';
import '../state/auth_provider.dart';
import '../theme/app_theme.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  Uint8List? _pendingBytes;
  String? _pendingFilename;
  String? _pendingMimeType;
  bool _busy = false;
  String? _error;

  // L'appareil photo via image_picker plante (StateError) sur desktop
  // (Windows/macOS/Linux) sans configuration additionnelle : on ne propose
  // ce bouton que la ou il fonctionne reellement.
  bool get _supportsCamera =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  // image_picker ne garantit pas toujours un XFile.mimeType exploitable
  // (souvent nul sur mobile) : on retombe sur l'extension du fichier, et a
  // defaut sur jpeg (format quasi systematique d'une capture appareil photo).
  String _resolveMimeType(XFile file) {
    final reported = file.mimeType;
    if (reported != null && reported.startsWith('image/')) return reported;
    final ext = file.name.toLowerCase().split('.').last;
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  Future<void> _pick(ImageSource source) async {
    setState(() => _error = null);
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pendingBytes = bytes;
        _pendingFilename = picked.name;
        _pendingMimeType = _resolveMimeType(picked);
      });
    } catch (err) {
      if (!mounted) return;
      setState(
        () => _error = source == ImageSource.camera
            ? "L'appareil photo n'est pas disponible sur cet appareil."
            : "Impossible d'ouvrir la galerie.",
      );
    }
  }

  void _cancelPending() {
    setState(() {
      _pendingBytes = null;
      _pendingFilename = null;
      _pendingMimeType = null;
      _error = null;
    });
  }

  Future<void> _confirmUpload() async {
    final bytes = _pendingBytes;
    if (bytes == null) return;

    setState(() => _busy = true);
    try {
      await context.read<AuthProvider>().uploadAvatar(
        bytes,
        _pendingFilename ?? 'avatar.jpg',
        _pendingMimeType ?? 'image/jpeg',
      );
      if (!mounted) return;
      setState(() {
        _pendingBytes = null;
        _pendingFilename = null;
        _pendingMimeType = null;
      });
    } catch (err) {
      if (!mounted) return;
      setState(
        () => _error = err.toString().replaceFirst('ApiException: ', ''),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().removeAvatar();
    } catch (err) {
      if (!mounted) return;
      setState(
        () => _error = err.toString().replaceFirst('ApiException: ', ''),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    context.read<AlertProvider>().reset();
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final avatarUrl = AppConfig.resolveAvatarUrl(user?.avatarUrl);
    final showPreview = _pendingBytes != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brand500.withValues(alpha: 0.15),
                    border: Border.all(
                      color: AppColors.brand500.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: showPreview
                      ? ClipOval(
                          child: Image.memory(
                            _pendingBytes!,
                            fit: BoxFit.cover,
                            width: 92,
                            height: 92,
                          ),
                        )
                      : (avatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  avatarUrl,
                                  fit: BoxFit.cover,
                                  width: 92,
                                  height: 92,
                                ),
                              )
                            : Center(
                                child: Text(
                                  user?.fullName.isNotEmpty == true
                                      ? user!.fullName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.brand400,
                                  ),
                                ),
                              )),
                ),
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
          const SizedBox(height: 32),
          const Text(
            'PHOTO DE PROFIL',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          if (_error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.brand500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.brand500.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.brand400, fontSize: 13),
              ),
            ),
          ],

          if (showPreview) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                _pendingBytes!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Apercu - confirmez pour l\'envoyer, ou annulez pour la remplacer.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _cancelPending,
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy ? null : _confirmUpload,
                    child: Text(_busy ? 'Envoi...' : 'Confirmer et envoyer'),
                  ),
                ),
              ],
            ),
          ] else ...[
            if (_supportsCamera) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_rounded, size: 18),
                  label: const Text('Prendre une photo'),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded, size: 18),
                label: const Text('Choisir depuis la galerie'),
              ),
            ),
            if (avatarUrl != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _busy ? null : _remove,
                  child: const Text('Retirer la photo'),
                ),
              ),
            ],
            const SizedBox(height: 10),
            const Text(
              'JPEG, PNG ou WEBP, 5 Mo max.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],

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
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Deconnexion'),
            ),
          ),
        ],
      ),
    );
  }
}
