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

class CaretakerScreen extends StatefulWidget {
  const CaretakerScreen({super.key});

  @override
  State<CaretakerScreen> createState() => _CaretakerScreenState();
}

class _CaretakerScreenState extends State<CaretakerScreen> {
  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<AppStateProviderState>()?.widget.state ?? 
                  _StaticState.demoState;

    return ListenableBuilder(
      listenable: state,
      builder: (context, child) {
        final list = state.caretakers;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Caretakers & Oversight'),
          ),
          body: list.isEmpty
              ? _buildEmptyState(context, state)
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final caretaker = list[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.brandStart.withValues(alpha: 0.1),
                                      foregroundColor: AppColors.brandStart,
                                      child: const Icon(Icons.person),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          caretaker.name,
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                        ),
                                        Text(
                                          '${caretaker.relationship} • ${caretaker.phone}',
                                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.statusMissed),
                                  onPressed: () => state.deleteCaretaker(caretaker.id),
                                ),
                              ],
                            ),
                            const Divider(height: 24, color: AppColors.border),
                            
                            const Text(
                              'ALERT PREFERENCES',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                            ),
                            const SizedBox(height: 8),
                            
                            _buildPreferenceRow(
                              'Unconfirmed / Missed Medication Alert', 
                              caretaker.notificationPreferences['missed_medication'] ?? false,
                              (val) => _updatePreference(state, caretaker, 'missed_medication', val),
                            ),
                            _buildPreferenceRow(
                              'Consecutive Unconfirmed/Missed Alerts (Threshold: ${caretaker.missedThreshold} events)', 
                              (caretaker.notificationPreferences['missed_medication'] ?? false) && caretaker.missedThreshold > 1,
                              null, // Fixed indicator or change threshold
                            ),
                            _buildPreferenceRow(
                              'Low Medicine Level Warning', 
                              caretaker.notificationPreferences['low_medicine_level'] ?? false,
                              (val) => _updatePreference(state, caretaker, 'low_medicine_level', val),
                            ),
                            _buildPreferenceRow(
                              'IoT Device Offline Alert', 
                              caretaker.notificationPreferences['device_offline'] ?? false,
                              (val) => _updatePreference(state, caretaker, 'device_offline', val),
                            ),
                            _buildPreferenceRow(
                              'Routine Recorded Medication Events (Disabled by default)', 
                              caretaker.notificationPreferences['medication_recorded'] ?? false,
                              (val) => _updatePreference(state, caretaker, 'medication_recorded', val),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddCaretakerSheet(context, state),
            backgroundColor: AppColors.brandStart,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Add Caretaker'),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Caretakers Added',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a trusted caretaker (spouse, child, parent) to receive safety notifications if a scheduled medication event goes unconfirmed.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showAddCaretakerSheet(context, state),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandStart,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Caretaker'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceRow(String label, bool value, Function(bool)? onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
          onChanged == null 
              ? Icon(
                  value ? Icons.check_circle_outline : Icons.remove_circle_outline, 
                  color: value ? AppColors.statusCompleted : AppColors.textSecondary,
                  size: 20,
                )
              : Switch(
                  value: value,
                  onChanged: onChanged,
                ),
        ],
      ),
    );
  }

  void _updatePreference(AppState state, Caretaker caretaker, String key, bool value) {
    final prefs = Map<String, bool>.from(caretaker.notificationPreferences);
    prefs[key] = value;

    final updated = Caretaker(
      id: caretaker.id,
      name: caretaker.name,
      relationship: caretaker.relationship,
      phone: caretaker.phone,
      email: caretaker.email,
      notificationPreferences: prefs,
      missedThreshold: caretaker.missedThreshold,
    );
    state.addCaretaker(updated);
  }

  void _showAddCaretakerSheet(BuildContext context, AppState state) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    String selectedRelationship = 'Spouse';
    int threshold = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add Caretaker', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedRelationship,
                decoration: const InputDecoration(labelText: 'Relationship', border: OutlineInputBorder()),
                items: ['Parent', 'Child', 'Spouse', 'Guardian', 'Caregiver', 'Other']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) => selectedRelationship = val ?? 'Other',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: threshold,
                decoration: const InputDecoration(
                  labelText: 'Alert Threshold (consecutive missed events)',
                  border: OutlineInputBorder(),
                ),
                items: [1, 2, 3]
                    .map((t) => DropdownMenuItem(value: t, child: Text('Notify after $t missed event(s)')))
                    .toList(),
                onChanged: (val) => threshold = val ?? 1,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isEmpty) return;
                  final caretaker = Caretaker(
                    id: 'caretaker_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameController.text,
                    relationship: selectedRelationship,
                    phone: phoneController.text,
                    email: emailController.text,
                    notificationPreferences: {
                      'missed_medication': true,
                      'low_medicine_level': true,
                      'device_offline': true,
                      'medication_recorded': false,
                    },
                    missedThreshold: threshold,
                  );
                  state.addCaretaker(caretaker);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandStart,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add Caretaker'),
              ),
              const SizedBox(height: 24),
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
