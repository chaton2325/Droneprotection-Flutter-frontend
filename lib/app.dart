import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/require_avatar_screen.dart';
import 'screens/root_shell.dart';
import 'screens/splash_screen.dart';
import 'state/auth_provider.dart';
import 'theme/app_theme.dart';

class DronaidApp extends StatelessWidget {
  const DronaidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drone Aid Security',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return switch (auth.status) {
      AuthStatus.unknown => const SplashScreen(),
      AuthStatus.unauthenticated => const LoginScreen(),
      AuthStatus.authenticated =>
        user != null && user.canTrigger && user.avatarUrl == null
            ? const RequireAvatarScreen()
            : const RootShell(),
    };
  }
}
