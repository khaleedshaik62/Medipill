import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/models.dart';

class LocalPersistenceService {
  static const String _keyProfile = 'medipill_profile';
  static const String _keyMedicines = 'medipill_medicines';
  static const String _keyEvents = 'medipill_events';
  static const String _keyCaretakers = 'medipill_caretakers';
  static const String _keySimulatedDevice = 'medipill_simulated_device';
  static const String _keyAccounts = 'medipill_accounts';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Profile persistence
  Future<UserProfile?> loadProfile() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_keyProfile);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserProfile.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyProfile, jsonEncode(profile.toMap()));
  }

  Future<void> clearProfile() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyProfile);
  }

  // Accounts persistence (for auth service user retention)
  Future<Map<String, Map<String, dynamic>>> loadAccounts() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_keyAccounts);
    if (jsonStr == null || jsonStr.isEmpty) return {};
    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveAccounts(Map<String, Map<String, dynamic>> accounts) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyAccounts, jsonEncode(accounts));
  }

  // Medicines persistence
  Future<List<Medicine>> loadMedicines() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_keyMedicines);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((item) => Medicine.fromMap(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMedicines(List<Medicine> medicines) async {
    final prefs = await _getPrefs();
    final list = medicines.map((m) => m.toMap()).toList();
    await prefs.setString(_keyMedicines, jsonEncode(list));
  }

  // Medication Events persistence
  Future<List<MedicationEvent>> loadEvents() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_keyEvents);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((item) => MedicationEvent.fromMap(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveEvents(List<MedicationEvent> events) async {
    final prefs = await _getPrefs();
    final list = events.map((e) => e.toMap()).toList();
    await prefs.setString(_keyEvents, jsonEncode(list));
  }

  // Caretakers persistence
  Future<List<Caretaker>> loadCaretakers() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_keyCaretakers);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((item) => Caretaker.fromMap(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCaretakers(List<Caretaker> caretakers) async {
    final prefs = await _getPrefs();
    final list = caretakers.map((c) => c.toMap()).toList();
    await prefs.setString(_keyCaretakers, jsonEncode(list));
  }

  // Simulated Device Mode toggle persistence
  Future<bool> loadIsSimulatedDevice() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keySimulatedDevice) ?? false;
  }

  Future<void> saveIsSimulatedDevice(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keySimulatedDevice, enabled);
  }
}
