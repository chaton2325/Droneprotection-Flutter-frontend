import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const privacyPolicyUrl = 'https://www.dronaid.app/privacy.html';
const termsOfUseUrl = 'https://www.dronaid.app/terms.html';
const copyrightUrl = 'https://www.dronaid.app/copyright.html';

/// Ouvre une page legale dans le navigateur (exigence App Store 5.1.1(i)).
Future<void> openLegalUrl(BuildContext context, String url) async {
  var ok = false;
  try {
    ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Impossible d\'ouvrir $url')),
    );
  }
}
