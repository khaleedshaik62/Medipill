import 'dart:async';
import '../../data/models/models.dart';

abstract class DeviceService {
  Future<DeviceStatus> getDeviceStatus();
  Future<void> syncMedicationPlan(List<Medicine> medicines);
  Future<void> triggerReminder(int containerId);
  Stream<DeviceEvent> get deviceEvents;
  Stream<List<PhysicalContainer>> get containerStateChanges;

  bool get isSimulated;
  void setSimulationMode(bool enabled);

  // Simulator APIs for testing & developer mode
  void simulateEvent(DeviceEvent event, {int? containerId, double? weightChange});
  List<PhysicalContainer> getContainers();
  void setDeviceConnected(bool connected);
}

class MockDeviceService implements DeviceService {
  final StreamController<DeviceEvent> _eventController = StreamController<DeviceEvent>.broadcast();
  final StreamController<List<PhysicalContainer>> _containerController = StreamController<List<PhysicalContainer>>.broadcast();

  bool _isConnected = false; // Physical ESP32 hardware connection
  bool _isSimulated = false;  // Developer simulation mode
  bool _isWifiConnected = false;
  List<PhysicalContainer> _containers = [];

  MockDeviceService({bool isSimulated = false}) : _isSimulated = isSimulated {
    _initContainers();
  }

  void _initContainers() {
    // Exactly the 4 physical containers, Morning, Afternoon, Evening, Night
    final slots = [
      {'id': 1, 'name': 'Container 1', 'slot': 'Morning'},
      {'id': 2, 'name': 'Container 2', 'slot': 'Afternoon'},
      {'id': 3, 'name': 'Container 3', 'slot': 'Evening'},
      {'id': 4, 'name': 'Container 4', 'slot': 'Night'},
    ];

    _containers = slots.map((s) {
      return PhysicalContainer(
        id: s['id'] as int,
        number: s['id'] as int,
        name: s['name'] as String,
        timeSlot: s['slot'] as String,
        assignedMedicineNames: [],
        currentWeight: 0.0,
        previousWeight: 0.0,
        inventoryStatus: 'Empty',
        estimatedRemaining: null,
        isOpen: false,
        sensorStatus: 'Normal',
        lastEvent: null,
      );
    }).toList();
  }

  @override
  bool get isSimulated => _isSimulated;

  @override
  void setSimulationMode(bool enabled) {
    _isSimulated = enabled;
    if (enabled) {
      _isWifiConnected = true;
      // In simulation mode, give test container initial simulation weight for testing if desired
      _eventController.add(DeviceEvent.deviceConnected);
    } else {
      _isWifiConnected = false;
      _eventController.add(DeviceEvent.deviceDisconnected);
    }
    _containerController.add(_containers);
  }

  @override
  Future<DeviceStatus> getDeviceStatus() async {
    final active = _isConnected || _isSimulated;
    return DeviceStatus(
      isConnected: _isConnected,
      isSimulated: _isSimulated,
      isWifiConnected: _isConnected || (_isSimulated && _isWifiConnected),
      lastSync: DateTime.now(),
      mechanismState: active ? MedicationContainerMechanismState.ready : MedicationContainerMechanismState.offline,
      buzzerReady: active,
      oledOnline: active,
      reedSensorsNormal: active,
      loadCellsConnected: active,
    );
  }

  @override
  Future<void> syncMedicationPlan(List<Medicine> medicines) async {
    // Map active medicines to the 4 physical containers
    final newContainers = List<PhysicalContainer>.from(_containers);
    for (int i = 0; i < 4; i++) {
      final containerNum = i + 1;
      final assigned = medicines
          .where((m) => m.containerId == containerNum && m.active)
          .map((m) => m.name)
          .toList();

      final currentWeight = newContainers[i].currentWeight;
      String status;
      if (assigned.isEmpty) {
        status = 'Empty';
      } else if (_isSimulated || _isConnected) {
        status = currentWeight > 10.0 ? 'Normal' : (currentWeight > 0.0 ? 'Low' : 'Empty');
      } else {
        // Real mode without connected hardware
        status = 'Configured';
      }

      newContainers[i] = newContainers[i].copyWith(
        assignedMedicineNames: assigned,
        inventoryStatus: status,
        estimatedRemaining: status == 'Empty' ? null : status,
      );
    }
    _containers = newContainers;
    _containerController.add(_containers);
  }

  @override
  Future<void> triggerReminder(int containerId) async {
    if (!_isConnected && !_isSimulated) return;
    simulateEvent(DeviceEvent.medicationEvent, containerId: containerId);
  }

  @override
  Stream<DeviceEvent> get deviceEvents => _eventController.stream;

  @override
  Stream<List<PhysicalContainer>> get containerStateChanges => _containerController.stream;

  @override
  List<PhysicalContainer> getContainers() => _containers;

  @override
  void setDeviceConnected(bool connected) {
    _isConnected = connected;
    _isWifiConnected = connected;
    _eventController.add(connected ? DeviceEvent.deviceConnected : DeviceEvent.deviceDisconnected);
  }

  @override
  void simulateEvent(DeviceEvent event, {int? containerId, double? weightChange}) {
    if (!_isSimulated && !_isConnected) return;

    if (containerId != null && containerId >= 1 && containerId <= 4) {
      final index = containerId - 1;
      final container = _containers[index];

      if (event == DeviceEvent.containerOpened) {
        _containers[index] = container.copyWith(
          isOpen: true,
          lastEvent: 'Container $containerId Opened',
        );
      } else if (event == DeviceEvent.containerClosed) {
        _containers[index] = container.copyWith(
          isOpen: false,
          lastEvent: 'Container $containerId Closed',
        );
      } else if (event == DeviceEvent.weightChanged && weightChange != null) {
        final newWeight = (container.currentWeight + weightChange).clamp(0.0, 100.0);
        String level = 'Empty';
        if (newWeight > 10.0) {
          level = 'Normal';
        } else if (newWeight > 0.0) {
          level = 'Low';
        }
        _containers[index] = container.copyWith(
          previousWeight: container.currentWeight,
          currentWeight: newWeight,
          inventoryStatus: level,
          estimatedRemaining: level,
          lastEvent: 'Weight Change: ${weightChange > 0 ? "+" : ""}${weightChange.toStringAsFixed(2)} g',
        );
      } else if (event == DeviceEvent.lowQuantity) {
        _containers[index] = container.copyWith(
          inventoryStatus: 'Low',
          estimatedRemaining: 'Low level warning',
          lastEvent: 'Low Level Warning Detected',
        );
      }

      _containerController.add(_containers);
    }
    _eventController.add(event);
  }
}
