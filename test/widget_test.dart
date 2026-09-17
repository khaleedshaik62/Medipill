import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medipill_monitor/core/app_state.dart';
import 'package:medipill_monitor/data/models/models.dart';
import 'package:medipill_monitor/data/repositories/repositories.dart';
import 'package:medipill_monitor/main.dart';
import 'package:medipill_monitor/services/auth/auth_service.dart';
import 'package:medipill_monitor/services/device/device_service.dart';
import 'package:medipill_monitor/services/medicine_image/medicine_image_service.dart';
import 'package:medipill_monitor/services/notifications/notification_service.dart';
import 'package:medipill_monitor/services/storage/local_persistence_service.dart';
import 'package:medipill_monitor/widgets/navigation_shell.dart';
import 'package:medipill_monitor/features/settings/settings_screen.dart';
import 'package:medipill_monitor/features/medicines/medicines_screen.dart';

void main() {
  group('MediPill Monitor Architecture & Safety Tests', () {
    late AppState state;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final authService = MockAuthService();
      final notificationService = MockNotificationService();
      final imageService = MockMedicineImageService();
      final deviceService = MockDeviceService();
      final medicineRepository = InMemoryMedicineRepository(
        initialMedicines: TestFixtures.sampleMedicines(),
      );
      final eventRepository = InMemoryEventRepository(
        initialEvents: TestFixtures.sampleEvents(),
      );
      final caretakerRepository = InMemoryCaretakerRepository(
        initialCaretakers: TestFixtures.sampleCaretakers(),
      );

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

  group('MediPill Monitor Authentication Flow Tests', () {
    late MockAuthService authService;
    late AppState state;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      authService = MockAuthService();
      state = AppState(
        authService: authService,
        notificationService: MockNotificationService(),
        imageService: MockMedicineImageService(),
        deviceService: MockDeviceService(),
        medicineRepository: InMemoryMedicineRepository(),
        eventRepository: InMemoryEventRepository(),
        caretakerRepository: InMemoryCaretakerRepository(),
      );
      await state.initialization;
    });

    test('AuthService: Valid seeded credentials authenticate successfully', () async {
      final user = await authService.login('john.doe@gmail.com', 'password123');
      expect(user.name, equals('John Doe'));
      expect(user.email, equals('john.doe@gmail.com'));
    });

    test('AuthService: Invalid password throws AuthException', () async {
      expect(
        () => authService.login('john.doe@gmail.com', 'wrongpassword'),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('Incorrect password'))),
      );
    });

    test('AuthService: Unknown email throws AuthException', () async {
      expect(
        () => authService.login('unknown@test.com', 'password123'),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', contains('No account found'))),
      );
    });

    test('AuthService: Sign Up stores account and allows subsequent login', () async {
      final newUser = await authService.signUp(
        name: 'Alice Smith',
        email: 'alice@example.com',
        password: 'securePass123',
        phone: '+1 555 1234',
      );
      expect(newUser.name, equals('Alice Smith'));
      expect(newUser.email, equals('alice@example.com'));

      await authService.logout();
      expect(await authService.getCurrentUser(), isNull);

      // Subsequent login with new credentials
      final loggedIn = await authService.login('alice@example.com', 'securePass123');
      expect(loggedIn.name, equals('Alice Smith'));
    });

    test('AppState: Login with valid credentials succeeds and clears errors', () async {
      final success = await state.login('john.doe@gmail.com', 'password123');
      expect(success, isTrue);
      expect(state.currentUser, isNotNull);
      expect(state.currentUser!.name, equals('John Doe'));
      expect(state.authErrorMessage, isNull);
    });

    test('AppState: Login with invalid credentials fails and sets authErrorMessage', () async {
      final success = await state.login('john.doe@gmail.com', 'wrongpassword');
      expect(success, isFalse);
      expect(state.currentUser, isNull);
      expect(state.authErrorMessage, isNotNull);
      expect(state.authErrorMessage, contains('Incorrect password'));
    });

    test('AppState: Logout clears user session and error state', () async {
      await state.login('john.doe@gmail.com', 'password123');
      expect(state.currentUser, isNotNull);

      await state.logout();
      expect(state.currentUser, isNull);
      expect(state.authErrorMessage, isNull);
    });

    testWidgets('UI Login: Valid credentials navigate to main app; Logout returns to Login', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        AppStateProvider(
          state: state,
          child: const MediPillApp(),
        ),
      );

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'john.doe@gmail.com');
      await tester.enterText(textFields.at(1), 'password123');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(state.currentUser, isNotNull);
      expect(find.text('Home'), findsWidgets);

      state.logout();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(state.currentUser, isNull);
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('UI Login: Invalid credentials show in-place error banner', (WidgetTester tester) async {
      await tester.pumpWidget(
        AppStateProvider(
          state: state,
          child: const MediPillApp(),
        ),
      );

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      // Enter invalid credentials
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'john.doe@gmail.com');
      await tester.enterText(textFields.at(1), 'wrongpass');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Login fails, error banner is shown, still on LoginScreen
      expect(state.currentUser, isNull);
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.textContaining('Incorrect password'), findsOneWidget);
    });

    testWidgets('UI SignUp: Registers account and navigates to main app', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        AppStateProvider(
          state: state,
          child: const MediPillApp(),
        ),
      );

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // Tap Create Account on WelcomeScreen
      await tester.tap(find.widgetWithText(OutlinedButton, 'Create Account'));
      await tester.pumpAndSettle();

      // Should be on SignUpScreen
      expect(find.text('Create Account'), findsWidgets);

      // Fill in signup fields: Name, Email, Phone, Password, Confirm Password
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Bob Martin');
      await tester.enterText(textFields.at(1), 'bob@example.com');
      await tester.enterText(textFields.at(2), '1234567890');
      await tester.enterText(textFields.at(3), 'secret123');
      await tester.enterText(textFields.at(4), 'secret123');
      await tester.pumpAndSettle();

      // Tap Agree & Register
      final registerButton = find.widgetWithText(ElevatedButton, 'Agree & Register');
      await tester.ensureVisible(registerButton);
      await tester.pumpAndSettle();
      await tester.tap(registerButton);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Successfully registered and authenticated into main app
      expect(state.currentUser, isNotNull);
      expect(state.currentUser!.name, equals('Bob Martin'));
      expect(find.text('Home'), findsWidgets);
    });

    testWidgets('UI Password Visibility Toggle: Toggles obscureText on LoginScreen', (WidgetTester tester) async {
      await tester.pumpWidget(
        AppStateProvider(
          state: state,
          child: const MediPillApp(),
        ),
      );

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      // Initially password field is obscured
      final editableTexts = find.byType(EditableText);
      final passwordEditableBefore = tester.widget<EditableText>(editableTexts.at(1));
      expect(passwordEditableBefore.obscureText, isTrue);

      // Tap visibility toggle icon
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      // Password field is now unobscured
      final passwordEditableAfter = tester.widget<EditableText>(editableTexts.at(1));
      expect(passwordEditableAfter.obscureText, isFalse);
    });
  });

  group('MediPill Clean Startup & Zero Demo Data Tests', () {
    late AppState cleanState;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      cleanState = AppState(
        authService: MockAuthService(seedTestAccount: true),
        notificationService: MockNotificationService(),
        imageService: MockMedicineImageService(),
        deviceService: MockDeviceService(),
        medicineRepository: InMemoryMedicineRepository(),
        eventRepository: InMemoryEventRepository(),
        caretakerRepository: InMemoryCaretakerRepository(),
      );
      await cleanState.initialization;
    });

    test('Unseeded startup has zero medicines, events, and caretakers', () {
      expect(cleanState.medicines, isEmpty);
      expect(cleanState.events, isEmpty);
      expect(cleanState.caretakers, isEmpty);
    });

    test('Device starts completely disconnected by default', () {
      expect(cleanState.deviceStatus!.isConnected, isFalse);
      expect(cleanState.deviceStatus!.isSimulated, isFalse);
      expect(cleanState.deviceStatus!.connectionStatusText, equals('Device not connected'));
      for (final container in cleanState.containers) {
        expect(container.currentWeight, equals(0.0));
      }
    });

    test('Simulation mode is clearly isolated and labeled when activated', () async {
      await cleanState.toggleSimulationMode(true);
      expect(cleanState.deviceStatus!.isSimulated, isTrue);
      expect(cleanState.deviceStatus!.connectionStatusText, equals('SIMULATED DEVICE — TESTING'));

      await cleanState.toggleSimulationMode(false);
      expect(cleanState.deviceStatus!.isConnected, isFalse);
      expect(cleanState.deviceStatus!.isSimulated, isFalse);
      expect(cleanState.deviceStatus!.connectionStatusText, equals('Device not connected'));
    });

    testWidgets('UI Clean State: Renders genuine empty states and no fabricated statistics', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      cleanState.currentUser = UserProfile(
        id: 'patient_test',
        name: 'John Doe',
        email: 'john.doe@gmail.com',
        phone: '+1 555 0199',
        role: UserRole.patient,
      );

      await tester.pumpWidget(
        AppStateProvider(
          state: cleanState,
          child: const MaterialApp(
            home: AdaptiveNavigationShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Home Screen empty states
      expect(find.text('No medication events recorded yet.'), findsOneWidget);
      expect(find.text('No medicines added yet.'), findsOneWidget);
      expect(find.text('Device not connected'), findsWidgets);

      // Fabricated demo statistics must NOT exist anywhere
      expect(find.text('18 / 21'), findsNothing);
      expect(find.text('86%'), findsNothing);
      expect(find.text('High Recording Rate'), findsNothing);
    });
  });

  group('MediPill Settings & Appearance Removal Tests', () {
    late AppState state;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      state = AppState(
        authService: MockAuthService(seedTestAccount: true),
        notificationService: MockNotificationService(),
        imageService: MockMedicineImageService(),
        deviceService: MockDeviceService(),
        medicineRepository: InMemoryMedicineRepository(),
        eventRepository: InMemoryEventRepository(),
        caretakerRepository: InMemoryCaretakerRepository(),
      );
      await state.initialization;
    });

    testWidgets('SettingsScreen has NO Appearance section, selectors, or dead rows', (WidgetTester tester) async {
      await tester.pumpWidget(
        AppStateProvider(
          state: state,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Appearance must be completely absent
      expect(find.text('Appearance'), findsNothing);
      expect(find.text('Theme Mode'), findsNothing);
      expect(find.text('Light / Dark / System'), findsNothing);
      expect(find.text('System Default'), findsNothing);
      expect(find.text('Dark Mode'), findsNothing);
      expect(find.text('Light Mode'), findsNothing);

      // Other real settings items MUST remain intact
      expect(find.text('Caretakers & Alerts configuration'), findsOneWidget);
      expect(find.text('Doctor Analytics Dashboard'), findsOneWidget);
      expect(find.text('ESP32 Device Settings'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });
  });

  group('MediPill Real Data Addition & Dynamic Schedule Tests', () {
    late AppState state;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      state = AppState(
        authService: MockAuthService(seedTestAccount: true),
        notificationService: MockNotificationService(),
        imageService: MockMedicineImageService(),
        deviceService: MockDeviceService(),
        medicineRepository: InMemoryMedicineRepository(),
        eventRepository: InMemoryEventRepository(),
        caretakerRepository: InMemoryCaretakerRepository(),
      );
      await state.initialization;
    });

    test('Adding medicine dynamically generates real 7-day Mon-Sun events across 4 containers', () async {
      expect(state.medicines, isEmpty);
      expect(state.events, isEmpty);

      final now = DateTime.now();
      final newMed = Medicine(
        id: 'med_real_1',
        name: 'Amoxicillin',
        strength: '500 mg',
        form: 'Capsule',
        dose: '1 Capsule',
        containerId: 1,
        timeSlot: 'Morning',
        frequency: 'Once daily',
        reminderTimes: ['08:00'],
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 7)),
        foodInstruction: 'After food',
        notes: 'Real patient medicine',
        active: true,
      );

      await state.addMedicine(newMed);

      expect(state.medicines.length, equals(1));
      expect(state.medicines.first.name, equals('Amoxicillin'));

      // Real events must now be populated
      expect(state.events.isNotEmpty, isTrue);
      for (final ev in state.events) {
        expect(ev.medicineName, equals('Amoxicillin'));
        expect(ev.containerId, equals(1));
        expect(ev.scheduledTime.weekday, inInclusiveRange(1, 7));
      }

      // Container 1 assigned medicines should reflect the added medicine
      final c1 = state.containers.firstWhere((c) => c.number == 1);
      expect(c1.assignedMedicineNames, contains('Amoxicillin'));
    });
  });

  group('MediPill Local Persistence Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('LocalPersistenceService saves and restores profile, medicines, caretakers, and simulation mode', () async {
      final persistence = LocalPersistenceService();

      final profile = UserProfile(
        id: 'p_101',
        name: 'Jane Doe',
        email: 'jane@example.com',
        phone: '+1 800 1234',
        role: UserRole.patient,
      );

      final now = DateTime.now();
      final med = Medicine(
        id: 'm_101',
        name: 'Metformin',
        strength: '850 mg',
        form: 'Tablet',
        dose: '1 Tablet',
        containerId: 2,
        timeSlot: 'Afternoon',
        frequency: 'Daily',
        reminderTimes: ['13:00'],
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
        foodInstruction: 'With food',
        active: true,
      );

      final caretaker = Caretaker(
        id: 'c_101',
        name: 'David Doe',
        relationship: 'Spouse',
        phone: '+1 800 5678',
        email: 'david@example.com',
        notificationPreferences: {
          'missed_medication': true,
          'medication_recorded': true,
        },
      );

      // Save to persistence
      await persistence.saveProfile(profile);
      await persistence.saveMedicines([med]);
      await persistence.saveCaretakers([caretaker]);
      await persistence.saveIsSimulatedDevice(true);

      // Re-create a fresh instance of persistence service to simulate app restart
      final freshPersistence = LocalPersistenceService();

      final loadedProfile = await freshPersistence.loadProfile();
      expect(loadedProfile, isNotNull);
      expect(loadedProfile!.name, equals('Jane Doe'));
      expect(loadedProfile.email, equals('jane@example.com'));

      final loadedMeds = await freshPersistence.loadMedicines();
      expect(loadedMeds.length, equals(1));
      expect(loadedMeds.first.name, equals('Metformin'));
      expect(loadedMeds.first.containerId, equals(2));

      final loadedCaretakers = await freshPersistence.loadCaretakers();
      expect(loadedCaretakers.length, equals(1));
      expect(loadedCaretakers.first.name, equals('David Doe'));

      final loadedSimMode = await freshPersistence.loadIsSimulatedDevice();
      expect(loadedSimMode, isTrue);
    });
  });

  group('MediPill Platform Adaptability Tests', () {
    late AppState state;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      state = AppState(
        authService: MockAuthService(seedTestAccount: true),
        notificationService: MockNotificationService(),
        imageService: MockMedicineImageService(),
        deviceService: MockDeviceService(),
        medicineRepository: InMemoryMedicineRepository(),
        eventRepository: InMemoryEventRepository(),
        caretakerRepository: InMemoryCaretakerRepository(),
      );
      await state.initialization;
      state.currentUser = UserProfile(
        id: 'patient_test',
        name: 'John Doe',
        email: 'john.doe@gmail.com',
        phone: '+1 555 0199',
        role: UserRole.patient,
      );
    });

    testWidgets('AdaptiveNavigationShell: Mobile screen (< 768px) displays BottomNavigationBar', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        AppStateProvider(
          state: state,
          child: const MaterialApp(
            home: AdaptiveNavigationShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('AdaptiveNavigationShell: Desktop screen (>= 768px) displays NavigationRail', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        AppStateProvider(
          state: state,
          child: const MaterialApp(
            home: AdaptiveNavigationShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
    });

    testWidgets('Desktop/Web: Camera scanning fallback dialog displays proper explanation', (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          AppStateProvider(
            state: state,
            child: const MaterialApp(
              home: Scaffold(
                body: MedicinesScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Add Medicine to open bottom sheet
        final addMedButton = find.widgetWithText(ElevatedButton, 'Add Medicine');
        expect(addMedButton, findsOneWidget);
        await tester.tap(addMedButton);
        await tester.pumpAndSettle();

        // Tap Scan Medicine Image
        final scanOption = find.text('Scan Medicine Image');
        expect(scanOption, findsOneWidget);
        await tester.tap(scanOption);
        await tester.pumpAndSettle();

        // Explanatory fallback dialog must be shown
        expect(find.text('Camera Scanning Unavailable'), findsOneWidget);
        expect(find.textContaining('Camera scanning is unavailable on this platform'), findsOneWidget);
        expect(find.widgetWithText(ElevatedButton, 'Enter Manually'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
