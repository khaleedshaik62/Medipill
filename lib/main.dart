import 'package:flutter/material.dart';
import 'core/app_state.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/repositories.dart';
import 'features/auth/auth_screens.dart';
import 'services/auth/auth_service.dart';
import 'services/device/device_service.dart';
import 'services/medicine_image/medicine_image_service.dart';
import 'services/notifications/notification_service.dart';
import 'widgets/navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Instantiate dependencies
  final authService = MockAuthService();
  final notificationService = MockNotificationService();
  final imageService = MockMedicineImageService();
  final deviceService = MockDeviceService();

  final medicineRepository = InMemoryMedicineRepository();
  final eventRepository = InMemoryEventRepository();
  final caretakerRepository = InMemoryCaretakerRepository();

  // Instantiate app state provider coordinating everything
  final appState = AppState(
    authService: authService,
    notificationService: notificationService,
    imageService: imageService,
    deviceService: deviceService,
    medicineRepository: medicineRepository,
    eventRepository: eventRepository,
    caretakerRepository: caretakerRepository,
  );

  // Initialize notifications
  await notificationService.initialize();

  runApp(
    AppStateProvider(
      state: appState,
      child: const MediPillApp(),
    ),
  );
}

class AppStateProvider extends StatefulWidget {
  final AppState state;
  final Widget child;
  const AppStateProvider({super.key, required this.state, required this.child});

  @override
  State<AppStateProvider> createState() => AppStateProviderState();
}

class AppStateProviderState extends State<AppStateProvider> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class MediPillApp extends StatefulWidget {
  const MediPillApp({super.key});

  @override
  State<MediPillApp> createState() => _MediPillAppState();
}

class _MediPillAppState extends State<MediPillApp> {
  bool _showSplash = true;
  bool _isWelcome = true;
  bool _isSignUp = false;

  @override
  Widget build(BuildContext context) {
    // Lookup AppState from higher context
    final state = context.findAncestorStateOfType<AppStateProviderState>()?.widget.state;
    if (state == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: Center(child: Text('AppState missing'))),
      );
    }

    return ListenableBuilder(
      listenable: state,
      builder: (context, child) {
        final isLoggedIn = state.currentUser != null;

        Widget screen = const Scaffold(body: Center(child: CircularProgressIndicator()));

        if (_showSplash) {
          screen = SplashScreen(
            onFinish: () {
              setState(() {
                _showSplash = false;
              });
            },
          );
        } else if (!isLoggedIn) {
          if (_isWelcome) {
            screen = WelcomeScreen(
              onLogin: () {
                setState(() {
                  _isWelcome = false;
                  _isSignUp = false;
                });
              },
              onSignUp: () {
                setState(() {
                  _isWelcome = false;
                  _isSignUp = true;
                });
              },
            );
          } else if (_isSignUp) {
            screen = SignUpScreen(
              onBack: () {
                setState(() {
                  _isWelcome = true;
                });
              },
              onSignUpPressed: (name, email, phone, dob) {
                state.signUp(name, email, phone, dob);
              },
              isLoading: state.isLoading,
            );
          } else {
            screen = LoginScreen(
              onBack: () {
                setState(() {
                  _isWelcome = true;
                });
              },
              onLoginPressed: (email, password) {
                state.login(email, password);
              },
              isLoading: state.isLoading,
            );
          }
        } else {
          // Logged in shell
          screen = const AdaptiveNavigationShell();
        }

        return MaterialApp(
          title: 'MediPill Monitor',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: screen,
        );
      },
    );
  }
}
