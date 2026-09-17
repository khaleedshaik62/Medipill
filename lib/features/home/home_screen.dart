import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../services/auth/auth_service.dart';
import '../../services/device/device_service.dart';
import '../../services/medicine_image/medicine_image_service.dart';
import '../../services/notifications/notification_service.dart';
import '../../data/repositories/repositories.dart';
import '../../main.dart';
import '../device/device_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<AppStateProviderState>()?.widget.state ?? 
                  _StaticState.cleanState;

    return ListenableBuilder(
      listenable: state,
      builder: (context, child) {
        final userName = state.currentUser?.name ?? 'User';
        final events = state.events;
        
        // Completion rate calculation from actual events
        final completedEvents = events.where((e) => e.status == MedicationStatus.medicationEventRecorded).toList();
        final pastEvents = events.where((e) => e.scheduledTime.isBefore(DateTime.now())).toList();
        final hasPastEvents = pastEvents.isNotEmpty;
        final percentage = hasPastEvents 
            ? ((completedEvents.length / pastEvents.length) * 100).round()
            : 0;

        // Next upcoming scheduled medication
        final upcomingEvents = events
            .where((e) => e.status == MedicationStatus.scheduled || e.status == MedicationStatus.due)
            .where((e) => e.scheduledTime.isAfter(DateTime.now().subtract(const Duration(minutes: 30))))
            .toList();
        upcomingEvents.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
        final MedicationEvent? nextEvent = upcomingEvents.isNotEmpty ? upcomingEvents.first : null;

        final isSimulated = state.deviceService.isSimulated;
        final isHardwareConnected = state.deviceStatus?.isConnected ?? false;
        final isDeviceOnline = isHardwareConnected || isSimulated;
        final containers = state.containers;

        return Scaffold(
          body: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 220,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await state.loadEvents();
                        await state.loadMedicines();
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User Profile Bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome, $userName',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Stay on track with your medication.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withValues(alpha: 0.85),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Tooltip(
                                      message: isHardwareConnected 
                                          ? 'ESP32 Hardware Connected' 
                                          : (isSimulated ? 'Simulated Device Active' : 'Device not connected'),
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 12),
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: isHardwareConnected 
                                              ? AppColors.statusCompleted 
                                              : (isSimulated ? AppColors.statusDue : AppColors.statusMissed),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                      ),
                                    ),
                                    CircleAvatar(
                                      backgroundColor: Colors.white24,
                                      foregroundColor: Colors.white,
                                      child: Text(userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'U'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),

                            // Weekly Event Completion Card
                            Card(
                              elevation: 0,
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'MEDICATION EVENTS RECORDED',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textSecondary,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        if (hasPastEvents && percentage >= 80)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              gradient: AppColors.goldGradient,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.workspace_premium, color: Colors.white, size: 14),
                                                SizedBox(width: 4),
                                                Text(
                                                  'High Recording Rate',
                                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (!hasPastEvents) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.event_note_outlined, size: 28, color: Colors.grey.shade400),
                                          const SizedBox(width: 12),
                                          const Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'No medication events recorded yet.',
                                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                                ),
                                                SizedBox(height: 2),
                                                Text(
                                                  'Event statistics will calculate automatically as scheduled medication times occur.',
                                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                    ] else ...[
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            '${completedEvents.length} / ${pastEvents.length}',
                                            style: const TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            '$percentage%',
                                            style: const TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.brandStart,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$percentage% of scheduled medication events recorded',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: completedEvents.length / pastEvents.length,
                                          minHeight: 8,
                                          backgroundColor: AppColors.border,
                                          color: AppColors.brandStart,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Calculated from observable device & application events (not clinical adherence).',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Next Upcoming Medication
                            const Text(
                              'NEXT UPCOMING MEDICATION',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (state.medicines.isEmpty)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Icon(Icons.medication_outlined, size: 36, color: Colors.grey.shade400),
                                      const SizedBox(width: 14),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'No medicines added yet.',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Add medicines to schedule daily slots across the 4 physical containers.',
                                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (nextEvent == null)
                              Card(
                                child: ListTile(
                                  leading: const Icon(Icons.check_circle_outline, color: AppColors.statusCompleted),
                                  title: const Text('All scheduled medications recorded!'),
                                  subtitle: Text('No further schedules for today.', style: TextStyle(color: Colors.grey.shade600)),
                                ),
                              )
                            else
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  nextEvent.medicineName,
                                                  style: const TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                                Text(
                                                  '${nextEvent.medicineStrength} • ${nextEvent.dose}',
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: AppColors.brandStart.withValues(alpha: 0.08),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.alarm,
                                              color: AppColors.brandStart,
                                              size: 28,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24, color: AppColors.border),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'SCHEDULED',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Today, ${DateFormat('hh:mm a').format(nextEvent.scheduledTime)}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              const Text(
                                                'PHYSICAL CONTAINER',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Container ${nextEvent.containerId} · ${nextEvent.timeSlot}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.brandStart,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () {
                                                state.updateEventStatus(
                                                  nextEvent.id,
                                                  MedicationStatus.medicationEventRecorded,
                                                  source: 'Mobile',
                                                );
                                              },
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(color: AppColors.border),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text('Confirm Manual'),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                state.updateEventStatus(
                                                  nextEvent.id,
                                                  MedicationStatus.snoozed,
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.brandStart,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text('Snooze 10m'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),

                            // Physical 4-Container Status Overview
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    '4 PHYSICAL MEDICINE CONTAINERS',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const DeviceScreen()),
                                    );
                                  },
                                  child: const Text('Manage Box', style: TextStyle(fontSize: 12, color: AppColors.brandStart, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            LayoutBuilder(
                              builder: (context, boxConstraints) {
                                final isWide = boxConstraints.maxWidth > 600;
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isWide ? 4 : 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: isWide ? 1.4 : 1.6,
                                  ),
                                  itemCount: containers.length,
                                  itemBuilder: (context, index) {
                                    final c = containers[index];
                                    final hasMed = c.assignedMedicineNames.isNotEmpty;
                                    final statusLabel = hasMed ? (isDeviceOnline ? c.inventoryStatus : 'CONFIGURED') : 'EMPTY';

                                    return Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    'Container ${c.number}',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: statusLabel == 'Low' 
                                                        ? AppColors.statusDueBg 
                                                        : (statusLabel == 'EMPTY' ? AppColors.statusUpcomingBg : AppColors.statusCompletedBg),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    statusLabel,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: statusLabel == 'Low' 
                                                          ? AppColors.statusDueText 
                                                          : (statusLabel == 'EMPTY' ? AppColors.statusUpcomingText : AppColors.statusCompletedText),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              c.timeSlot,
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                            ),
                                            Text(
                                              isDeviceOnline
                                                  ? '${c.currentWeight.toStringAsFixed(1)} g • door: ${c.isOpen ? "OPEN" : "CLOSED"}'
                                                  : (hasMed ? '${c.assignedMedicineNames.length} med(s) assigned' : 'No hardware linked'),
                                              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 20),

                            // Device Status Banner
                            Card(
                              color: isHardwareConnected 
                                  ? AppColors.cardSurface 
                                  : (isSimulated ? const Color(0xFFFBF8F2) : const Color(0xFFFBF4F5)),
                              child: ListTile(
                                leading: Icon(
                                  isHardwareConnected 
                                      ? Icons.router_rounded 
                                      : (isSimulated ? Icons.developer_mode : Icons.wifi_off_rounded),
                                  color: isHardwareConnected 
                                      ? AppColors.brandStart 
                                      : (isSimulated ? AppColors.statusDue : AppColors.statusMissed),
                                  size: 28,
                                ),
                                title: Text(
                                  isHardwareConnected 
                                      ? 'MediPill Box • Connected' 
                                      : (isSimulated ? 'SIMULATED DEVICE — TESTING' : 'Device not connected'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isHardwareConnected 
                                        ? AppColors.textPrimary 
                                        : (isSimulated ? AppColors.statusDueText : AppColors.statusMissedText),
                                  ),
                                ),
                                subtitle: Text(
                                  isHardwareConnected
                                      ? 'Physical ESP32 IoT Box active • Sensors online'
                                      : (isSimulated
                                          ? 'Developer simulation active • Telemetry is simulated'
                                          : 'No physical device connected • Mobile fallback active'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                trailing: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const DeviceScreen()),
                                    );
                                  },
                                  child: const Text('Configure'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Fallback preview State
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
