import 'dart:async';
import '../../data/models/models.dart';

abstract class AuthService {
  Future<UserProfile?> getCurrentUser();
  Future<UserProfile> login(String email, String password);
  Future<UserProfile> signUp(String name, String email, String phone, String? dob);
  Future<void> updateProfile(UserProfile profile);
  Future<void> logout();
  Stream<UserProfile?> get authStateChanges;
}

class MockAuthService implements AuthService {
  final StreamController<UserProfile?> _controller = StreamController<UserProfile?>.broadcast();
  UserProfile? _currentUser;

  MockAuthService() {
    // Initial state is logged out for fresh startup demo
    _currentUser = null;
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _currentUser;
  }

  @override
  Future<UserProfile> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUser = UserProfile(
      id: 'patient_123',
      name: 'John Doe',
      email: email,
      phone: '+1 555 0199',
      dob: '1975-06-15',
      role: UserRole.patient,
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserProfile> signUp(String name, String email, String phone, String? dob) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _currentUser = UserProfile(
      id: 'patient_123',
      name: name,
      email: email,
      phone: phone,
      dob: dob,
      role: UserRole.patient,
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = profile;
    _controller.add(_currentUser);
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Stream<UserProfile?> get authStateChanges => _controller.stream;
}
