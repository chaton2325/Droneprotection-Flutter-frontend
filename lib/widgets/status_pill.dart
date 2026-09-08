import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusPill extends StatelessWidget {
  final String status;
  const StatusPill({super.key, required this.status});

  static const _labels = {
    'pending': 'En attente',
    'accepted': 'Prise en charge',
    'resolved': 'Resolue',
    'cancelled': 'Annulee',
  };

  static const _colors = {
    'pending': AppColors.brand500,
    'accepted': AppColors.warn500,
    'resolved': AppColors.ok500,
    'cancelled': AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? AppColors.textSecondary;
    final label = _labels[status] ?? status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
