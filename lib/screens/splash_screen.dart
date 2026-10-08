import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/dronaid_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DronaidLogo(size: 120),
            SizedBox(height: 24),
            CircularProgressIndicator(color: AppColors.brand500),
          ],
        ),
      ),
    );
  }
}
