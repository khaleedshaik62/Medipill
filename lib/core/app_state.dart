import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../services/auth/auth_service.dart';
import '../services/device/device_service.dart';
import '../services/medicine_image/medicine_image_service.dart';
import '../services/notifications/notification_service.dart';

class AppState extends ChangeNotifier {
  // Services
  final AuthService authService;
  final NotificationService notificationService;
  final MedicineImageService imageService;
  final DeviceService deviceService;

  // Repositories
  final MedicineRepository medicineRepository;
  final EventRepository eventRepository;
  final CaretakerRepository caretakerRepository;

  // State caches
  UserProfile? currentUser;
  List<Medicine> medicines = [];
  List<MedicationEvent> events = [];
  List<Caretaker> caretakers = [];
  DeviceStatus? deviceStatus;
  late List<PhysicalContainer> containers;
  late final Future<void> initialization;

  bool isLoading = false;

  AppState({
    required this.authService,
    required this.notificationService,
    required this.imageService,
    required this.deviceService,
    required this.medicineRepository,
    required this.eventRepository,
    required this.caretakerRepository,
  }) {
    containers = deviceService.getContainers();
    initialization = _init();
  }

  Future<void> _init() async {
    isLoading = true;
    notifyListeners();

    // Setup Auth Listener
    authService.authStateChanges.listen((user) {
      currentUser = user;
      notifyListeners();
    });
    currentUser = await authService.getCurrentUser();

    // Load initial repository data
    await loadMedicines();
    await loadEvents();
    await loadCaretakers();

    // Setup Device Listener
    deviceStatus = await deviceService.getDeviceStatus();
    containers = deviceService.getContainers();
    
    deviceService.deviceEvents.listen((event) async {
      debugPrint('AppState: Received device event -> $event');
      deviceStatus = await deviceService.getDeviceStatus();
      containers = deviceService.getContainers();
      
      if (event == DeviceEvent.medicationEvent) {
        await _recordDeviceMedicationEvent();
      }
      notifyListeners();
    });

    deviceService.containerStateChanges.listen((newContainers) {
      containers = newContainers;
      notifyListeners();
    });

    // Synchronize current medicines to the 4 containers
    await deviceService.syncMedicationPlan(medicines);

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadMedicines() async {
    medicines = await medicineRepository.getMedicines();
    notifyListeners();
  }

  Future<void> loadEvents() async {
    events = await eventRepository.getEvents();
    notifyListeners();
  }

  Future<void> loadCaretakers() async {
    caretakers = await caretakerRepository.getCaretakers();
    notifyListeners();
  }

  // Auth Operations
  Future<void> login(String email, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      currentUser = await authService.login(email, password);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String name, String email, String phone, String? dob) async {
    isLoading = true;
    notifyListeners();
    try {
      currentUser = await authService.signUp(name, email, phone, dob);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await authService.logout();
    currentUser = null;
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile profile) async {
    await authService.updateProfile(profile);
    currentUser = profile;
    notifyListeners();
  }

  // Medicine Operations
  Future<void> addMedicine(Medicine medicine) async {
    await medicineRepository.saveMedicine(medicine);
    await loadMedicines();
    await deviceService.syncMedicationPlan(medicines);
    
    // Auto-generate scheduled events for this medicine across the 7-day week
    await _generateEventsForMedicine(medicine);
  }

  Future<void> deleteMedicine(String id) async {
    await medicineRepository.deleteMedicine(id);
    await loadMedicines();
    await deviceService.syncMedicationPlan(medicines);
  }

  // Caretaker Operations
  Future<void> addCaretaker(Caretaker caretaker) async {
    await caretakerRepository.saveCaretaker(caretaker);
    await loadCaretakers();
  }

  Future<void> deleteCaretaker(String id) async {
    await caretakerRepository.deleteCaretaker(id);
    await loadCaretakers();
  }

  // Event Action
  Future<void> updateEventStatus(String eventId, MedicationStatus status, {String source = 'Manual'}) async {
    final idx = events.indexWhere((e) => e.id == eventId);
    if (idx != -1) {
      final ev = events[idx];
      final updated = ev.copyWith(
        status: status,
        eventTime: status == MedicationStatus.medicationEventRecorded ? DateTime.now() : null,
        source: source,
      );
      await eventRepository.saveEvent(updated);
      await loadEvents();
      
      // If missed alert is triggered and caretakers configured, notify them
      if (status == MedicationStatus.missed || status == MedicationStatus.unconfirmed) {
        _triggerCaretakerAlerts(ev);
      }
    }
  }

  // Generate mock events across the Monday–Sunday week reusing the physical container
  Future<void> _generateEventsForMedicine(Medicine medicine) async {
    final List<MedicationEvent> newEvents = [];
    final now = DateTime.now();
    
    // Current week: Monday to Sunday
    final monday = now.subtract(Duration(days: now.weekday - 1));
    
    for (int day = 0; day < 7; day++) {
      final currentDayDate = monday.add(Duration(days: day));
      for (var timeStr in medicine.reminderTimes) {
        final timeParts = timeStr.split(':');
        final hour = int.parse(timeParts[0]);
        final min = int.parse(timeParts[1]);
        
        final scheduledTime = DateTime(
          currentDayDate.year,
          currentDayDate.month,
          currentDayDate.day,
          hour,
          min,
        );

        MedicationStatus status = MedicationStatus.scheduled;
        DateTime? eventTime;
        String source = 'System';
        double? weightBefore;
        double? weightAfter;
        double? weightChange;
        bool confirmed = false;

        if (scheduledTime.isBefore(now)) {
          // Past events in current week
          final isMonOrWed = scheduledTime.weekday == 1 || scheduledTime.weekday == 3;
          if (isMonOrWed) {
            status = MedicationStatus.medicationEventRecorded;
            eventTime = scheduledTime.add(const Duration(minutes: 5));
            source = 'IoT Device';
            weightBefore = 15.0;
            weightAfter = 14.5;
            weightChange = -0.5;
            confirmed = true;
          } else {
            status = MedicationStatus.unconfirmed;
          }
        } else if (scheduledTime.difference(now).inHours <= 2) {
          status = MedicationStatus.due;
        }

        newEvents.add(
          MedicationEvent(
            id: '${medicine.id}_${scheduledTime.millisecondsSinceEpoch}',
            medicineId: medicine.id,
            medicineName: medicine.name,
            medicineStrength: medicine.strength,
            medicineForm: medicine.form,
            dose: medicine.dose,
            scheduledTime: scheduledTime,
            eventTime: eventTime,
            containerId: medicine.containerId,
            timeSlot: medicine.timeSlot,
            status: status,
            source: source,
            weightBefore: weightBefore,
            weightAfter: weightAfter,
            weightChange: weightChange,
            deviceConfirmed: confirmed,
          ),
        );
      }
    }
    await eventRepository.saveEvents(newEvents);
    await loadEvents();
  }

  // IoT event simulation hook: record when simulated sensor registers a change
  Future<void> _recordDeviceMedicationEvent() async {
    final now = DateTime.now();
    MedicationEvent? targetEvent;
    
    // Look for due or scheduled events near now
    final due = events.where((e) => e.status == MedicationStatus.due || e.status == MedicationStatus.scheduled).toList();
    if (due.isNotEmpty) {
      due.sort((a, b) => (a.scheduledTime.difference(now).abs()).compareTo(b.scheduledTime.difference(now).abs()));
      targetEvent = due.first;
    }

    if (targetEvent != null) {
      await updateEventStatus(
        targetEvent.id, 
        MedicationStatus.medicationEventRecorded,
        source: 'IoT Device',
      );
      
      // Update weight cache for the container (1 to 4)
      final containerIdx = targetEvent.containerId - 1;
      if (containerIdx >= 0 && containerIdx < containers.length) {
        final currentWeight = containers[containerIdx].currentWeight;
        final targetNewWeight = (currentWeight - 0.5).clamp(0.0, 100.0);
        
        final idx = events.indexWhere((e) => e.id == targetEvent!.id);
        if (idx != -1) {
          events[idx] = events[idx].copyWith(
            weightBefore: currentWeight,
            weightAfter: targetNewWeight,
            weightChange: -0.5,
            deviceConfirmed: true,
          );
          await eventRepository.saveEvent(events[idx]);
          await loadEvents();
        }
        
        deviceService.simulateEvent(
          DeviceEvent.weightChanged, 
          containerId: targetEvent.containerId,
          weightChange: -0.5,
        );
      }
    }
  }

  void _triggerCaretakerAlerts(MedicationEvent event) {
    for (var caretaker in caretakers) {
      if (caretaker.notificationPreferences['missed_medication'] == true) {
        notificationService.showCaretakerAlert(
          caretaker, 
          event.medicineName, 
          event.scheduledTime.toLocal().toString(),
          event.containerId,
          event.timeSlot,
        );
      }
    }
  }
}
