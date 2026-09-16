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
                  _StaticState.demoState;

    return ListenableBuilder(
      listenable: state,
      builder: (context, child) {
        final patientName = state.currentUser?.name ?? 'John Doe';
        final events = state.events;
        
        // Safety terminology metrics
        final int totalScheduled = events.length;
        final int recorded = events.where((e) => e.status == MedicationStatus.medicationEventRecorded).length;
        final int unconfirmed = events.where((e) => e.status == MedicationStatus.unconfirmed).length;
        final int missed = events.where((e) => e.status == MedicationStatus.missed).length;
        
        // Device metrics
        final int loadCellTriggers = events.where((e) => e.deviceConfirmed == true && e.weightChange != null).length;
        final percentage = totalScheduled == 0 ? 0 : ((recorded / totalScheduled) * 100).round();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Doctor Analytics Dashboard'),
          ),
          body: SingleChildScrollView(
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
                            _buildStatTile('Recorded Activity', '$recorded', Icons.check_circle_outline),
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
                              'Device Event Completion Rate:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              '$percentage%',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.brandStart),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Weekly Matrix trends
                const Text(
                  'WEEKLY MEDICATION MONITORING TRENDS (MON–SUN)',
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
                        _buildTrendRow('Scheduled', [3, 3, 3, 3, 3, 3, 3]),
                        _buildTrendRow('Recorded', [3, 2, 3, 3, 2, 3, 2]),
                        _buildTrendRow('Unconfirmed', [0, 1, 0, 0, 1, 0, 1]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Device Load Cells & Switches Telemetry
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
                        _buildTelemetryRow('4 x HX711 Weight Deltas Recorded', '$loadCellTriggers triggers'),
                        _buildTelemetryRow('4 x Reed Door Sensor Openings', '${recorded + unconfirmed} openings'),
                        _buildTelemetryRow('ESP32 Telemetry Uptime', '98.5%'),
                        _buildTelemetryRow('DS3231 RTC Module Offset', '+0.08s'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
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
                      ? AppColors.statusCompleted 
                      : (label == 'Unconfirmed' && v > 0 ? AppColors.statusMissed : AppColors.textPrimary),
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
