import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Visionneuse plein ecran (pincer-zoomer) pour une photo de profil, a
/// partir soit d'une URL reseau (avatar deja envoye) soit d'octets locaux
/// (apercu en attente d'envoi).
class PhotoViewerScreen extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;

  const PhotoViewerScreen({super.key, this.imageUrl, this.imageBytes});

  static void open(
    BuildContext context, {
    String? imageUrl,
    Uint8List? imageBytes,
  }) {
    if (imageUrl == null && imageBytes == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PhotoViewerScreen(
          imageUrl: imageUrl,
          imageBytes: imageBytes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = imageBytes != null
        ? Image.memory(imageBytes!, fit: BoxFit.contain)
        : Image.network(imageUrl!, fit: BoxFit.contain);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(child: image),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: Material(
              color: Colors.black.withValues(alpha: 0.55),
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
