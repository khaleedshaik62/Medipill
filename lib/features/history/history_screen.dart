import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../services/auth/auth_service.dart';
import '../../services/device/device_service.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/medicine_image/medicine_image_service.dart';
import '../../data/repositories/repositories.dart';
import '../../main.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedRange = 'This Week';

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<AppStateProviderState>()?.widget.state ?? 
                  _StaticState.cleanState;

    return ListenableBuilder(
      listenable: state,
      builder: (context, child) {
        final list = state.events;

        // Apply date range filter
        final now = DateTime.now();
        final mondayThisWeek = now.subtract(Duration(days: now.weekday - 1));
        final mondayLastWeek = mondayThisWeek.subtract(const Duration(days: 7));

        List<MedicationEvent> filteredList = list.where((e) {
          if (_selectedRange == 'This Week') {
            return e.scheduledTime.isAfter(mondayThisWeek.subtract(const Duration(days: 1)));
          } else if (_selectedRange == 'Previous Week') {
            return e.scheduledTime.isAfter(mondayLastWeek.subtract(const Duration(days: 1))) &&
                   e.scheduledTime.isBefore(mondayThisWeek);
          } else if (_selectedRange == 'This Month') {
            return e.scheduledTime.month == now.month && e.scheduledTime.year == now.year;
          }
          return true; // 'All'
        }).toList();

        // Sort events: latest first
        filteredList.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Event History'),
            actions: [
              DropdownButton<String>(
                value: _selectedRange,
                underline: const SizedBox(),
                icon: const Icon(Icons.calendar_month, color: AppColors.brandStart),
                items: ['This Week', 'Previous Week', 'This Month', 'All']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) {
                  setState(() => _selectedRange = val ?? 'This Week');
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: filteredList.isEmpty
              ? _buildEmptyState()
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final event = filteredList[index];
                        return _buildEventTile(event);
                      },
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildEventTile(MedicationEvent event) {
    Color statusColor = AppColors.statusUpcoming;
    Color statusBg = AppColors.statusUpcomingBg;
    IconData icon = Icons.watch_later_outlined;
    String statusLabel = event.status.name;

    switch (event.status) {
      case MedicationStatus.medicationEventRecorded:
        statusColor = AppColors.statusCompleted;
        statusBg = AppColors.statusCompletedBg;
        icon = Icons.check_circle;
        statusLabel = 'Recorded via ${event.source}';
        break;
      case MedicationStatus.missed:
        statusColor = AppColors.statusMissed;
        statusBg = AppColors.statusMissedBg;
        icon = Icons.cancel;
        statusLabel = 'Missed';
        break;
      case MedicationStatus.unconfirmed:
        statusColor = AppColors.statusUnconfirmedText;
        statusBg = AppColors.statusUnconfirmed;
        icon = Icons.help_outline;
        statusLabel = 'Unconfirmed';
        break;
      case MedicationStatus.due:
      case MedicationStatus.snoozed:
        statusColor = AppColors.statusDue;
        statusBg = AppColors.statusDueBg;
        icon = Icons.alarm;
        statusLabel = 'Due Soon';
        break;
      default:
        break;
    }

    final formattedScheduled = DateFormat('EEE, MMM dd - hh:mm a').format(event.scheduledTime);
    final formattedEvent = event.eventTime != null 
        ? DateFormat('hh:mm a').format(event.eventTime!) 
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: statusColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.medicineName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                  ),
                  Text(
                    '$formattedScheduled • Container ${event.containerId} (${event.timeSlot})',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  if (formattedEvent != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Event recorded at: $formattedEvent',
                        style: const TextStyle(fontSize: 12, color: AppColors.statusCompleted, fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (event.weightChange != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        'Measured weight change: ${event.weightChange! > 0 ? "+" : ""}${event.weightChange} g',
                        style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel.toUpperCase(),
                style: TextStyle(
                  fontSize: 9, 
                  fontWeight: FontWeight.bold, 
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No medication events recorded yet.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Events recorded via physical container door sensors or manual confirmations will be logged here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// Fallback preview
class _StaticState {
  static final cleanState = AppState(
    authService: MockAuthService(seedTestAccount: false),
    notificationService: MockNotificationService(),
    imageService: MockMedicineImageService(),
    deviceService: MockDeviceService(),
    medicineRepository: InMemoryMedicineRepository(),
    eventRepository: InMemoryEventRepository(),
    caretakerRepository: InMemoryCaretakerRepository(),
  );
}
