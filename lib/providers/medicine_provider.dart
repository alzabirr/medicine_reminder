import 'package:flutter/material.dart';
import 'package:medi/models/medicine.dart';
import 'package:medi/services/database_service.dart';
import 'package:medi/services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;

class MedicineProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  List<Medicine> _medicines = [];
  List<Medicine> get medicines => _medicines;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    await _databaseService.init();
    await _notificationService.init();
    await _notificationService.requestPermissions(); // Request permissions on app launch
    await loadMedicines();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMedicines() async {
    _medicines = _databaseService.getMedicines();
    notifyListeners();
  }

  Future<void> addMedicine(Medicine medicine) async {
    await _databaseService.addMedicine(medicine);
    
    // Schedule notifications for each slot
    // Format is "Label: Time (e.g. Morning: 8:00 AM)"
    for (final slotString in medicine.timeSlots) {
      try {
        // Parse "Label: Time"
        final parts = slotString.split(': ');
        if (parts.length < 2) continue; // Skip if format is wrong
        
        final label = parts[0];
        final timeStr = parts[1]; // "8:00 AM"
        
        // Parse time string to TimeOfDay
        // Remove spaces and normalize
        // Basic parsing assuming "8:00 AM" format from TimeOfDay.format()
        // Format depends on locale, but standard Material is "h:mm a" or "HH:mm"
        // Better: Pass proper TimeOfDay/DateTime in Medicine object, but strict refactor is hard.
        // Let's parse strictly assuming standard US (AM/PM) or 24h
        
        int hour = 8;
        int minute = 0;
        
        // Quick regex parse
        // Matches 8:00 AM or 13:00
        final timeParts = timeStr.split(RegExp(r'[:\s]')); // split by : or space
        if (timeParts.isNotEmpty) {
           int h = int.tryParse(timeParts[0]) ?? 8;
           int m = int.tryParse(timeParts[1]) ?? 0;
           final isPm = timeStr.toLowerCase().contains('pm');
           final isAm = timeStr.toLowerCase().contains('am');
           
           if (isPm && h != 12) h += 12;
           if (isAm && h == 12) h = 0;
           
           hour = h;
           minute = m;
        }

        final now = DateTime.now();
        final scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );
        
        // Unique ID: medicineId hash + slot hash
        final notificationId = (medicine.id + label).hashCode;

        await _notificationService.scheduleNotification(
          id: notificationId,
          title: 'Medicine Reminder: ${medicine.name}',
          body: 'Time to take your ${label.toLowerCase()} dose (${medicine.instruction ?? ""})',
          scheduledTime: scheduledTime,
          matchDateTimeComponents: fln.DateTimeComponents.time, // Repeat Daily
        );
        
      } catch (e) {
        debugPrint('Error scheduling notification: $e');
      }
    }

    await loadMedicines();
  }

  Future<void> deleteMedicine(String id) async {
    // Attempt to cancel all potential slots
    // Since we don't have the slots easily here without fetching, we iterate common ones
    // Or we could fetch the medicine first.
    final medicineIndex = _medicines.indexWhere((m) => m.id == id);
    if (medicineIndex != -1) {
       final medicine = _medicines[medicineIndex];
       for (final slotString in medicine.timeSlots) {
          final label = slotString.split(': ')[0];
          await _notificationService.cancelNotification((id + label).hashCode);
       }
    }

    await _databaseService.deleteMedicine(id);
    await loadMedicines();
  }

  Future<void> toggleTaken(Medicine medicine) async {
    final now = DateTime.now();
    // ... existing logic ...
    final isTaken = medicine.takenHistory.any(
      (d) => d.year == now.year && d.month == now.month && d.day == now.day,
    );

    if (isTaken) {
      medicine.takenHistory.removeWhere(
        (d) => d.year == now.year && d.month == now.month && d.day == now.day,
      );
    } else {
      medicine.takenHistory.add(now);
    }

    await medicine.save();
    notifyListeners();
  }
}
