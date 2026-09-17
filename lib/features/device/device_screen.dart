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
                  _StaticState.cleanState;

    return ListenableBuilder(
      listenable: state,
      builder: (context, child) {
        final isHardwareConnected = state.deviceStatus?.isConnected ?? false;
        final isSimulated = state.deviceService.isSimulated;
        final containers = state.containers;

        return Scaffold(
          appBar: AppBar(
            title: const Text('ESP32 IoT Box Settings'),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Simulation Mode Active Banner
                    if (isSimulated) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.statusDueBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.statusDue.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.developer_mode, color: AppColors.statusDue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'SIMULATED DEVICE — TESTING',
                                    style: TextStyle(color: AppColors.statusDueText, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Simulated mode is active for development/testing. All sensor telemetry and weight deltas below are simulated.',
                                    style: TextStyle(color: AppColors.statusDueText.withValues(alpha: 0.9), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isSimulated,
                              onChanged: (val) {
                                state.toggleSimulationMode(val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

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
                                  'DEVICE STATUS',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isHardwareConnected 
                                        ? AppColors.statusCompletedBg 
                                        : (isSimulated ? AppColors.statusDueBg : AppColors.statusMissedBg),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isHardwareConnected 
                                        ? 'CONNECTED' 
                                        : (isSimulated ? 'SIMULATED DEVICE' : 'DISCONNECTED'),
                                    style: TextStyle(
                                      fontSize: 10, 
                                      fontWeight: FontWeight.bold, 
                                      color: isHardwareConnected 
                                          ? AppColors.statusCompletedText 
                                          : (isSimulated ? AppColors.statusDueText : AppColors.statusMissedText),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              isHardwareConnected 
                                  ? 'MediPill Box • Online' 
                                  : (isSimulated ? 'MediPill Box • Simulated Environment' : 'No physical device connected.'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              isHardwareConnected
                                  ? 'Firmware: ESP32-MediPill-4Slot-v2.0'
                                  : (isSimulated 
                                      ? 'Developer Simulator Active' 
                                      : 'Device not connected. Local mobile fallback mode is active.'),
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const Divider(height: 24, color: AppColors.border),
                            
                            _buildSubsystemRow('4 x HX711 Load Cell Weight Modules', isHardwareConnected || isSimulated, isSimulated),
                            _buildSubsystemRow('4 x KY-025 Reed Door Switch Sensors', isHardwareConnected || isSimulated, isSimulated),
                            _buildSubsystemRow('Container Dispensing Servo Mechanism', isHardwareConnected || isSimulated, isSimulated),
                            _buildSubsystemRow('0.96" SSD1306 OLED Telemetry Display', isHardwareConnected || isSimulated, isSimulated),
                            _buildSubsystemRow('Piezo Active Buzzer & LED Indicators', isHardwareConnected || isSimulated, isSimulated),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Developer Mode Toggle (when not simulated)
                    if (!isSimulated && !isHardwareConnected) ...[
                      Card(
                        color: AppColors.cardSurfaceAlt,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Icon(Icons.developer_mode, color: AppColors.brandStart, size: 28),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Developer Simulation Mode',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Enable to simulate load cell weights and door reed switches without physical ESP32 hardware.',
                                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: isSimulated,
                                onChanged: (val) {
                                  state.toggleSimulationMode(val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Exactly 4 Physical Containers Architecture
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
                                  Text(
                                    isHardwareConnected || isSimulated
                                        ? 'Measured Weight: ${c.currentWeight.toStringAsFixed(2)} g'
                                        : 'Measured Weight: — (Device not connected)',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    isHardwareConnected || isSimulated
                                        ? 'Door: ${c.isOpen ? "OPEN" : "CLOSED"}'
                                        : 'Door: —',
                                    style: TextStyle(
                                      fontSize: 12, 
                                      fontWeight: FontWeight.bold, 
                                      color: (isHardwareConnected || isSimulated) 
                                          ? (c.isOpen ? AppColors.statusMissed : AppColors.statusCompleted)
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              if (c.lastEvent != null && (isHardwareConnected || isSimulated)) ...[
                                const SizedBox(height: 4),
                                Text('Last Event: ${c.lastEvent}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),

                    // Interactive Simulator Controls Panel (only when simulation mode is active)
                    if (isSimulated) ...[
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
                                      child: const Text('-0.5g Cont. 1'),
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
                                      child: const Text('+5.0g Cont. 1'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {
                                  state.deviceService.simulateEvent(DeviceEvent.medicationEvent);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Simulated physical medication interaction event')),
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
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubsystemRow(String label, bool isOnline, bool isSimulated) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
              if (isSimulated && isOnline)
                const Padding(
                  padding: EdgeInsets.only(left: 6.0),
                  child: Text('(Simulated)', style: TextStyle(fontSize: 11, color: AppColors.statusDueText, fontStyle: FontStyle.italic)),
                ),
            ],
          ),
          Icon(
            isOnline ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isOnline 
                ? (isSimulated ? AppColors.statusDue : AppColors.statusCompleted)
                : AppColors.textSecondary,
            size: 18,
          ),
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
