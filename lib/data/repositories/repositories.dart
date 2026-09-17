import '../../data/models/models.dart';
import '../../services/storage/local_persistence_service.dart';

abstract class MedicineRepository {
  Future<List<Medicine>> getMedicines();
  Future<void> saveMedicine(Medicine medicine);
  Future<void> deleteMedicine(String id);
}

abstract class EventRepository {
  Future<List<MedicationEvent>> getEvents();
  Future<void> saveEvent(MedicationEvent event);
  Future<void> saveEvents(List<MedicationEvent> events);
  Future<void> clearAllEvents();
}

abstract class CaretakerRepository {
  Future<List<Caretaker>> getCaretakers();
  Future<void> saveCaretaker(Caretaker caretaker);
  Future<void> deleteCaretaker(String id);
}

class InMemoryMedicineRepository implements MedicineRepository {
  final List<Medicine> _medicines = [];
  final LocalPersistenceService? _persistenceService;

  InMemoryMedicineRepository({
    LocalPersistenceService? persistenceService,
    List<Medicine>? initialMedicines,
  }) : _persistenceService = persistenceService {
    if (initialMedicines != null && initialMedicines.isNotEmpty) {
      _medicines.addAll(initialMedicines);
    }
  }

  Future<void> init() async {
    if (_persistenceService != null) {
      final loaded = await _persistenceService.loadMedicines();
      if (loaded.isNotEmpty) {
        _medicines.clear();
        _medicines.addAll(loaded);
      }
    }
  }

  @override
  Future<List<Medicine>> getMedicines() async {
    return List.from(_medicines);
  }

  @override
  Future<void> saveMedicine(Medicine medicine) async {
    final idx = _medicines.indexWhere((m) => m.id == medicine.id);
    if (idx != -1) {
      _medicines[idx] = medicine;
    } else {
      _medicines.add(medicine);
    }
    if (_persistenceService != null) {
      await _persistenceService.saveMedicines(_medicines);
    }
  }

  @override
  Future<void> deleteMedicine(String id) async {
    _medicines.removeWhere((m) => m.id == id);
    if (_persistenceService != null) {
      await _persistenceService.saveMedicines(_medicines);
    }
  }
}

class InMemoryEventRepository implements EventRepository {
  final List<MedicationEvent> _events = [];
  final LocalPersistenceService? _persistenceService;

  InMemoryEventRepository({
    LocalPersistenceService? persistenceService,
    List<MedicationEvent>? initialEvents,
  }) : _persistenceService = persistenceService {
    if (initialEvents != null && initialEvents.isNotEmpty) {
      _events.addAll(initialEvents);
    }
  }

  Future<void> init() async {
    if (_persistenceService != null) {
      final loaded = await _persistenceService.loadEvents();
      if (loaded.isNotEmpty) {
        _events.clear();
        _events.addAll(loaded);
      }
    }
  }

  @override
  Future<List<MedicationEvent>> getEvents() async {
    return List.from(_events);
  }

  @override
  Future<void> saveEvent(MedicationEvent event) async {
    final idx = _events.indexWhere((e) => e.id == event.id);
    if (idx != -1) {
      _events[idx] = event;
    } else {
      _events.add(event);
    }
    if (_persistenceService != null) {
      await _persistenceService.saveEvents(_events);
    }
  }

  @override
  Future<void> saveEvents(List<MedicationEvent> events) async {
    for (var ev in events) {
      final idx = _events.indexWhere((e) => e.id == ev.id);
      if (idx != -1) {
        _events[idx] = ev;
      } else {
        _events.add(ev);
      }
    }
    if (_persistenceService != null) {
      await _persistenceService.saveEvents(_events);
    }
  }

  @override
  Future<void> clearAllEvents() async {
    _events.clear();
    if (_persistenceService != null) {
      await _persistenceService.saveEvents(_events);
    }
  }
}

class InMemoryCaretakerRepository implements CaretakerRepository {
  final List<Caretaker> _caretakers = [];
  final LocalPersistenceService? _persistenceService;

  InMemoryCaretakerRepository({
    LocalPersistenceService? persistenceService,
    List<Caretaker>? initialCaretakers,
  }) : _persistenceService = persistenceService {
    if (initialCaretakers != null && initialCaretakers.isNotEmpty) {
      _caretakers.addAll(initialCaretakers);
    }
  }

  Future<void> init() async {
    if (_persistenceService != null) {
      final loaded = await _persistenceService.loadCaretakers();
      if (loaded.isNotEmpty) {
        _caretakers.clear();
        _caretakers.addAll(loaded);
      }
    }
  }

  @override
  Future<List<Caretaker>> getCaretakers() async {
    return List.from(_caretakers);
  }

  @override
  Future<void> saveCaretaker(Caretaker caretaker) async {
    final idx = _caretakers.indexWhere((c) => c.id == caretaker.id);
    if (idx != -1) {
      _caretakers[idx] = caretaker;
    } else {
      _caretakers.add(caretaker);
    }
    if (_persistenceService != null) {
      await _persistenceService.saveCaretakers(_caretakers);
    }
  }

  @override
  Future<void> deleteCaretaker(String id) async {
    _caretakers.removeWhere((c) => c.id == id);
    if (_persistenceService != null) {
      await _persistenceService.saveCaretakers(_caretakers);
    }
  }
}

/// Test fixtures for automated test suites.
/// Isolated from normal application startup.
class TestFixtures {
  static List<Medicine> sampleMedicines() {
    final now = DateTime.now();
    return [
      Medicine(
        id: 'med_test_1',
        name: 'Test Medicine A',
        strength: '500 mg',
        form: 'Tablet',
        dose: '1 Tablet',
        containerId: 1,
        timeSlot: 'Morning',
        frequency: 'Three times daily',
        reminderTimes: ['08:00', '13:00', '20:00'],
        startDate: now.subtract(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 14)),
        foodInstruction: 'After food',
        notes: 'Test notes',
        active: true,
      ),
      Medicine(
        id: 'med_test_2',
        name: 'Test Medicine B',
        strength: '1000 IU',
        form: 'Capsule',
        dose: '1 Capsule',
        containerId: 1,
        timeSlot: 'Morning',
        frequency: 'Once daily',
        reminderTimes: ['08:00'],
        startDate: now.subtract(const Duration(days: 10)),
        endDate: now.add(const Duration(days: 20)),
        foodInstruction: 'With food',
        notes: 'Test notes',
        active: true,
      ),
      Medicine(
        id: 'med_test_3',
        name: 'Test Medicine C',
        strength: '500 mg',
        form: 'Tablet',
        dose: '1 Tablet',
        containerId: 3,
        timeSlot: 'Evening',
        frequency: 'Once daily',
        reminderTimes: ['20:00'],
        startDate: now.subtract(const Duration(days: 5)),
        endDate: now.add(const Duration(days: 30)),
        foodInstruction: 'With food',
        notes: 'Test notes',
        active: true,
      ),
    ];
  }

  static List<MedicationEvent> sampleEvents() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final List<MedicationEvent> events = [];

    // Cover all 7 days of the week across the 4 containers
    for (int day = 0; day < 7; day++) {
      final dayDate = monday.add(Duration(days: day));
      final containerId = (day % 4) + 1;
      final timeSlot = ['Morning', 'Afternoon', 'Evening', 'Night'][containerId - 1];
      final scheduledTime = DateTime(dayDate.year, dayDate.month, dayDate.day, 8 + (containerId * 3), 0);

      events.add(
        MedicationEvent(
          id: 'test_ev_$day',
          medicineId: 'med_test_1',
          medicineName: 'Test Medicine A',
          medicineStrength: '500 mg',
          medicineForm: 'Tablet',
          dose: '1 Tablet',
          scheduledTime: scheduledTime,
          eventTime: day < 3 ? scheduledTime.add(const Duration(minutes: 5)) : null,
          containerId: containerId,
          timeSlot: timeSlot,
          status: day < 3 ? MedicationStatus.medicationEventRecorded : MedicationStatus.scheduled,
          source: day < 3 ? 'Manual' : 'System',
          deviceConfirmed: false,
        ),
      );

      // Add a Container 1 event on multiple days to test container reuse across days
      if (containerId != 1) {
        final c1Time = DateTime(dayDate.year, dayDate.month, dayDate.day, 8, 0);
        events.add(
          MedicationEvent(
            id: 'test_c1_ev_$day',
            medicineId: 'med_test_2',
            medicineName: 'Test Medicine B',
            medicineStrength: '1000 IU',
            medicineForm: 'Capsule',
            dose: '1 Capsule',
            scheduledTime: c1Time,
            eventTime: null,
            containerId: 1,
            timeSlot: 'Morning',
            status: MedicationStatus.scheduled,
            source: 'System',
            deviceConfirmed: false,
          ),
        );
      }
    }
    return events;
  }

  static List<Caretaker> sampleCaretakers() {
    return [
      Caretaker(
        id: 'test_caretaker_1',
        name: 'Test Caretaker',
        relationship: 'Spouse',
        phone: '+1 555 9876',
        email: 'caretaker@test.net',
        notificationPreferences: {
          'missed_medication': true,
          'low_medicine_level': true,
          'device_offline': true,
          'medication_recorded': false,
        },
        missedThreshold: 1,
      ),
    ];
  }
}
