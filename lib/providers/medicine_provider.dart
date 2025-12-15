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
    await _scheduleNotifications(medicine);
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
          // Robust label extraction matching addMedicine
          final pivotIndex = slotString.indexOf(':');
          final label = pivotIndex != -1 
              ? slotString.substring(0, pivotIndex).trim() 
              : slotString; // Fallback if no colon (shouldn't happen with new logic, but safe)
          
          await _notificationService.cancelNotification((id + label).hashCode);
       }
    }

    await _databaseService.deleteMedicine(id);
    await loadMedicines();
  }

  Future<void> updateMedicine(Medicine medicine, {
    required String name,
    required String type,
    required List<String> timeSlots,
    required String instruction,
    required DateTime startDate,
    required DateTime endDate,
    String? imagePath,
  }) async {
    // 1. Cancel old notifications using OLD slots
    for (final slotString in medicine.timeSlots) {
       final pivotIndex = slotString.indexOf(':');
       final label = pivotIndex != -1 
          ? slotString.substring(0, pivotIndex).trim() 
          : slotString;
       await _notificationService.cancelNotification((medicine.id + label).hashCode);
    }

    // 2. Update Medicine Object
    medicine.name = name;
    medicine.type = type;
    medicine.timeSlots = timeSlots;
    medicine.instruction = instruction;
    medicine.startTime = startDate;
    medicine.endDate = endDate;
    if (imagePath != null) medicine.imagePath = imagePath;
    
    await medicine.save();

    // 3. Schedule New Notifications
    await _scheduleNotifications(medicine);
    
    notifyListeners();
  }

  Future<void> _scheduleNotifications(Medicine medicine) async {
    for (final slotString in medicine.timeSlots) {
      try {
        final pivotIndex = slotString.indexOf(':');
        if (pivotIndex == -1) continue; 
        
        final label = slotString.substring(0, pivotIndex).trim();
        final timeStr = slotString.substring(pivotIndex + 1).trim(); 
        
        int hour = 8;
        int minute = 0;
        
        final RegExp timeRegex = RegExp(r'(\d{1,2})[:\s\u00A0\u2007\u202F]+(\d{2})\s*(AM|PM|am|pm)?');
        final match = timeRegex.firstMatch(timeStr);

        if (match != null) {
           int h = int.parse(match.group(1)!);
           int m = int.parse(match.group(2)!);
           final period = match.group(3)?.toLowerCase(); 

           if (period == 'pm' && h != 12) h += 12;
           if (period == 'am' && h == 12) h = 0;
           
           hour = h;
           minute = m;
        } else {
             debugPrint('Could not parse time string: $timeStr');
             continue; 
        }

        final now = DateTime.now();
        final scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );
        
        final notificationId = (medicine.id + label).hashCode;

        await _notificationService.scheduleNotification(
          id: notificationId,
          title: 'Medicine Reminder: ${medicine.name}',
          body: 'Please take your medicine',
          scheduledTime: scheduledTime,
          matchDateTimeComponents: fln.DateTimeComponents.time,
        );
        
      } catch (e) {
        debugPrint('Error scheduling notification: $e');
      }
    }
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
