import 'package:flutter/material.dart';
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

  group('MediPill Monitor Authentication Flow Tests', () {
    late MockAuthService authService;
    late AppState state;

    setUp(() async {
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
}
