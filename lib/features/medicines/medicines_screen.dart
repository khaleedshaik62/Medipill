import 'package:flutter/foundation.dart';
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

class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<AppStateProviderState>()?.widget.state ?? 
                  _StaticState.cleanState;

    return ListenableBuilder(
      listenable: state,
      builder: (context, child) {
        final list = state.medicines;

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Medicines'),
          ),
          body: list.isEmpty
              ? _buildEmptyState(context, state)
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final med = list[index];
                        
                        // Look up container from state
                        final containers = state.containers;
                        final container = containers.firstWhere(
                          (c) => c.number == med.containerId, 
                          orElse: () => PhysicalContainer(
                            id: med.containerId,
                            number: med.containerId,
                            name: 'Container ${med.containerId}',
                            timeSlot: med.timeSlot,
                          ),
                        );

                        final isDeviceOnline = state.deviceService.isSimulated || (state.deviceStatus?.isConnected ?? false);
                        final levelLabel = isDeviceOnline ? container.inventoryStatus : 'Configured';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
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
                                            med.name,
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                          ),
                                          Text(
                                            '${med.strength} • ${med.dose} (${med.form})',
                                            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: med.active,
                                      onChanged: (val) {
                                        final updated = Medicine(
                                          id: med.id,
                                          name: med.name,
                                          strength: med.strength,
                                          form: med.form,
                                          dose: med.dose,
                                          containerId: med.containerId,
                                          timeSlot: med.timeSlot,
                                          frequency: med.frequency,
                                          reminderTimes: med.reminderTimes,
                                          startDate: med.startDate,
                                          endDate: med.endDate,
                                          foodInstruction: med.foodInstruction,
                                          notes: med.notes,
                                          active: val,
                                        );
                                        state.addMedicine(updated);
                                      },
                                    ),
                                  ],
                                ),
                                const Divider(height: 20, color: AppColors.border),
                                
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('ASSIGNED CONTAINER', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text('Container ${med.containerId} · ${med.timeSlot}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.brandStart)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        const Text('CONTAINER LEVEL', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text(
                                          levelLabel, 
                                          style: TextStyle(
                                            fontSize: 13, 
                                            fontWeight: FontWeight.bold,
                                            color: levelLabel == 'Low' 
                                                ? AppColors.statusDue 
                                                : (levelLabel == 'Empty' ? AppColors.statusUpcoming : AppColors.statusCompleted),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('SCHEDULED TIMES', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text(med.reminderTimes.join(', '), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.edit_outlined, size: 18),
                                      label: const Text('Edit'),
                                      onPressed: () => _openAddEditMedicineWorkflow(context, state, medicine: med),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.statusMissed),
                                      label: const Text('Delete', style: TextStyle(color: AppColors.statusMissed)),
                                      onPressed: () => state.deleteMedicine(med.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.brandStart,
            foregroundColor: Colors.white,
            onPressed: () => _openAddEditMedicineWorkflow(context, state),
            child: const Icon(Icons.add),
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
            Icon(Icons.medication_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No medicines added yet.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your medicines to automatically schedule your weekly plan across the 4 physical containers.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _openAddEditMedicineWorkflow(context, state),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandStart,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Medicine'),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddEditMedicineWorkflow(BuildContext context, AppState state, {Medicine? medicine}) {
    final isWide = MediaQuery.of(context).size.width >= 768;

    if (isWide) {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580, maxHeight: 850),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _AddMedicineWorkflow(state: state, existingMedicine: medicine),
              ),
            ),
          );
        },
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return _AddMedicineWorkflow(state: state, existingMedicine: medicine);
        },
      );
    }
  }
}

class _AddMedicineWorkflow extends StatefulWidget {
  final AppState state;
  final Medicine? existingMedicine;
  const _AddMedicineWorkflow({required this.state, this.existingMedicine});

  @override
  State<_AddMedicineWorkflow> createState() => _AddMedicineWorkflowState();
}

class _AddMedicineWorkflowState extends State<_AddMedicineWorkflow> {
  int _step = 0; // 0 = Mode Selection, 1 = OCR Simulation, 2 = Details review/manual edit
  bool _isOcrProcessing = false;
  
  final _nameController = TextEditingController();
  final _strengthController = TextEditingController();
  final _doseController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedForm = 'Tablet';
  String _selectedFrequency = 'Once daily';
  List<String> _reminderTimes = ['08:00'];
  int _selectedContainer = 1;
  String _foodInstruction = 'After food';
  int _durationDays = 7;

  // Container slot metadata (Architecture requirement: 4 physical containers)
  final List<Map<String, dynamic>> _containerSlots = [
    {'id': 1, 'name': 'Container 1', 'slot': 'Morning'},
    {'id': 2, 'name': 'Container 2', 'slot': 'Afternoon'},
    {'id': 3, 'name': 'Container 3', 'slot': 'Evening'},
    {'id': 4, 'name': 'Container 4', 'slot': 'Night'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingMedicine != null) {
      _step = 2; // Jump to edit
      final med = widget.existingMedicine!;
      _nameController.text = med.name;
      _strengthController.text = med.strength;
      _doseController.text = med.dose;
      _notesController.text = med.notes ?? '';
      _selectedForm = med.form;
      _selectedFrequency = med.frequency;
      _reminderTimes = List.from(med.reminderTimes);
      _selectedContainer = med.containerId;
      _foodInstruction = med.foodInstruction;
      _durationDays = med.endDate.difference(med.startDate).inDays;
      if (_durationDays <= 0) _durationDays = 7;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _strengthController.dispose();
    _doseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildCurrentStepView(),
        ),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    if (_step == 0) {
      return _buildModeSelection();
    } else if (_step == 1) {
      return _buildOcrSimulation();
    } else {
      return _buildDetailForm();
    }
  }

  Widget _buildModeSelection() {
    final isDesktopOrWeb = kIsWeb || 
        defaultTargetPlatform == TargetPlatform.windows || 
        defaultTargetPlatform == TargetPlatform.linux || 
        defaultTargetPlatform == TargetPlatform.macOS;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Add Medicine',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'How would you like to add your medicine?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 24),
        
        // Scan Medicine Image (OCR)
        InkWell(
          onTap: () {
            if (isDesktopOrWeb) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Camera Scanning Unavailable'),
                  content: const Text(
                    'Camera scanning is unavailable on this platform. You can upload an image or enter the medicine manually.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() => _step = 1); // Allow image sample simulation
                      },
                      child: const Text('Simulate Image OCR'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() => _step = 2);
                      },
                      child: const Text('Enter Manually'),
                    ),
                  ],
                ),
              );
            } else {
              setState(() => _step = 1);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Scan Medicine Image', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        isDesktopOrWeb 
                            ? 'Camera unavailable on desktop/web (Image upload available)' 
                            : 'Extract prescription / label using OCR', 
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Enter Manually
        OutlinedButton(
          onPressed: () {
            setState(() => _step = 2);
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(20),
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Row(
            children: [
              Icon(Icons.edit_note_outlined, color: AppColors.brandStart, size: 36),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Enter Manually', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 4),
                    Text('Enter details and assign physical container (1 to 4)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildOcrSimulation() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('OCR Image Processing', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Select an image source to simulate OCR extraction for testing:',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),

        if (_isOcrProcessing)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Extracting medicine details using OCR...'),
              ],
            ),
          )
        else ...[
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined, color: AppColors.brandStart),
            title: const Text('Prescription Image'),
            subtitle: const Text('Simulates scanning a doctor prescription'),
            onTap: () => _simulateScan('prescription'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.label_important_outline, color: AppColors.brandStart),
            title: const Text('Medicine Bottle Label Image'),
            subtitle: const Text('Simulates scanning a commercial medicine bottle'),
            onTap: () => _simulateScan('label'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.blur_off, color: AppColors.statusMissed),
            title: const Text('Blurry / Unclear Image (OCR Failure Test)'),
            subtitle: const Text('Simulates low-light conditions with failure guidance'),
            onTap: () => _simulateScan('unclear'),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDetailForm() {
    final existingInContainer = widget.state.medicines
        .where((m) => m.containerId == _selectedContainer && m.id != widget.existingMedicine?.id)
        .map((m) => m.name)
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Medicine Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        
        // Safety notice
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.statusDueBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.statusDue.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.health_and_safety_outlined, color: AppColors.statusDue, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Please verify details before saving. System does not automatically alter medical dosage.',
                  style: TextStyle(color: AppColors.statusDueText, fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Medicine Name', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _strengthController,
                decoration: const InputDecoration(labelText: 'Strength (e.g. 500mg)', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _doseController,
                decoration: const InputDecoration(labelText: 'Dose (e.g. 1 Tablet)', border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          initialValue: _selectedForm,
          decoration: const InputDecoration(labelText: 'Form', border: OutlineInputBorder()),
          items: ['Tablet', 'Capsule', 'Syrup', 'Drops', 'Cream', 'Other']
              .map((f) => DropdownMenuItem(value: f, child: Text(f)))
              .toList(),
          onChanged: (val) => setState(() => _selectedForm = val ?? 'Tablet'),
        ),
        const SizedBox(height: 12),

        // Assign to exactly ONE OF FOUR physical containers
        DropdownButtonFormField<int>(
          initialValue: _selectedContainer,
          decoration: const InputDecoration(
            labelText: 'Assign Physical Container (1 of 4)', 
            border: OutlineInputBorder(),
          ),
          items: _containerSlots.map((c) {
            return DropdownMenuItem<int>(
              value: c['id'] as int,
              child: Text('${c['name']} — ${c['slot']}'),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedContainer = val ?? 1),
        ),
        if (existingInContainer.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Note: Container $_selectedContainer currently also holds: ${existingInContainer.join(", ")}',
            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.statusDueText),
          ),
        ],
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          initialValue: _selectedFrequency,
          decoration: const InputDecoration(labelText: 'Frequency', border: OutlineInputBorder()),
          items: ['Once daily', 'Twice daily', 'Three times daily', 'Four times daily', 'Custom']
              .map((f) => DropdownMenuItem(value: f, child: Text(f)))
              .toList(),
          onChanged: (val) {
            setState(() {
              _selectedFrequency = val ?? 'Once daily';
              if (_selectedFrequency == 'Once daily') _reminderTimes = ['08:00'];
              if (_selectedFrequency == 'Twice daily') _reminderTimes = ['08:00', '20:00'];
              if (_selectedFrequency == 'Three times daily') _reminderTimes = ['08:00', '13:00', '20:00'];
              if (_selectedFrequency == 'Four times daily') _reminderTimes = ['08:00', '12:00', '16:00', '20:00'];
            });
          },
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          initialValue: _foodInstruction,
          decoration: const InputDecoration(labelText: 'Food Instruction', border: OutlineInputBorder()),
          items: ['Before food', 'After food', 'With food', 'Any time', 'Not specified']
              .map((f) => DropdownMenuItem(value: f, child: Text(f)))
              .toList(),
          onChanged: (val) => setState(() => _foodInstruction = val ?? 'Not specified'),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _notesController,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Notes / Medical instructions', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: _saveMedicine,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandStart,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Save Medication & Plan'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _simulateScan(String imageKey) async {
    setState(() {
      _isOcrProcessing = true;
    });

    try {
      final draft = await widget.state.imageService.processMedicineImage(imageKey);
      
      if (draft.name == null) {
        setState(() {
          _isOcrProcessing = false;
          _step = 0;
        });
        
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('OCR Scan Failed'),
            content: const Text(
              "We couldn't confidently read this image.\n\nTry:\n• Better lighting\n• A clearer image\n• Keeping the label flat\n• Taking the image closer"
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('Try Again'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _step = 2);
                },
                child: const Text('Enter Manually'),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          _isOcrProcessing = false;
          _step = 2; // Jump to verify/edit form
          _nameController.text = draft.name ?? '';
          _strengthController.text = draft.strength ?? '';
          _doseController.text = draft.dose ?? '';
          _selectedForm = draft.form ?? 'Tablet';
          _selectedFrequency = draft.frequency ?? 'Once daily';
          _reminderTimes = draft.reminderTimes ?? ['08:00'];
          _foodInstruction = draft.foodInstruction ?? 'After food';
          _notesController.text = draft.notes ?? '';
        });
      }
    } catch (e) {
      setState(() {
        _isOcrProcessing = false;
      });
    }
  }

  void _saveMedicine() async {
    if (_nameController.text.trim().isEmpty) return;

    final slotInfo = _containerSlots.firstWhere(
      (c) => c['id'] == _selectedContainer,
      orElse: () => {'slot': 'Morning'},
    );

    final medicine = Medicine(
      id: widget.existingMedicine?.id ?? 'med_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      strength: _strengthController.text.trim(),
      form: _selectedForm,
      dose: _doseController.text.trim(),
      containerId: _selectedContainer,
      timeSlot: slotInfo['slot'] as String,
      frequency: _selectedFrequency,
      reminderTimes: _reminderTimes,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(Duration(days: _durationDays)),
      foodInstruction: _foodInstruction,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      active: widget.existingMedicine?.active ?? true,
    );

    await widget.state.addMedicine(medicine);
    if (!mounted) return;
    Navigator.pop(context);
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
