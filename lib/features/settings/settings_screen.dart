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
                  _StaticState.demoState;

    return ListenableBuilder(
      listenable: state,
      builder: (context, child) {
        final email = state.currentUser?.email ?? 'john.doe@gmail.com';
        final phone = state.currentUser?.phone ?? '+1 555 0199';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // Profile Section
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.brandStart.withValues(alpha: 0.1),
                  foregroundColor: AppColors.brandStart,
                  child: const Icon(Icons.person),
                ),
                title: Text(state.currentUser?.name ?? 'John Doe', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('$email\n$phone', style: const TextStyle(fontSize: 12)),
                isThreeLine: true,
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

              // Appearance Options
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                child: Text('APPEARANCE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textSecondary, letterSpacing: 1.0)),
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text('Theme Mode'),
                trailing: const Text('Light Theme', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('System is optimized for high-contrast light mode for accessibility')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_format_outlined),
                title: const Text('Text Size'),
                trailing: const Text('Large (Elderly-Friendly)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Elderly accessibility typography is enabled by default')),
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
        );
      },
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
