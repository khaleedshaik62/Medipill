import 'dart:async';
import '../../data/models/models.dart';

abstract class MedicineImageService {
  Future<MedicineDraft> processMedicineImage(String imagePath);
}

class MockMedicineImageService implements MedicineImageService {
  // Pre-configured mocks for different types of scans to simulate OCR results realistically
  final Map<String, MedicineDraft> _mockDb = {
    'prescription': MedicineDraft(
      name: 'Paracetamol',
      strength: '500 mg',
      form: 'Tablet',
      dose: '1 Tablet',
      frequency: 'Three times daily',
      reminderTimes: ['08:00', '13:00', '20:00'],
      foodInstruction: 'After food',
      durationDays: '5',
      notes: 'Take after meals for fever/pain relief',
    ),
    'label': MedicineDraft(
      name: 'Vitamin D3',
      strength: '1000 IU',
      form: 'Capsule',
      dose: '1 Capsule',
      frequency: 'Once daily',
      reminderTimes: ['08:00'],
      foodInstruction: 'With food',
      durationDays: '30',
      notes: 'Take in the morning',
    ),
    'unclear': MedicineDraft(), // Will fail verification/empty OCR simulation
  };

  @override
  Future<MedicineDraft> processMedicineImage(String imagePath) async {
    await Future.delayed(const Duration(milliseconds: 1500)); // Simulate processing delay
    
    // Choose mock based on substring matches
    if (imagePath.contains('presc') || imagePath.contains('parac')) {
      return _mockDb['prescription']!;
    } else if (imagePath.contains('vit') || imagePath.contains('label')) {
      return _mockDb['label']!;
    }
    
    // Default fallback to OCR failure / manual verification needed
    return _mockDb['unclear']!;
  }
}
