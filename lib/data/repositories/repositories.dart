import '../../data/models/models.dart';

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

  InMemoryMedicineRepository() {
    // Seed with initial sample medicines assigned to the 4 physical containers
    final now = DateTime.now();
    _medicines.addAll([
      Medicine(
        id: 'med_1',
        name: 'Paracetamol',
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
        notes: 'Take with plenty of water',
        active: true,
      ),
      Medicine(
        id: 'med_2',
        name: 'Vitamin D3',
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
        notes: 'Morning energy boost',
        active: true,
      ),
      Medicine(
        id: 'med_3',
        name: 'Metformin',
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
        notes: 'Take with evening meal',
        active: true,
      ),
    ]);
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
  }

  @override
  Future<void> deleteMedicine(String id) async {
    _medicines.removeWhere((m) => m.id == id);
  }
}

class InMemoryEventRepository implements EventRepository {
  final List<MedicationEvent> _events = [];

  InMemoryEventRepository() {
    // Generate realistic initial events for the current week (Monday to Sunday)
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    
    // Day 1: Monday - Paracetamol Morning
    final monMorning = DateTime(monday.year, monday.month, monday.day, 8, 0);
    _events.add(
      MedicationEvent(
        id: 'ev_1',
        medicineId: 'med_1',
        medicineName: 'Paracetamol',
        medicineStrength: '500 mg',
        medicineForm: 'Tablet',
        dose: '1 Tablet',
        scheduledTime: monMorning,
        eventTime: monMorning.add(const Duration(minutes: 6)),
        containerId: 1,
        timeSlot: 'Morning',
        status: MedicationStatus.medicationEventRecorded,
        source: 'IoT Device',
        weightBefore: 15.0,
        weightAfter: 14.5,
        weightChange: -0.5,
        deviceConfirmed: true,
      ),
    );

    // Day 1: Monday - Vitamin D Morning
    _events.add(
      MedicationEvent(
        id: 'ev_2',
        medicineId: 'med_2',
        medicineName: 'Vitamin D3',
        medicineStrength: '1000 IU',
        medicineForm: 'Capsule',
        dose: '1 Capsule',
        scheduledTime: monMorning,
        eventTime: monMorning.add(const Duration(minutes: 6)),
        containerId: 1,
        timeSlot: 'Morning',
        status: MedicationStatus.medicationEventRecorded,
        source: 'IoT Device',
        weightBefore: 14.5,
        weightAfter: 14.2,
        weightChange: -0.3,
        deviceConfirmed: true,
      ),
    );

    // Day 1: Monday - Paracetamol Afternoon
    final monAfternoon = DateTime(monday.year, monday.month, monday.day, 13, 0);
    _events.add(
      MedicationEvent(
        id: 'ev_3',
        medicineId: 'med_1',
        medicineName: 'Paracetamol',
        medicineStrength: '500 mg',
        medicineForm: 'Tablet',
        dose: '1 Tablet',
        scheduledTime: monAfternoon,
        eventTime: monAfternoon.add(const Duration(minutes: 12)),
        containerId: 2,
        timeSlot: 'Afternoon',
        status: MedicationStatus.medicationEventRecorded,
        source: 'Mobile',
        deviceConfirmed: false,
      ),
    );

    // Day 2: Tuesday - Paracetamol Morning
    final tueMorning = monMorning.add(const Duration(days: 1));
    _events.add(
      MedicationEvent(
        id: 'ev_4',
        medicineId: 'med_1',
        medicineName: 'Paracetamol',
        medicineStrength: '500 mg',
        medicineForm: 'Tablet',
        dose: '1 Tablet',
        scheduledTime: tueMorning,
        eventTime: tueMorning.add(const Duration(minutes: 4)),
        containerId: 1,
        timeSlot: 'Morning',
        status: MedicationStatus.medicationEventRecorded,
        source: 'IoT Device',
        weightBefore: 14.2,
        weightAfter: 13.7,
        weightChange: -0.5,
        deviceConfirmed: true,
      ),
    );

    // Day 2: Tuesday - Afternoon Unconfirmed
    final tueAfternoon = monAfternoon.add(const Duration(days: 1));
    _events.add(
      MedicationEvent(
        id: 'ev_5',
        medicineId: 'med_1',
        medicineName: 'Paracetamol',
        medicineStrength: '500 mg',
        medicineForm: 'Tablet',
        dose: '1 Tablet',
        scheduledTime: tueAfternoon,
        eventTime: null,
        containerId: 2,
        timeSlot: 'Afternoon',
        status: MedicationStatus.unconfirmed,
        source: 'System',
        deviceConfirmed: false,
      ),
    );

    // Day 3: Wednesday - Morning
    final wedMorning = monMorning.add(const Duration(days: 2));
    _events.add(
      MedicationEvent(
        id: 'ev_6',
        medicineId: 'med_1',
        medicineName: 'Paracetamol',
        medicineStrength: '500 mg',
        medicineForm: 'Tablet',
        dose: '1 Tablet',
        scheduledTime: wedMorning,
        eventTime: wedMorning.add(const Duration(minutes: 2)),
        containerId: 1,
        timeSlot: 'Morning',
        status: MedicationStatus.medicationEventRecorded,
        source: 'IoT Device',
        weightBefore: 13.7,
        weightAfter: 13.2,
        weightChange: -0.5,
        deviceConfirmed: true,
      ),
    );

    // Today / Upcoming slots
    final today = DateTime(now.year, now.month, now.day, 20, 0);
    _events.add(
      MedicationEvent(
        id: 'ev_7',
        medicineId: 'med_3',
        medicineName: 'Metformin',
        medicineStrength: '500 mg',
        medicineForm: 'Tablet',
        dose: '1 Tablet',
        scheduledTime: today,
        eventTime: null,
        containerId: 3,
        timeSlot: 'Evening',
        status: now.hour >= 20 ? MedicationStatus.due : MedicationStatus.scheduled,
        source: 'System',
        deviceConfirmed: false,
      ),
    );
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
  }

  @override
  Future<void> saveEvents(List<MedicationEvent> events) async {
    for (var ev in events) {
      await saveEvent(ev);
    }
  }

  @override
  Future<void> clearAllEvents() async {
    _events.clear();
  }
}

class InMemoryCaretakerRepository implements CaretakerRepository {
  final List<Caretaker> _caretakers = [];

  InMemoryCaretakerRepository() {
    _caretakers.add(
      Caretaker(
        id: 'caretaker_1',
        name: 'Sarah Connor',
        relationship: 'Spouse',
        phone: '+1 555 9876',
        email: 'sarah.c@medicare.net',
        notificationPreferences: {
          'missed_medication': true,
          'low_medicine_level': true,
          'device_offline': true,
          'medication_recorded': false, // Disabled by default per master requirements
        },
        missedThreshold: 1,
      ),
    );
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
  }

  @override
  Future<void> deleteCaretaker(String id) async {
    _caretakers.removeWhere((c) => c.id == id);
  }
}
