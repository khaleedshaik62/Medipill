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
                  _StaticState.demoState;

    return ListenableBuilder(
      listenable: state,
      builder: (context, child) {
        final userName = state.currentUser?.name ?? 'John';
        final events = state.events;
        
        // Completion rate calculation
        final completedEvents = events.where((e) => e.status == MedicationStatus.medicationEventRecorded).toList();
        final pastEvents = events.where((e) => e.scheduledTime.isBefore(DateTime.now())).toList();
        final percentage = pastEvents.isEmpty 
            ? 100 
            : ((completedEvents.length / pastEvents.length) * 100).round();

        // Get next upcoming scheduled medication
        final upcomingEvents = events
            .where((e) => e.status == MedicationStatus.scheduled || e.status == MedicationStatus.due)
            .where((e) => e.scheduledTime.isAfter(DateTime.now().subtract(const Duration(minutes: 30))))
            .toList();
        upcomingEvents.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
        final MedicationEvent? nextEvent = upcomingEvents.isNotEmpty ? upcomingEvents.first : null;

        final deviceConnected = state.deviceStatus?.isConnected ?? false;
        final containers = state.containers;

        return Scaffold(
          body: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 240,
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good Morning, $userName',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
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
                            Row(
                              children: [
                                Tooltip(
                                  message: deviceConnected ? 'IoT Device Online (Simulated)' : 'Device Offline',
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: deviceConnected ? AppColors.statusCompleted : AppColors.statusMissed,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                                CircleAvatar(
                                  backgroundColor: Colors.white24,
                                  foregroundColor: Colors.white,
                                  child: Text(userName.substring(0, 1).toUpperCase()),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

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
                                      'THIS WEEK',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    if (percentage >= 80)
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
                                              'High Completion',
                                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${completedEvents.length} / ${pastEvents.length} medication events recorded',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '$percentage%',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.brandStart,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: pastEvents.isEmpty ? 1.0 : completedEvents.length / pastEvents.length,
                                    minHeight: 8,
                                    backgroundColor: AppColors.border,
                                    color: AppColors.brandStart,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Medication event completion calculated from load cell & door sensors.',
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
                        if (nextEvent == null)
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
                            const Text(
                              '4 PHYSICAL MEDICINE CONTAINERS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                                letterSpacing: 1.0,
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

                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.6,
                          ),
                          itemCount: containers.length,
                          itemBuilder: (context, index) {
                            final c = containers[index];
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
                                        Text(
                                          'Container ${c.number}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: c.inventoryStatus == 'Low' 
                                                ? AppColors.statusDueBg 
                                                : (c.inventoryStatus == 'Empty' ? AppColors.statusUpcomingBg : AppColors.statusCompletedBg),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            c.inventoryStatus,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: c.inventoryStatus == 'Low' 
                                                  ? AppColors.statusDueText 
                                                  : (c.inventoryStatus == 'Empty' ? AppColors.statusUpcomingText : AppColors.statusCompletedText),
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
                                      '${c.currentWeight.toStringAsFixed(1)} g • door: ${c.isOpen ? "OPEN" : "CLOSED"}',
                                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // IoT Device Status Banner
                        Card(
                          color: deviceConnected ? AppColors.cardSurface : const Color(0xFFFBF4F5),
                          child: ListTile(
                            leading: Icon(
                              deviceConnected ? Icons.router_rounded : Icons.wifi_off_rounded,
                              color: deviceConnected ? AppColors.brandStart : AppColors.statusMissed,
                              size: 28,
                            ),
                            title: Text(
                              deviceConnected ? 'MediPill Box • Online (Mock ESP32)' : 'MediPill Box • Offline',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: deviceConnected ? AppColors.textPrimary : AppColors.statusMissedText,
                              ),
                            ),
                            subtitle: Text(
                              deviceConnected 
                                  ? 'SIMULATED DEVICE • 4 load cells & 4 reed sensors active'
                                  : 'Local fallback active • Mobile notifications enabled',
                              style: TextStyle(
                                fontSize: 12,
                                color: deviceConnected ? AppColors.textSecondary : AppColors.statusMissedText,
                              ),
                            ),
                            trailing: Switch(
                              value: deviceConnected,
                              onChanged: (val) {
                                state.deviceService.setDeviceConnected(val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
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
  static final demoState = AppState(
    authService: MockAuthService(),
    notificationService: MockNotificationService(),
    imageService: MockMedicineImageService(),
    deviceService: MockDeviceService(),
    medicineRepository: InMemoryMedicineRepository(),
    eventRepository: InMemoryEventRepository(),
    caretakerRepository: InMemoryCaretakerRepository(),
  );
}
