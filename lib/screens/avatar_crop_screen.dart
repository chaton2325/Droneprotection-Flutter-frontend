import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Ecran plein cadre pour cadrer une photo de profil avant envoi : guide
/// circulaire (rendu final toujours carre, l'avatar etant affiche dans un
/// cercle cote UI) avec pincer-zoomer / deplacer.
class AvatarCropScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const AvatarCropScreen({super.key, required this.imageBytes});

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  final _controller = CropController();
  bool _ready = false;
  bool _cropping = false;

  void _submit() {
    if (!_ready || _cropping) return;
    setState(() => _cropping = true);
    _controller.crop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        title: const Text('Cadrer la photo'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _cropping ? null : () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _ready && !_cropping ? _submit : null,
            child: _cropping
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.brand400,
                    ),
                  )
                : const Text(
                    'Valider',
                    style: TextStyle(
                      color: AppColors.brand400,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Crop(
              controller: _controller,
              image: widget.imageBytes,
              aspectRatio: 1,
              withCircleUi: true,
              baseColor: Colors.black,
              maskColor: Colors.black.withValues(alpha: 0.65),
              progressIndicator: const Center(
                child: CircularProgressIndicator(color: AppColors.brand400),
              ),
              cornerDotBuilder: (size, edgeAlignment) => const SizedBox.shrink(),
              onStatusChanged: (status) {
                final ready = status == CropStatus.ready;
                if (ready != _ready) setState(() => _ready = ready);
              },
              onCropped: (result) {
                if (!mounted) return;
                switch (result) {
                  case CropSuccess(:final croppedImage):
                    Navigator.of(context).pop(croppedImage);
                  case CropFailure():
                    setState(() => _cropping = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Impossible de cadrer cette photo.'),
                      ),
                    );
                }
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            child: Text(
              'Deplacez et zoomez pour cadrer votre visage dans le cercle.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
