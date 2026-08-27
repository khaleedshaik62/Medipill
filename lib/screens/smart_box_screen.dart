import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../app/theme/app_colors.dart';

class SmartBoxScreen extends StatelessWidget {
  const SmartBoxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('MediPill Box'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildStatusHeader(theme),
            const SizedBox(height: 32),
            _buildBoxGrid(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusItem('Online', LucideIcons.checkCircle2, AppColors.healthy, theme),
          Container(width: 1, height: 40, color: AppColors.border),
          _buildStatusItem('7 Active', LucideIcons.grid, AppColors.primary, theme),
          Container(width: 1, height: 40, color: AppColors.border),
          _buildStatusItem('82% Bat', LucideIcons.batteryCharging, AppColors.healthy, theme),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, IconData icon, Color color, ThemeData theme) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildBoxGrid(ThemeData theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildCompartment('01', 82, 'Paracetamol', AppColors.healthy, theme)),
            const SizedBox(width: 16),
            Expanded(child: _buildCompartment('02', 64, 'Vitamin C', AppColors.healthy, theme)),
            const SizedBox(width: 16),
            Expanded(child: _buildCompartment('03', 25, 'Aspirin', AppColors.warning, theme)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildCompartment('04', 91, 'Ibuprofen', AppColors.healthy, theme)),
            const SizedBox(width: 16),
            Expanded(child: _buildCompartment('05', 54, 'Omega 3', AppColors.healthy, theme)),
            const SizedBox(width: 16),
            Expanded(child: _buildCompartment('06', 18, 'Iron', AppColors.error, theme)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 110, // Match the width of others approximately
              child: _buildCompartment('07', 0, 'Empty', AppColors.offline, theme),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompartment(String number, int percentage, String medName, Color statusColor, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: percentage > 0 ? statusColor.withValues(alpha: 0.3) : AppColors.border,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                number,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.mutedText,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Icon(
            LucideIcons.pill,
            color: percentage > 0 ? statusColor : AppColors.mutedText,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            '$percentage%',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            medName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.secondaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
