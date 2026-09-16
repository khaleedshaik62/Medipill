import 'dart:async';
import '../../data/models/models.dart';

abstract class DeviceService {
  Future<DeviceStatus> getDeviceStatus();
  Future<void> syncMedicationPlan(List<Medicine> medicines);
  Future<void> triggerReminder(int containerId);
  Stream<DeviceEvent> get deviceEvents;
  Stream<List<PhysicalContainer>> get containerStateChanges;

  // Simulator APIs for testing & demo
  void simulateEvent(DeviceEvent event, {int? containerId, double? weightChange});
  List<PhysicalContainer> getContainers();
  void setDeviceConnected(bool connected);
}

class MockDeviceService implements DeviceService {
  final StreamController<DeviceEvent> _eventController = StreamController<DeviceEvent>.broadcast();
  final StreamController<List<PhysicalContainer>> _containerController = StreamController<List<PhysicalContainer>>.broadcast();

  bool _isConnected = true;
  bool _isWifiConnected = true;
  List<PhysicalContainer> _containers = [];

  MockDeviceService() {
    // Populate EXACTLY the 4 physical containers
    final slots = [
      {'id': 1, 'name': 'Container 1', 'slot': 'Morning', 'weight': 14.5, 'status': 'Normal'},
      {'id': 2, 'name': 'Container 2', 'slot': 'Afternoon', 'weight': 5.2, 'status': 'Low'},
      {'id': 3, 'name': 'Container 3', 'slot': 'Evening', 'weight': 18.0, 'status': 'Normal'},
      {'id': 4, 'name': 'Container 4', 'slot': 'Night', 'weight': 0.0, 'status': 'Empty'},
    ];

    _containers = slots.map((s) {
      return PhysicalContainer(
        id: s['id'] as int,
        number: s['id'] as int,
        name: s['name'] as String,
        timeSlot: s['slot'] as String,
        assignedMedicineNames: [],
        currentWeight: s['weight'] as double,
        previousWeight: s['weight'] as double,
        inventoryStatus: s['status'] as String,
        estimatedRemaining: s['status'] == 'Empty' ? 'None' : (s['status'] == 'Low' ? 'Low level' : 'Normal level'),
        isOpen: false,
        sensorStatus: 'Normal',
        lastEvent: 'System Initialized',
      );
    }).toList();
  }

  @override
  Future<DeviceStatus> getDeviceStatus() async {
    return DeviceStatus(
      isConnected: _isConnected,
      isWifiConnected: _isWifiConnected,
      lastSync: DateTime.now().subtract(const Duration(minutes: 2)),
      mechanismState: _isConnected ? MedicationContainerMechanismState.ready : MedicationContainerMechanismState.offline,
      buzzerReady: _isConnected,
      oledOnline: _isConnected,
      reedSensorsNormal: _isConnected,
      loadCellsConnected: _isConnected,
    );
  }

  @override
  Future<void> syncMedicationPlan(List<Medicine> medicines) async {
    if (!_isConnected) return;
    
    // Map active medicines to the 4 physical containers
    final newContainers = List<PhysicalContainer>.from(_containers);
    for (int i = 0; i < 4; i++) {
      final containerNum = i + 1;
      final assigned = medicines
          .where((m) => m.containerId == containerNum && m.active)
          .map((m) => m.name)
          .toList();

      final currentWeight = newContainers[i].currentWeight;
      final status = assigned.isEmpty 
          ? 'Empty' 
          : (currentWeight > 10.0 ? 'Normal' : (currentWeight > 0.0 ? 'Low' : 'Empty'));

      newContainers[i] = newContainers[i].copyWith(
        assignedMedicineNames: assigned,
        inventoryStatus: status,
        estimatedRemaining: status == 'Empty' ? 'Empty' : (status == 'Low' ? 'Low' : 'Normal'),
      );
    }
    _containers = newContainers;
    _containerController.add(_containers);
  }

  @override
  Future<void> triggerReminder(int containerId) async {
    if (!_isConnected) return;
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
          estimatedRemaining: level == 'Empty' ? 'Empty' : (level == 'Low' ? 'Low' : 'Normal'),
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
