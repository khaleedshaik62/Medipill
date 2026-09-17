/// Represents user roles for the app
enum UserRole {
  patient,
  caretaker,
  doctor,
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final String? dob;
  final UserRole role;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
    this.dob,
    this.role = UserRole.patient,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'dob': dob,
      'role': role.index,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      profileImage: map['profileImage'],
      dob: map['dob'],
      role: UserRole.values[map['role'] ?? 0],
    );
  }
}

class Medicine {
  final String id;
  final String name;
  final String strength;
  final String form;
  final String dose;
  final int containerId; // EXACTLY 1 to 4
  final String timeSlot; // "Morning", "Afternoon", "Evening", "Night"
  final String frequency; // e.g. "Once daily", "Twice daily", "Three times daily", "Four times daily", "Custom"
  final List<String> reminderTimes; // list of "HH:MM" 24h formats
  final DateTime startDate;
  final DateTime endDate;
  final String foodInstruction; // "Before food", "After food", "With food", "Any time", "Not specified"
  final String? notes;
  final bool active;

  Medicine({
    required this.id,
    required this.name,
    required this.strength,
    required this.form,
    required this.dose,
    required this.containerId,
    required this.timeSlot,
    required this.frequency,
    required this.reminderTimes,
    required this.startDate,
    required this.endDate,
    required this.foodInstruction,
    this.notes,
    this.active = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'strength': strength,
      'form': form,
      'dose': dose,
      'containerId': containerId,
      'timeSlot': timeSlot,
      'frequency': frequency,
      'reminderTimes': reminderTimes,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'foodInstruction': foodInstruction,
      'notes': notes,
      'active': active,
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      strength: map['strength'] ?? '',
      form: map['form'] ?? '',
      dose: map['dose'] ?? '',
      containerId: map['containerId'] ?? 1,
      timeSlot: map['timeSlot'] ?? 'Morning',
      frequency: map['frequency'] ?? 'Once daily',
      reminderTimes: List<String>.from(map['reminderTimes'] ?? []),
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      foodInstruction: map['foodInstruction'] ?? 'Not specified',
      notes: map['notes'],
      active: map['active'] ?? true,
    );
  }
}

class MedicineDraft {
  final String? name;
  final String? strength;
  final String? form;
  final String? dose;
  final int? containerId;
  final String? timeSlot;
  final String? frequency;
  final List<String>? reminderTimes;
  final String? foodInstruction;
  final String? durationDays;
  final String? notes;

  MedicineDraft({
    this.name,
    this.strength,
    this.form,
    this.dose,
    this.containerId,
    this.timeSlot,
    this.frequency,
    this.reminderTimes,
    this.foodInstruction,
    this.durationDays,
    this.notes,
  });
}

enum MedicationStatus {
  scheduled,
  due,
  interactionDetected,
  weightChangeDetected,
  medicationEventRecorded, // Completed
  unconfirmed,
  missed,
  snoozed,
}

class MedicationEvent {
  final String id;
  final String medicineId;
  final String medicineName;
  final String medicineStrength;
  final String medicineForm;
  final String dose;
  final DateTime scheduledTime;
  final DateTime? eventTime;
  final int containerId; // 1 to 4
  final String timeSlot; // "Morning", "Afternoon", "Evening", "Night"
  final MedicationStatus status;
  final String source; // "Manual", "Mobile", "IoT Device"
  final double? weightBefore;
  final double? weightAfter;
  final double? weightChange;
  final bool deviceConfirmed;

  MedicationEvent({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.medicineStrength,
    required this.medicineForm,
    required this.dose,
    required this.scheduledTime,
    this.eventTime,
    required this.containerId,
    required this.timeSlot,
    required this.status,
    required this.source,
    this.weightBefore,
    this.weightAfter,
    this.weightChange,
    this.deviceConfirmed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'medicineStrength': medicineStrength,
      'medicineForm': medicineForm,
      'dose': dose,
      'scheduledTime': scheduledTime.toIso8601String(),
      'eventTime': eventTime?.toIso8601String(),
      'containerId': containerId,
      'timeSlot': timeSlot,
      'status': status.index,
      'source': source,
      'weightBefore': weightBefore,
      'weightAfter': weightAfter,
      'weightChange': weightChange,
      'deviceConfirmed': deviceConfirmed,
    };
  }

  factory MedicationEvent.fromMap(Map<String, dynamic> map) {
    return MedicationEvent(
      id: map['id'] ?? '',
      medicineId: map['medicineId'] ?? '',
      medicineName: map['medicineName'] ?? '',
      medicineStrength: map['medicineStrength'] ?? '',
      medicineForm: map['medicineForm'] ?? '',
      dose: map['dose'] ?? '',
      scheduledTime: DateTime.parse(map['scheduledTime']),
      eventTime: map['eventTime'] != null ? DateTime.parse(map['eventTime']) : null,
      containerId: map['containerId'] ?? 1,
      timeSlot: map['timeSlot'] ?? 'Morning',
      status: MedicationStatus.values[map['status'] ?? 0],
      source: map['source'] ?? 'Manual',
      weightBefore: map['weightBefore']?.toDouble(),
      weightAfter: map['weightAfter']?.toDouble(),
      weightChange: map['weightChange']?.toDouble(),
      deviceConfirmed: map['deviceConfirmed'] ?? false,
    );
  }

  MedicationEvent copyWith({
    MedicationStatus? status,
    DateTime? eventTime,
    String? source,
    double? weightBefore,
    double? weightAfter,
    double? weightChange,
    bool? deviceConfirmed,
  }) {
    return MedicationEvent(
      id: id,
      medicineId: medicineId,
      medicineName: medicineName,
      medicineStrength: medicineStrength,
      medicineForm: medicineForm,
      dose: dose,
      scheduledTime: scheduledTime,
      eventTime: eventTime ?? this.eventTime,
      containerId: containerId,
      timeSlot: timeSlot,
      status: status ?? this.status,
      source: source ?? this.source,
      weightBefore: weightBefore ?? this.weightBefore,
      weightAfter: weightAfter ?? this.weightAfter,
      weightChange: weightChange ?? this.weightChange,
      deviceConfirmed: deviceConfirmed ?? this.deviceConfirmed,
    );
  }
}

class Caretaker {
  final String id;
  final String name;
  final String relationship; // e.g. "Parent", "Child", "Spouse", "Guardian", "Caregiver", "Other"
  final String phone;
  final String email;
  final Map<String, bool> notificationPreferences;
  final int missedThreshold; // Threshold in number of missed events before alerting (1, 2, 3...)

  Caretaker({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phone,
    required this.email,
    required this.notificationPreferences,
    this.missedThreshold = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'phone': phone,
      'email': email,
      'notificationPreferences': notificationPreferences,
      'missedThreshold': missedThreshold,
    };
  }

  factory Caretaker.fromMap(Map<String, dynamic> map) {
    return Caretaker(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      relationship: map['relationship'] ?? 'Other',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      notificationPreferences: Map<String, bool>.from(map['notificationPreferences'] ?? {}),
      missedThreshold: map['missedThreshold'] ?? 1,
    );
  }
}

class DoctorProfile {
  final String id;
  final String name;
  final String email;
  final String specialty;
  final String phone;

  DoctorProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.specialty,
    required this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'specialty': specialty,
      'phone': phone,
    };
  }

  factory DoctorProfile.fromMap(Map<String, dynamic> map) {
    return DoctorProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      specialty: map['specialty'] ?? '',
      phone: map['phone'] ?? '',
    );
  }
}

/// Abstract representation of the physical servo/dispensing mechanism
enum MedicationContainerMechanismState {
  ready,
  offline,
  error,
  active,
}

/// Represents one of exactly 4 physical medicine containers
class PhysicalContainer {
  final int id; // 1, 2, 3, 4
  final int number; // 1, 2, 3, 4
  final String name; // e.g. "Container 1"
  final String timeSlot; // "Morning", "Afternoon", "Evening", "Night"
  final List<String> assignedMedicineNames;
  final double currentWeight; // In grams
  final double previousWeight; // In grams
  final String inventoryStatus; // "Normal", "Low", "Empty"
  final String? estimatedRemaining;
  final bool isOpen;
  final String sensorStatus; // "Normal", "Calibrating", "Error"
  final String? lastEvent;

  PhysicalContainer({
    required this.id,
    required this.number,
    required this.name,
    required this.timeSlot,
    this.assignedMedicineNames = const [],
    this.currentWeight = 0.0,
    this.previousWeight = 0.0,
    this.inventoryStatus = 'Empty',
    this.estimatedRemaining,
    this.isOpen = false,
    this.sensorStatus = 'Normal',
    this.lastEvent,
  });

  PhysicalContainer copyWith({
    List<String>? assignedMedicineNames,
    double? currentWeight,
    double? previousWeight,
    String? inventoryStatus,
    String? estimatedRemaining,
    bool? isOpen,
    String? sensorStatus,
    String? lastEvent,
  }) {
    return PhysicalContainer(
      id: id,
      number: number,
      name: name,
      timeSlot: timeSlot,
      assignedMedicineNames: assignedMedicineNames ?? this.assignedMedicineNames,
      currentWeight: currentWeight ?? this.currentWeight,
      previousWeight: previousWeight ?? this.previousWeight,
      inventoryStatus: inventoryStatus ?? this.inventoryStatus,
      estimatedRemaining: estimatedRemaining ?? this.estimatedRemaining,
      isOpen: isOpen ?? this.isOpen,
      sensorStatus: sensorStatus ?? this.sensorStatus,
      lastEvent: lastEvent ?? this.lastEvent,
    );
  }
}

enum DeviceEvent {
  deviceConnected,
  deviceDisconnected,
  containerOpened,
  containerClosed,
  weightChanged,
  lowQuantity,
  medicationEvent,
  sensorError,
}

class DeviceStatus {
  final bool isConnected;
  final bool isSimulated;
  final bool isWifiConnected;
  final DateTime lastSync;
  final MedicationContainerMechanismState mechanismState;
  final bool buzzerReady;
  final bool oledOnline;
  final bool reedSensorsNormal; // 4 sensors
  final bool loadCellsConnected; // 4 load cells

  DeviceStatus({
    this.isConnected = false,
    this.isSimulated = false,
    this.isWifiConnected = false,
    required this.lastSync,
    this.mechanismState = MedicationContainerMechanismState.ready,
    this.buzzerReady = false,
    this.oledOnline = false,
    this.reedSensorsNormal = false,
    this.loadCellsConnected = false,
  });

  String get connectionStatusText {
    if (isSimulated) return 'SIMULATED DEVICE — TESTING';
    if (isConnected) return 'Connected';
    return 'Device not connected';
  }
}
