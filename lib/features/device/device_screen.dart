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

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<AppStateProviderState>()?.widget.state ?? 
                  _StaticState.demoState;

    return ListenableBuilder(
      listenable: state,
      builder: (context, child) {
        final isConnected = state.deviceStatus?.isConnected ?? false;
        final containers = state.containers;

        return Scaffold(
          appBar: AppBar(
            title: const Text('ESP32 IoT Box Telemetry'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Developer Mode Warning Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.statusDueBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.statusDue.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.developer_mode, color: AppColors.statusDue),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'SIMULATED DEVICE MODE ACTIVE • 4 Containers Physical Architecture\nSimulate door reed switches & load cell weight deltas prior to physical ESP32 flash.',
                          style: TextStyle(color: AppColors.statusDueText, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Hardware Status Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'HARDWARE SUBSYSTEMS',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isConnected ? AppColors.statusCompletedBg : AppColors.statusMissedBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isConnected ? 'CONNECTED (MOCK)' : 'DISCONNECTED',
                                style: TextStyle(
                                  fontSize: 10, 
                                  fontWeight: FontWeight.bold, 
                                  color: isConnected ? AppColors.statusCompletedText : AppColors.statusMissedText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'MediPill Box 4-Slot Architecture',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Text('Firmware: ESP32-MediPill-4Slot-v2.0', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const Divider(height: 24, color: AppColors.border),
                        
                        _buildSubsystemRow('4 x HX711 Load Cell Weight Modules', state.deviceStatus?.loadCellsConnected ?? false),
                        _buildSubsystemRow('4 x KY-025 Reed Door Switch Sensors', state.deviceStatus?.reedSensorsNormal ?? false),
                        _buildSubsystemRow('Container Dispensing Servo Mechanism', state.deviceStatus?.mechanismState == MedicationContainerMechanismState.ready),
                        _buildSubsystemRow('0.96" SSD1306 OLED Telemetry Display', state.deviceStatus?.oledOnline ?? false),
                        _buildSubsystemRow('Piezo Active Buzzer & LED Indicators', state.deviceStatus?.buzzerReady ?? false),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Exactly 4 Physical Containers
                const Text(
                  '4 PHYSICAL MEDICINE CONTAINERS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                ),
                const SizedBox(height: 8),
                
                ...List.generate(containers.length, (index) {
                  final c = containers[index];
                  final hasMed = c.assignedMedicineNames.isNotEmpty;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.brandStart.withValues(alpha: 0.08),
                                    foregroundColor: AppColors.brandStart,
                                    child: Text('${c.number}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Container ${c.number} — ${c.timeSlot}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      Text(
                                        hasMed ? c.assignedMedicineNames.join(', ') : 'No medicines currently assigned',
                                        style: TextStyle(
                                          fontSize: 12, 
                                          color: hasMed ? AppColors.textPrimary : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: c.inventoryStatus == 'Low' 
                                      ? AppColors.statusDueBg 
                                      : (c.inventoryStatus == 'Empty' ? AppColors.statusUpcomingBg : AppColors.statusCompletedBg),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  c.inventoryStatus.toUpperCase(),
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
                          const Divider(height: 20, color: AppColors.border),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Measured Weight: ${c.currentWeight.toStringAsFixed(2)} g', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              Text(
                                'Door: ${c.isOpen ? "OPEN" : "CLOSED"}',
                                style: TextStyle(
                                  fontSize: 12, 
                                  fontWeight: FontWeight.bold, 
                                  color: c.isOpen ? AppColors.statusMissed : AppColors.statusCompleted,
                                ),
                              ),
                            ],
                          ),
                          if (c.lastEvent != null) ...[
                            const SizedBox(height: 4),
                            Text('Last Event: ${c.lastEvent}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),

                // Interactive Simulator Controls Panel
                const Text(
                  'DEVELOPER SIMULATION CONTROLS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Test Container Reed Door Switches:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(4, (i) {
                            final cNum = i + 1;
                            return OutlinedButton(
                              onPressed: () {
                                final isOpen = containers[i].isOpen;
                                state.deviceService.simulateEvent(
                                  isOpen ? DeviceEvent.containerClosed : DeviceEvent.containerOpened,
                                  containerId: cNum,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Simulated Container $cNum door ${isOpen ? "Closed" : "Opened"}')),
                                );
                              },
                              child: Text('Toggle Door $cNum (${containers[i].isOpen ? "Open" : "Closed"})'),
                            );
                          }),
                        ),
                        const Divider(height: 24, color: AppColors.border),
                        
                        const Text(
                          'Test Load Cell Weight Changes:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  state.deviceService.simulateEvent(
                                    DeviceEvent.weightChanged, 
                                    containerId: 1,
                                    weightChange: -0.5,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Simulated Container 1 Weight Delta: -0.50 g')),
                                  );
                                },
                                child: const Text('-0.5g in Cont. 1'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  state.deviceService.simulateEvent(
                                    DeviceEvent.weightChanged, 
                                    containerId: 1,
                                    weightChange: 5.0,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Simulated Container 1 Refilled: +5.00 g')),
                                  );
                                },
                                child: const Text('+5.0g Refill Cont. 1'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            state.deviceService.simulateEvent(DeviceEvent.medicationEvent);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Simulated physical medication interaction & dispensing event')),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandStart, foregroundColor: Colors.white),
                          child: const Text('Simulate Medication Event'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubsystemRow(String label, bool isOk) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          Icon(
            isOk ? Icons.check_circle : Icons.error_outline,
            color: isOk ? AppColors.statusCompleted : AppColors.statusMissed,
            size: 18,
          ),
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
