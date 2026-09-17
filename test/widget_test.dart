import 'package:flutter_test/flutter_test.dart';
import 'package:medipill_monitor/core/app_state.dart';
import 'package:medipill_monitor/data/models/models.dart';
import 'package:medipill_monitor/data/repositories/repositories.dart';
import 'package:medipill_monitor/main.dart';
import 'package:medipill_monitor/services/auth/auth_service.dart';
import 'package:medipill_monitor/services/device/device_service.dart';
import 'package:medipill_monitor/services/medicine_image/medicine_image_service.dart';
import 'package:medipill_monitor/services/notifications/notification_service.dart';

void main() {
  group('MediPill Monitor Architecture & Safety Tests', () {
    late AppState state;

    setUp(() async {
      final authService = MockAuthService();
      final notificationService = MockNotificationService();
      final imageService = MockMedicineImageService();
      final deviceService = MockDeviceService();
      final medicineRepository = InMemoryMedicineRepository();
      final eventRepository = InMemoryEventRepository();
      final caretakerRepository = InMemoryCaretakerRepository();

      state = AppState(
        authService: authService,
        notificationService: notificationService,
        imageService: imageService,
        deviceService: deviceService,
        medicineRepository: medicineRepository,
        eventRepository: eventRepository,
        caretakerRepository: caretakerRepository,
      );
      await state.initialization;
    });

    test('Hardware Constraint: Device must have exactly 4 physical containers', () {
      expect(state.containers.length, equals(4));
      final containerNumbers = state.containers.map((c) => c.number).toList();
      expect(containerNumbers, containsAll([1, 2, 3, 4]));
      expect(containerNumbers.contains(5), isFalse);
      expect(containerNumbers.contains(6), isFalse);
      expect(containerNumbers.contains(7), isFalse);
    });

    test('Hardware Constraint: 4 containers map to 4 time slots', () {
      final slots = state.containers.map((c) => c.timeSlot).toList();
      expect(slots, containsAll(['Morning', 'Afternoon', 'Evening', 'Night']));
    });

    test('Medical Safety: Event status distinguishes recorded from ingestion', () {
      // Must support recorded, unconfirmed, missed, snoozed
      expect(MedicationStatus.values, contains(MedicationStatus.medicationEventRecorded));
      expect(MedicationStatus.values, contains(MedicationStatus.unconfirmed));
      expect(MedicationStatus.values, contains(MedicationStatus.missed));
    });

    test('Schedule Model: Week covers Monday to Sunday across 4 containers', () {
      expect(state.events.isNotEmpty, isTrue);
      final daysPresent = state.events.map((e) => e.scheduledTime.weekday).toSet();
      // Must cover all 7 days of week (1 = Monday ... 7 = Sunday)
      expect(daysPresent, containsAll([1, 2, 3, 4, 5, 6, 7]));

      for (final event in state.events) {
        // Every event must reference a container between 1 and 4
        expect(event.containerId, inInclusiveRange(1, 4));
        expect(event.containerId, isNot(greaterThan(4)));
      }
    });

    test('Reusable Containers: Same physical container is reused across multiple days of the week', () {
      // Find events assigned to Container 1
      final container1Events = state.events.where((e) => e.containerId == 1).toList();
      expect(container1Events.isNotEmpty, isTrue);

      // Verify Container 1 is scheduled on multiple distinct days (e.g., Monday through Sunday)
      final c1Days = container1Events.map((e) => e.scheduledTime.weekday).toSet();
      expect(c1Days.length, greaterThan(1));
    });

    test('Caretaker Terminology: Alerts use observable event language without ingestion claims', () {
      final preferences = state.caretakers.first.notificationPreferences;
      expect(preferences.containsKey('missed_medication'), isTrue);
      expect(preferences.containsKey('medication_recorded'), isTrue);
    });

    testWidgets('App Startup & Splash Screen Smoke Test', (WidgetTester tester) async {
      await tester.pumpWidget(
        AppStateProvider(
          state: state,
          child: const MediPillApp(),
        ),
      );

      // Splash screen should render MediPill Monitor title
      expect(find.text('MediPill Monitor'), findsWidgets);

      // Advance timer to allow splash to finish smoothly
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.text('Your Smarter Medication Partner'), findsOneWidget);
    });
  });
}
