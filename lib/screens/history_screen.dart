import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../app/theme/app_colors.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.filter),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24.0),
        itemCount: 5,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          // Dummy data logic
          final statuses = [
            {'label': 'Verified', 'color': AppColors.healthy, 'bg': AppColors.softGreen},
            {'label': 'Taken', 'color': AppColors.primary, 'bg': AppColors.softBlue},
            {'label': 'Pending', 'color': AppColors.warning, 'bg': AppColors.softOrange},
            {'label': 'Missed', 'color': AppColors.error, 'bg': AppColors.softRed},
            {'label': 'Taken', 'color': AppColors.primary, 'bg': AppColors.softBlue},
          ];
          final medNames = ['Paracetamol', 'Vitamin C', 'Aspirin', 'Ibuprofen', 'Omega 3'];
          
          return _buildHistoryCard(
            medName: medNames[index],
            dosage: '500 mg',
            date: 'Yesterday, 08:00 PM',
            status: statuses[index]['label'] as String,
            statusColor: statuses[index]['color'] as Color,
            bgColor: statuses[index]['bg'] as Color,
            theme: theme,
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard({
    required String medName,
    required String dosage,
    required String date,
    required String status,
    required Color statusColor,
    required Color bgColor,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.pill, color: AppColors.mutedText),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medName,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status == 'Verified' || status == 'Taken')
                  Icon(LucideIcons.check, size: 14, color: statusColor)
                else if (status == 'Missed')
                  Icon(LucideIcons.alertCircle, size: 14, color: statusColor)
                else
                  Icon(LucideIcons.clock, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
