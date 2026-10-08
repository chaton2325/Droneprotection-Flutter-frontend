import 'package:flutter/material.dart';

class DronaidLogo extends StatelessWidget {
  const DronaidLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
    );
  }
}
