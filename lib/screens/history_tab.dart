import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/alert_provider.dart';
import '../theme/app_theme.dart';
import '../utils/time.dart';
import '../widgets/status_pill.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlertProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();

    if (alertProvider.loadingHistory && alertProvider.history.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brand500),
      );
    }

    if (alertProvider.history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.history_rounded,
                color: AppColors.textSecondary,
                size: 40,
              ),
              const SizedBox(height: 12),
              const Text(
                "Aucune alerte pour l'instant.",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.brand500,
      onRefresh: () => context.read<AlertProvider>().loadHistory(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: alertProvider.history.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final alert = alertProvider.history[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alerte #${alert.id}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeAgo(alert.createdAt),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                      if (alert.responderName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Pris en charge par ${alert.responderName}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                StatusPill(status: alert.status),
              ],
            ),
          );
        },
      ),
    );
  }
}
