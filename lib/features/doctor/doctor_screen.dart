import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../services/auth/auth_service.dart';
import '../../services/device/device_service.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/medicine_image/medicine_image_service.dart';
import '../../data/repositories/repositories.dart';
import '../../main.dart';

class DoctorScreen extends StatelessWidget {
  const DoctorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<AppStateProviderState>()?.widget.state ?? 
                  _StaticState.cleanState;

    return ListenableBuilder(
      listenable: state,
      builder: (context, child) {
        final patientName = state.currentUser?.name ?? 'Patient';
        final events = state.events;

        // Safety terminology metrics from real application data
        final int totalScheduled = events.length;
        final int recorded = events.where((e) => e.status == MedicationStatus.medicationEventRecorded).length;
        final int unconfirmed = events.where((e) => e.status == MedicationStatus.unconfirmed).length;
        final int missed = events.where((e) => e.status == MedicationStatus.missed).length;
        
        final percentage = totalScheduled == 0 ? 0 : ((recorded / totalScheduled) * 100).round();

        // Calculate real trend per day for current week (Monday to Sunday)
        final now = DateTime.now();
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final weekStart = DateTime(monday.year, monday.month, monday.day);
        final weekEnd = weekStart.add(const Duration(days: 7));
        final weekEvents = events.where((e) => 
            e.scheduledTime.isAfter(weekStart.subtract(const Duration(seconds: 1))) && 
            e.scheduledTime.isBefore(weekEnd)
        ).toList();

        final List<int> scheduledPerDay = List.generate(7, (i) {
          final day = i + 1;
          return weekEvents.where((e) => e.scheduledTime.weekday == day).length;
        });
        final List<int> recordedPerDay = List.generate(7, (i) {
          final day = i + 1;
          return weekEvents.where((e) => e.scheduledTime.weekday == day && e.status == MedicationStatus.medicationEventRecorded).length;
        });
        final List<int> unconfirmedPerDay = List.generate(7, (i) {
          final day = i + 1;
          return weekEvents.where((e) => e.scheduledTime.weekday == day && e.status == MedicationStatus.unconfirmed).length;
        });

        // Real observable device metrics
        final int loadCellTriggers = events.where((e) => e.deviceConfirmed == true && e.weightChange != null).length;
        final int deviceEventsLogged = events.where((e) => e.source == 'IoT Device' || e.source == 'Simulated Device').length;

        final isHardwareConnected = state.deviceStatus?.isConnected ?? false;
        final isSimulated = state.deviceService.isSimulated;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Doctor Analytics Dashboard'),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: events.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Medical Safety Disclaimer
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.statusCompletedBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.statusCompleted.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.health_and_safety_outlined, color: AppColors.statusCompleted, size: 24),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Clinical Notice: Displays Device-Detected Medication Activity patterns across the 4 physical containers. Ingestion cannot be medically confirmed by sensors alone. Routine daily reminders are disabled for doctor profiles.',
                                    style: TextStyle(color: AppColors.statusCompletedText, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Patient overview
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PATIENT MONITORING SUMMARY',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    patientName,
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  const Divider(height: 24, color: AppColors.border),
                                  
                                  Row(
                                    children: [
                                      _buildStatTile('Scheduled Events', '$totalScheduled', Icons.calendar_today_outlined),
                                      _buildStatTile('Recorded Events', '$recorded', Icons.check_circle_outline),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      _buildStatTile('Unconfirmed Events', '$unconfirmed', Icons.help_outline),
                                      _buildStatTile('Missed Events', '$missed', Icons.cancel_outlined),
                                    ],
                                  ),
                                  const Divider(height: 24, color: AppColors.border),
                                  
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Recorded vs Scheduled Events:',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Text(
                                        '$recorded / $totalScheduled ($percentage%)',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandStart),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Weekly Matrix trends calculated from real stored events
                          const Text(
                            'MEDICATION EVENT RECORDING TREND (MON–SUN)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  _buildTrendHeaderRow(),
                                  const Divider(color: AppColors.border),
                                  _buildTrendRow('Scheduled', scheduledPerDay),
                                  _buildTrendRow('Recorded', recordedPerDay),
                                  _buildTrendRow('Unconfirmed', unconfirmedPerDay),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Real Observable Device Telemetry
                          const Text(
                            '4-CONTAINER HARDWARE TELEMETRY LOGS',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTelemetryRow(
                                    'Hardware Connection State', 
                                    isHardwareConnected 
                                        ? 'Connected' 
                                        : (isSimulated ? 'Simulated Device (Testing)' : 'Device not connected'),
                                  ),
                                  _buildTelemetryRow('HX711 Weight Deltas Confirmed', '$loadCellTriggers triggers'),
                                  _buildTelemetryRow('Physical Door Sensor Events', '$deviceEventsLogged events recorded'),
                                  _buildTelemetryRow(
                                    'Dispenser Physical Architecture', 
                                    '4 Physical Containers (Reused Mon–Sun)',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Not enough medication-event data yet.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Analytics and recording trends across the 4 physical containers will appear after medication events are recorded.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardSurfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.brandStart, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendHeaderRow() {
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return Row(
      children: [
        const Expanded(child: SizedBox()),
        ...days.map((d) => Expanded(
          child: Center(
            child: Text(
              d,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.textSecondary),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildTrendRow(String label, List<int> values) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
            ),
          ),
          ...values.map((v) => Expanded(
            child: Center(
              child: Text(
                '$v',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: label == 'Recorded' 
                      ? (v > 0 ? AppColors.statusCompleted : AppColors.textSecondary)
                      : (label == 'Unconfirmed' && v > 0 ? AppColors.statusMissed : AppColors.textSecondary),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTelemetryRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.brandStart)),
        ],
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
