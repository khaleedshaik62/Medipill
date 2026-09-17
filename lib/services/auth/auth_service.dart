import 'dart:async';
import '../../data/models/models.dart';
import '../storage/local_persistence_service.dart';

abstract class AuthService {
  Future<UserProfile?> getCurrentUser();
  Future<UserProfile> login(String email, String password);
  Future<UserProfile> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? dob,
  });
  Future<void> updateProfile(UserProfile profile);
  Future<void> logout();
  Stream<UserProfile?> get authStateChanges;
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

class UserAccount {
  final UserProfile profile;
  final String password;

  UserAccount({
    required this.profile,
    required this.password,
  });
}

class MockAuthService implements AuthService {
  final StreamController<UserProfile?> _controller = StreamController<UserProfile?>.broadcast();
  UserProfile? _currentUser;
  final LocalPersistenceService? _persistenceService;

  // In-memory accounts store keyed by normalized email
  final Map<String, UserAccount> _accounts = {};

  MockAuthService({
    LocalPersistenceService? persistenceService,
    bool seedTestAccount = true,
  }) : _persistenceService = persistenceService {
    if (seedTestAccount) {
      _seedDefaultAccount();
    }
    _currentUser = null;
  }

  Future<void> init() async {
    if (_persistenceService != null) {
      final savedAccounts = await _persistenceService.loadAccounts();
      for (final entry in savedAccounts.entries) {
        final profile = UserProfile.fromMap(Map<String, dynamic>.from(entry.value['profile'] as Map));
        final password = entry.value['password'] as String;
        _accounts[entry.key] = UserAccount(profile: profile, password: password);
      }
      final savedProfile = await _persistenceService.loadProfile();
      if (savedProfile != null) {
        _currentUser = savedProfile;
        _controller.add(_currentUser);
      }
    }
  }

  void _seedDefaultAccount() {
    final demoUser = UserProfile(
      id: 'patient_demo_1',
      name: 'John Doe',
      email: 'john.doe@gmail.com',
      phone: '+1 555 0199',
      dob: '1975-06-15',
      role: UserRole.patient,
    );
    _accounts['john.doe@gmail.com'] = UserAccount(
      profile: demoUser,
      password: 'password123',
    );
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<UserProfile> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final normalizedEmail = email.trim().toLowerCase();
    final trimmedPassword = password.trim();

    if (normalizedEmail.isEmpty) {
      throw const AuthException('Email address is required.');
    }
    if (trimmedPassword.isEmpty) {
      throw const AuthException('Password is required.');
    }

    final account = _accounts[normalizedEmail];
    if (account == null) {
      throw const AuthException('No account found with this email. Please check your credentials or create an account.');
    }

    if (account.password != trimmedPassword) {
      throw const AuthException('Incorrect password. Please verify and try again.');
    }

    _currentUser = account.profile;
    if (_persistenceService != null) {
      await _persistenceService.saveProfile(_currentUser!);
    }
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserProfile> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? dob,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final normalizedEmail = email.trim().toLowerCase();
    final trimmedPassword = password.trim();

    if (name.trim().isEmpty) {
      throw const AuthException('Full name is required.');
    }
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw const AuthException('A valid email address is required.');
    }
    if (trimmedPassword.length < 6) {
      throw const AuthException('Password must be at least 6 characters long.');
    }

    if (_accounts.containsKey(normalizedEmail)) {
      throw const AuthException('An account with this email already exists. Please log in instead.');
    }

    final newProfile = UserProfile(
      id: 'patient_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: normalizedEmail,
      phone: phone.trim(),
      dob: dob,
      role: UserRole.patient,
    );

    _accounts[normalizedEmail] = UserAccount(
      profile: newProfile,
      password: trimmedPassword,
    );

    _currentUser = newProfile;
    if (_persistenceService != null) {
      await _persistenceService.saveProfile(_currentUser!);
      final accountsMap = _accounts.map(
        (k, v) => MapEntry(k, {
          'profile': v.profile.toMap(),
          'password': v.password,
        }),
      );
      await _persistenceService.saveAccounts(accountsMap);
    }
    _controller.add(_currentUser);
    return newProfile;
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _currentUser = profile;
    final normalizedEmail = profile.email.trim().toLowerCase();
    if (_accounts.containsKey(normalizedEmail)) {
      final existing = _accounts[normalizedEmail]!;
      _accounts[normalizedEmail] = UserAccount(profile: profile, password: existing.password);
    }
    if (_persistenceService != null) {
      await _persistenceService.saveProfile(profile);
      final accountsMap = _accounts.map(
        (k, v) => MapEntry(k, {
          'profile': v.profile.toMap(),
          'password': v.password,
        }),
      );
      await _persistenceService.saveAccounts(accountsMap);
    }
    _controller.add(_currentUser);
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 50));
    _currentUser = null;
    if (_persistenceService != null) {
      await _persistenceService.clearProfile();
    }
    _controller.add(null);
  }

  @override
  Stream<UserProfile?> get authStateChanges => _controller.stream;
}
