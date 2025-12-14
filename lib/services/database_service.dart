import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:medi/models/medicine.dart';

class DatabaseService {
  static const String boxName = 'medicines';

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(MedicineAdapter());
    await Hive.openBox<Medicine>(boxName);
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
