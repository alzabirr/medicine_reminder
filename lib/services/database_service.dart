import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:medi/models/medicine.dart';

class DatabaseService {
  static const String boxName = 'medicines';

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(MedicineAdapter());
    await Hive.openBox<Medicine>(boxName);
    
    // Migration: Fix existing medicines with immutable takenHistory
    await _migrateTakenHistory();
  }
  
  Future<void> _migrateTakenHistory() async {
    try {
      final medicines = _box.values.toList();
      debugPrint('=== Migration: Fixing takenHistory ===');
      debugPrint('Total medicines: ${medicines.length}');
      
      for (var medicine in medicines) {
        // Check if takenHistory is immutable by trying to add/remove
        try {
          // final originalLength = medicine.takenHistory.length; // Removed unused

          final testDate = DateTime.now();
          medicine.takenHistory.add(testDate);
          medicine.takenHistory.remove(testDate);
          debugPrint('Medicine ${medicine.name}: takenHistory is mutable ✓');
        } catch (e) {
          // takenHistory is immutable, need to fix it
          debugPrint('Medicine ${medicine.name}: takenHistory is IMMUTABLE, fixing...');
          final oldHistory = List<DateTime>.from(medicine.takenHistory);
          
          // Create new medicine with mutable list
          final fixedMedicine = Medicine(
            id: medicine.id,
            name: medicine.name,
            dosage: medicine.dosage,
            type: medicine.type,
            interval: medicine.interval,
            startTime: medicine.startTime,
            imagePath: medicine.imagePath,
            takenHistory: oldHistory, // This will create a new mutable list
            timeSlots: medicine.timeSlots,
            instruction: medicine.instruction,
            endDate: medicine.endDate,
          );
          
          // Delete old and add fixed
          await medicine.delete();
          await _box.add(fixedMedicine);
          debugPrint('Fixed medicine ${medicine.name} ✓');
        }
      }
      
      debugPrint('Migration complete!');
      debugPrint('====================================');
    } catch (e) {
      debugPrint('Migration error: $e');
    }
  }

  Box<Medicine> get _box => Hive.box<Medicine>(boxName);

  List<Medicine> getMedicines() {
    return _box.values.toList();
  }

  Future<void> addMedicine(Medicine medicine) async {
    await _box.add(medicine);
  }

  Future<void> deleteMedicine(String id) async {
    // Find key and delete
    try {
      final medicine = _box.values.firstWhere((m) => m.id == id);
      await medicine.delete();
    } catch (e) {
      debugPrint('Error deleting medicine: $e');
    }
  }

  Future<void> updateMedicine(Medicine medicine) async {
    await medicine.save();
  }

  // ValueListenable for UI updates
  ValueListenable<Box<Medicine>> getMedicinesListenable() {
    return _box.listenable();
  }
}
