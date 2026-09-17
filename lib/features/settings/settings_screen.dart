import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../caretaker/caretaker_screen.dart';
import '../doctor/doctor_screen.dart';
import '../device/device_screen.dart';
import '../../services/auth/auth_service.dart';
import '../../services/device/device_service.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/medicine_image/medicine_image_service.dart';
import '../../data/repositories/repositories.dart';
import '../../main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<AppStateProviderState>()?.widget.state ?? 
                  _StaticState.cleanState;

    return ListenableBuilder(
      listenable: state,
      builder: (context, child) {
        final user = state.currentUser;
        final name = user?.name ?? 'Guest User';
        final email = user?.email ?? 'No active session';
        final phone = user?.phone ?? '';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Profile Section
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.brandStart.withValues(alpha: 0.1),
                      foregroundColor: AppColors.brandStart,
                      child: const Icon(Icons.person),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      phone.isNotEmpty ? '$email\n$phone' : email,
                      style: const TextStyle(fontSize: 12),
                    ),
                    isThreeLine: phone.isNotEmpty,
                  ),
                  const Divider(color: AppColors.border),

                  // Caretaker Link
                  ListTile(
                    leading: const Icon(Icons.people_outline, color: AppColors.brandStart),
                    title: const Text('Caretakers & Alerts configuration'),
                    subtitle: const Text('Configure threshold SMS/Push warning rules'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CaretakerScreen()),
                      );
                    },
                  ),
                  const Divider(color: AppColors.border, indent: 56),

                  // Doctor Link
                  ListTile(
                    leading: const Icon(Icons.health_and_safety_outlined, color: AppColors.brandStart),
                    title: const Text('Doctor Analytics Dashboard'),
                    subtitle: const Text('Medication trends and load cell weight analytics'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DoctorScreen()),
                      );
                    },
                  ),
                  const Divider(color: AppColors.border, indent: 56),

                  // Device Link
                  ListTile(
                    leading: const Icon(Icons.router_rounded, color: AppColors.brandStart),
                    title: const Text('ESP32 Device Settings'),
                    subtitle: const Text('Calibrate scales, configure WiFi, simulated inputs'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DeviceScreen()),
                      );
                    },
                  ),
                  const Divider(color: AppColors.border),

                  // Sign Out
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.statusMissed),
                    title: const Text('Sign Out', style: TextStyle(color: AppColors.statusMissed, fontWeight: FontWeight.bold)),
                    onTap: () {
                      state.logout();
                    },
                  ),
                  const Divider(color: AppColors.border),

                  // App Version
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        'MediPill Monitor\nVersion 1.0.0 (ESP32-Ready)',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
