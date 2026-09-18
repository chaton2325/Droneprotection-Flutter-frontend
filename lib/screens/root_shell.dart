import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/alert_provider.dart';
import '../state/auth_provider.dart';
import '../state/friend_alerts_provider.dart';
import '../state/friend_live_location_provider.dart';
import '../state/friends_provider.dart';
import '../state/live_location_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_nav_bar.dart';
import 'emergency_tab.dart';
import 'friend_alerts_tab.dart';
import 'friends_tab.dart';
import 'history_tab.dart';
import 'settings_tab.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final alertProvider = context.read<AlertProvider>();
      alertProvider.attachSocket();
      alertProvider.restoreActiveAlert();
      context.read<FriendAlertsProvider>().attachSocket();
      context.read<FriendsProvider>().load();
      context.read<FriendLiveLocationProvider>().attachSocket();
      final user = context.read<AuthProvider>().user;
      context.read<LiveLocationProvider>().syncFromUser(
        user?.liveLocationSharing ?? false,
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // La position en direct ne doit tourner que quand l'app est au premier
  // plan (voir LiveLocationProvider) - c'est la garantie demandee que le
  // partage s'arrete tout seul des que l'app passe en arriere-plan.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final liveLocation = context.read<LiveLocationProvider>();
    if (state == AppLifecycleState.resumed) {
      liveLocation.onForeground();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // 'inactive' est volontairement ignore : il se declenche aussi pour des
      // interruptions breves (volet de notifications, ecran d'appel) qui ne
      // doivent pas couper le partage de position.
      liveLocation.onBackground();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final pendingFriendRequests = context.watch<FriendsProvider>().incoming.length;
    final activeFriendAlerts = context.watch<FriendAlertsProvider>().active.length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.brand400, AppColors.brand700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand600.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Drone Aid Security',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                ),
                if (user != null)
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: const [
          EmergencyTab(),
          HistoryTab(),
          FriendAlertsTab(),
          FriendsTab(),
          SettingsTab(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ModernNavBar(
          currentIndex: _tabIndex,
          onTap: (index) => setState(() => _tabIndex = index),
          items: [
            const ModernNavItem(
              icon: Icons.warning_amber_outlined,
              selectedIcon: Icons.warning_rounded,
              label: 'Urgence',
            ),
            const ModernNavItem(
              icon: Icons.history_outlined,
              selectedIcon: Icons.history_rounded,
              label: 'Historique',
            ),
            ModernNavItem(
              icon: Icons.notifications_active_outlined,
              selectedIcon: Icons.notifications_active_rounded,
              label: 'Alertes',
              badgeCount: activeFriendAlerts,
            ),
            ModernNavItem(
              icon: Icons.people_outline_rounded,
              selectedIcon: Icons.people_rounded,
              label: 'Amis',
              badgeCount: pendingFriendRequests,
            ),
            const ModernNavItem(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings_rounded,
              label: 'Reglages',
            ),
          ],
        ),
      ),
    );
  }
}
