import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../app/theme/app_colors.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.calendar),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TODAY',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.mutedText,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            _buildTimelineItem(
              time: '08:00 AM',
              medName: 'Paracetamol',
              dosage: '500 mg',
              status: 'Completed',
              isCompleted: true,
              theme: theme,
            ),
            _buildTimelineItem(
              time: '01:00 PM',
              medName: 'Vitamin D',
              dosage: '1 tablet',
              status: 'Completed',
              isCompleted: true,
              theme: theme,
            ),
            _buildTimelineItem(
              time: '08:00 PM',
              medName: 'Paracetamol',
              dosage: '500 mg',
              status: 'Upcoming',
              isCompleted: false,
              isActive: true,
              theme: theme,
            ),
            _buildTimelineItem(
              time: '10:00 PM',
              medName: 'Melatonin',
              dosage: '5 mg',
              status: 'Upcoming',
              isCompleted: false,
              isLast: true,
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String time,
    required String medName,
    required String dosage,
    required String status,
    required bool isCompleted,
    bool isActive = false,
    bool isLast = false,
    required ThemeData theme,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Column
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.primary : AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          
          // Line Column
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.healthy
                      : (isActive ? AppColors.primary : AppColors.border),
                  shape: BoxShape.circle,
                  border: isActive
                      ? Border.all(color: AppColors.softBlue, width: 4)
                      : null,
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 10, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? AppColors.healthy.withValues(alpha: 0.5) : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          
          // Content Column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.softBlue : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dosage,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          isCompleted ? LucideIcons.checkCircle2 : LucideIcons.clock,
                          size: 16,
                          color: isCompleted ? AppColors.healthy : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isCompleted ? AppColors.healthy : AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
