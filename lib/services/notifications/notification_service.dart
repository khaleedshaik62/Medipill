import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/models.dart';

abstract class NotificationService {
  Future<void> initialize();
  Future<void> showNotification({required String title, required String body, String? payload});
  Future<void> scheduleMedicationReminder(Medicine medicine, String time);
  Future<void> cancelReminder(String medicineId);
  Future<void> snoozeReminder(String medicineId, int minutes);
  Future<void> showCaretakerAlert(Caretaker caretaker, String medicineName, String scheduledTime, int containerId, String timeSlot);
  Stream<String?> get notificationClicks;
}

class MockNotificationService implements NotificationService {
  final StreamController<String?> _clickController = StreamController<String?>.broadcast();
  final List<Map<String, dynamic>> _scheduledReminders = [];
  final List<String> _deliveredNotifications = [];

  List<String> get deliveredNotifications => _deliveredNotifications;

  @override
  Future<void> initialize() async {
    debugPrint('MockNotificationService initialized');
  }

  @override
  Future<void> showNotification({required String title, required String body, String? payload}) async {
    debugPrint('NOTIFICATION: $title - $body');
    _deliveredNotifications.add('[$title] $body');
  }

  @override
  Future<void> scheduleMedicationReminder(Medicine medicine, String time) async {
    debugPrint('SCHEDULED REMINDER: ${medicine.name} at $time for Container ${medicine.containerId} (${medicine.timeSlot})');
    _scheduledReminders.add({
      'medicineId': medicine.id,
      'time': time,
      'containerId': medicine.containerId,
      'timeSlot': medicine.timeSlot,
    });
  }

  @override
  Future<void> cancelReminder(String medicineId) async {
    debugPrint('CANCEL REMINDER for medicine: $medicineId');
    _scheduledReminders.removeWhere((element) => element['medicineId'] == medicineId);
  }

  @override
  Future<void> snoozeReminder(String medicineId, int minutes) async {
    debugPrint('SNOOZED REMINDER for medicine: $medicineId by $minutes minutes');
    await showNotification(
      title: 'Medication Snoozed',
      body: 'Reminder postponed by $minutes minutes.',
    );
  }

  @override
  Future<void> showCaretakerAlert(
    Caretaker caretaker, 
    String medicineName, 
    String scheduledTime, 
    int containerId, 
    String timeSlot,
  ) async {
    final alertMsg = 'Medication Alert: ${caretaker.name}, the scheduled medication event for $medicineName at $scheduledTime was not confirmed. (Physical Location: Container $containerId - $timeSlot)';
    await showNotification(
      title: 'Caretaker Alert: Unconfirmed Medication',
      body: 'Scheduled event for $medicineName at $scheduledTime was not confirmed.',
    );
    debugPrint(alertMsg);
  }

  @override
  Stream<String?> get notificationClicks => _clickController.stream;
}
