import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';
import '../widgets/dronaid_logo.dart';

class _Need {
  const _Need(this.permission, this.icon, this.title, this.why);

  final Permission permission;
  final IconData icon;
  final String title;
  final String why;
}

const _needs = [
  _Need(
    Permission.locationWhenInUse,
    Icons.location_on_rounded,
    'Localisation',
    "Elle permet au pilote de drone et aux secours de vous retrouver "
        "precisement quand vous declenchez une alerte.",
  ),
  _Need(
    Permission.camera,
    Icons.videocam_rounded,
    'Cameras',
    "Une fois votre alerte acceptee, les cameras avant et arriere s'ouvrent "
        "pour que le repondant voie ce qui se passe autour de vous.",
  ),
  _Need(
    Permission.microphone,
    Icons.mic_rounded,
    'Micro',
    "Une fois votre alerte acceptee, le micro s'ouvre pour que le repondant "
        "entende la situation et puisse vous guider.",
  ),
];

/// Bloque toute l'application (meme la connexion) tant que la localisation,
/// les cameras et le micro ne sont pas autorises et que la localisation n'est
/// pas activee sur l'appareil. Si une autorisation est refusee definitivement,
/// le seul moyen d'avancer est de l'activer dans les parametres : l'ecran est
/// revalide automatiquement au retour dans l'application.
class PermissionGate extends StatefulWidget {
  const PermissionGate({super.key, required this.child});

  final Widget child;

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate>
    with WidgetsBindingObserver {
  Timer? _recheck;
  bool _loaded = false;
  bool _serviceOn = true;
  final Map<Permission, PermissionStatus> _status = {};

  bool get _allGranted =>
      _needs.every((n) => _status[n.permission]?.isGranted == true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
    // Filet de securite : une autorisation ou la localisation retiree sans
    // quitter l'app (volet de reglages rapides) ramene aussi cet ecran.
    _recheck = Timer.periodic(const Duration(seconds: 3), (_) => _check());
  }

  @override
  void dispose() {
    _recheck?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final statuses = <Permission, PermissionStatus>{};
    for (final n in _needs) {
      statuses[n.permission] = await n.permission.status;
    }
    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    setState(() {
      _status
        ..clear()
        ..addAll(statuses);
      _serviceOn = serviceOn;
      _loaded = true;
    });
  }

  Future<void> _activate(_Need need) async {
    var status = _status[need.permission];
    final isLocation = need.permission == Permission.locationWhenInUse;

    if (status?.isGranted == true && isLocation) {
      // Autorisee mais service de localisation eteint sur l'appareil.
      await _askSettings(
        need,
        message:
            "La localisation est desactivee sur votre telephone. Activez-la "
            "dans les reglages pour continuer.",
        open: Geolocator.openLocationSettings,
      );
    } else if (status?.isPermanentlyDenied == true ||
        status?.isRestricted == true) {
      await _askSettings(need);
    } else {
      status = await need.permission.request();
      // Refus : le systeme ne redemandera plus (ou plus pour cette session),
      // on guide donc l'utilisateur vers les reglages.
      if (!status.isGranted && mounted) await _askSettings(need);
    }
    await _check();
  }

  Future<void> _askSettings(
    _Need need, {
    String? message,
    Future<Object?> Function()? open,
  }) async {
    if (!mounted) return;
    final goToSettings = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(need.icon, color: AppColors.brand400, size: 32),
        title: Text('${need.title} obligatoire'),
        content: Text(
          message ??
              "Vous avez refuse cette autorisation. Dronaid Security ne peut "
                  "pas fonctionner sans elle : activez-la dans les parametres "
                  "de l'application, puis revenez ici.\n\n${need.why}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ouvrir les parametres'),
          ),
        ],
      ),
    );
    if (goToSettings == true) {
      await (open ?? openAppSettings)();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.brand500),
        ),
      );
    }
    if (_allGranted && _serviceOn) return widget.child;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Center(child: DronaidLogo(size: 80)),
              const SizedBox(height: 20),
              const Text(
                'Autorisations obligatoires',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                "Dronaid Security est une application d'urgence : sans ces "
                "autorisations, elle ne peut pas vous proteger.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              for (final n in _needs)
                _NeedTile(
                  need: n,
                  status: _status[n.permission],
                  serviceOff:
                      n.permission == Permission.locationWhenInUse &&
                      !_serviceOn,
                  onActivate: () => _activate(n),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeedTile extends StatelessWidget {
  const _NeedTile({
    required this.need,
    required this.status,
    required this.serviceOff,
    required this.onActivate,
  });

  final _Need need;
  final PermissionStatus? status;
  final bool serviceOff;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final granted = status?.isGranted == true && !serviceOff;
    final needsSettings =
        status?.isPermanentlyDenied == true || status?.isRestricted == true;
    final buttonLabel = serviceOff
        ? 'Activer la localisation'
        : needsSettings
        ? 'Ouvrir les parametres'
        : 'Activer';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface2.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: granted
              ? Colors.greenAccent.withValues(alpha: 0.5)
              : AppColors.brand500.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            need.icon,
            color: granted ? Colors.greenAccent : AppColors.brand400,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  need.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  need.why,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                if (!granted) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 38,
                    child: FilledButton(
                      onPressed: onActivate,
                      child: Text(buttonLabel),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (granted)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(
                Icons.check_circle_rounded,
                color: Colors.greenAccent,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}
