import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:medi/models/medicine.dart';
import 'package:medi/services/database_service.dart';
import 'package:medi/services/notification_service.dart';

class MedicineProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  NotificationService get notificationService => _notificationService;
  
  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  Map<String, String> _userProfile = {
    'name': 'User Name',
    'email': 'user@example.com',
  };
  Map<String, String> get userProfile => _userProfile;

  // Getters for filtered lists
  List<Medicine> _medicines = []; // Internal storage
  List<Medicine> get medicines => _medicines; // All medicines (raw)
  List<Medicine> get activeMedicines => _medicines.where((m) => !m.isDeleted).toList();
  List<Medicine> get deletedMedicines => _medicines.where((m) => m.isDeleted).toList();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    await _databaseService.init();
    await _notificationService.init();
    await loadMedicines();
    
    // Initial schedule refresh on app startup
    await refreshAllSchedules();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMedicines() async {
    _medicines = _databaseService.getMedicines();
    notifyListeners();
  }

  Future<void> addMedicine(Medicine medicine) async {
    await _databaseService.addMedicine(medicine);
    await refreshAllSchedules(); // Centralized scheduling
    await loadMedicines();
  }

  // Soft Delete: Move to Trash
  Future<void> deleteMedicine(String id) async {
    final medicineIndex = _medicines.indexWhere((m) => m.id == id);
    if (medicineIndex != -1) {
       final medicine = _medicines[medicineIndex];
       
       // 1. Cancel notifications
       await _cancelNotifications(medicine);
       
       // 2. Soft delete
       medicine.isDeleted = true;
       await medicine.save();
    }
    
    await loadMedicines();
  }

  // Restore from Trash
  Future<void> restoreMedicine(Medicine medicine) async {
    medicine.isDeleted = false;
    await medicine.save();
    
    // Reschedule notifications
    await refreshAllSchedules();
    
    await loadMedicines();
  }

  // Hard Delete: Permanent Removal
  Future<void> deletePermanently(String id) async {
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
    int? frequency,
  }) async {
    // 1. Cancel old notifications using OLD slots
    await _cancelNotifications(medicine);

    // 2. Update Medicine Object
    medicine.name = name;
    medicine.type = type;
    medicine.timeSlots = timeSlots;
    medicine.instruction = instruction;
    medicine.startTime = startDate;
    medicine.endDate = endDate;
    if (imagePath != null) medicine.imagePath = imagePath;
    if (frequency != null) medicine.interval = frequency;
    
    await medicine.save();

    // 3. Schedule New Notifications
    await refreshAllSchedules();
    
    notifyListeners();
  }

  Future<void> _cancelNotifications(Medicine medicine) async {
    for (final slotString in medicine.timeSlots) {
      final pivotIndex = slotString.indexOf(':');
      final label = pivotIndex != -1 
          ? slotString.substring(0, pivotIndex).trim() 
          : slotString;
      
      final baseId = (medicine.id + label).hashCode;
      
      // Cancel standard daily/weekly
      await _notificationService.cancelNotification(baseId);
      
      // Cancel potential manual occurrences (next 10) for interval-based
      for (int i = 0; i < 10; i++) {
        await _notificationService.cancelNotification((medicine.id + label + i.toString()).hashCode);
      }
    }
  }

  // Centralized Scheduling Logic
  Future<void> refreshAllSchedules({DateTime? baseTime}) async {
    if (!_notificationsEnabled) return;
    
    final now = baseTime ?? DateTime.now();
    debugPrint('Refeshing all schedules at $now');

    // We could optimize by comparing checksums, but for now we'll just ensure 
    // coverage for all active medicines.
    // Note: To avoid duplicate alarms, awesome_notifications handles ID conflicts by replacing.
    // However, for interval meds, we might want to clear old future ones first if we want to be strict.
    // For simplicity and robustness: just trigger scheduling for each.
    
    for (final medicine in activeMedicines) {
      await _scheduleNotifications(medicine, baseTime: now);
    }
  }

  Future<void> _scheduleNotifications(Medicine medicine, {DateTime? baseTime}) async {
    final now = baseTime ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(medicine.startTime.year, medicine.startTime.month, medicine.startTime.day);
    
    // 1. Check if medicine has already ended
    if (medicine.endDate != null) {
      final end = DateTime(medicine.endDate!.year, medicine.endDate!.month, medicine.endDate!.day);
      if (today.isAfter(end)) {
        return;
      }
    }
    
    // 2. Schedule Window: Next 90 Days
    const int scheduleWindowDays = 90;
    
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
             continue; 
        }
        
        // Base Notification ID generated from MedicineID + SlotLabel
        // usage: (base string).hashCode
        final slotKey = medicine.id + label;

        if (medicine.interval == 1) {
          // Daily: Use standard repeating notification
          // If start date is in future, we technically should wait.
          // BUT AwesomeNotifications repeating daily starts "now" if we don't specify a date, 
          // or starts on the specific date if we do.
          
          if (start.isAfter(today)) {
             // Future start: Schedule a specific "Daily" starting from that date?
             // AwesomeNotifications doesn't effortlessly support "Repeat Daily starting from X" 
             // except by scheduling the first one on X with repeats=true.
             
             await _notificationService.scheduleNotification(
                id: slotKey.hashCode,
                title: 'Daily: ${medicine.name}',
                body: 'Time for your dose ${medicine.instruction != null ? ' • ' + medicine.instruction! : ''}',
                hour: hour,
                minute: minute,
                day: start, // Start on the start date
                repeats: true,
                payload: {'medicineId': medicine.id},
             );
          } else {
             // Already started: Schedule for Today (or next occurrence by hour)
             await _notificationService.scheduleNotification(
                id: slotKey.hashCode,
                title: 'Daily: ${medicine.name}',
                body: 'Time for your dose ${medicine.instruction != null ? ' • ' + medicine.instruction! : ''}',
                hour: hour,
                minute: minute,
                repeats: true,
                payload: {'medicineId': medicine.id},
             );
          }
          
        } else if (medicine.interval == 7) {
          // Weekly
           await _notificationService.scheduleNotification(
            id: slotKey.hashCode,
            title: 'Weekly: ${medicine.name}',
            body: 'Your weekly dose is due ${medicine.instruction != null ? ' • ' + medicine.instruction! : ''}',
            hour: hour,
            minute: minute,
            weekday: start.weekday,
            repeats: true,
            payload: {'medicineId': medicine.id},
          );
        } else {
          // Interval (Every X Days) - Rolling Window Logic
          
          // Calculate first valid occurrence relative to START date
          // We need to find occurrences within [now, now + 90 days]
          
          final daysDesdeStart = today.difference(start).inDays;
          
          // Start iterating from a point that covers "today" or "future start"
          // If daysDesdeStart < 0 (Future start), we start from 0 (Start Date)
          // If daysDesdeStart >= 0, we find the next multiple of interval
          
          int startOffset = 0;
          if (daysDesdeStart >= 0) {
             final remainder = daysDesdeStart % medicine.interval;
             if (remainder == 0) {
               startOffset = daysDesdeStart; // Today is a dose day
             } else {
               startOffset = daysDesdeStart + (medicine.interval - remainder); // Next dose day
             }
          }
          
          // Now iterate forward for 90 days
          for (int dayOffset = startOffset; ; dayOffset += medicine.interval) {
             // Safety break if we drift too far backwards (unlikely)
             if (dayOffset < daysDesdeStart && daysDesdeStart > 90) break; // Should not happen with logic above
             
             final occurrenceDate = start.add(Duration(days: dayOffset));
             
             // Stop if we exceed the window
             if (occurrenceDate.difference(today).inDays > scheduleWindowDays) break;
             
             // Stop if we exceed End Date
             if (medicine.endDate != null) {
                final end = DateTime(medicine.endDate!.year, medicine.endDate!.month, medicine.endDate!.day);
                if (occurrenceDate.isAfter(end)) break;
             }
             
             // Unique ID for this specific occurrence: MedId + Slot + DateString
             final occurrenceId = (slotKey + occurrenceDate.toIso8601String()).hashCode;
             
             await _notificationService.scheduleNotification(
              id: occurrenceId,
              title: 'Medi: ${medicine.name}',
              body: 'Time for your dose ${medicine.instruction != null ? ' • ' + medicine.instruction! : ''}',
              hour: hour,
              minute: minute,
              day: occurrenceDate,
              repeats: false,
              payload: {'medicineId': medicine.id},
            );
          }
        }
        
      } catch (e) {
        debugPrint('Error scheduling notification: $e');
      }
    }
  }

  Future<void> toggleTaken(Medicine medicine, {DateTime? date, String? timeSlot}) async {
    final targetDate = date ?? DateTime.now();
    
    // If timeslot provided, we use slot-specific logic
    if (timeSlot != null) {
      final pivotIndex = timeSlot.indexOf(':');
      final timeStr = pivotIndex != -1 ? timeSlot.substring(pivotIndex + 1).trim() : timeSlot;
      
      // Parse to match the logic in isSlotTaken
      int hour = 0;
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
      }
      
      final isTaken = medicine.isSlotTaken(targetDate, timeSlot);
      
      if (isTaken) {
        // Remove the specific entry matching date + time
        medicine.takenHistory.removeWhere((dt) => 
            dt.year == targetDate.year && 
            dt.month == targetDate.month && 
            dt.day == targetDate.day &&
            dt.hour == hour &&
            dt.minute == minute
        );
      } else {
        // Add new entry with correct date + time
        final entry = DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);
        medicine.takenHistory.add(entry);
      }
      
    } else {
      // Fallback: Legacy "Daily Count" toggle if no slot specified (backward compatibility)
      // We will try to guess the "next available slot" or just append NOW
      // Current usage in Home Screen relies on this, so we should try to be smart.
      
      // Since we want to move to slot-based, we'll auto-assign to the first untaken slot of the day?
      // Or just keep legacy behavior. Let's keep legacy behavior BUT try to align hours if possible.
      
      final todayEntries = medicine.takenHistory.where(
        (d) => d.year == targetDate.year && d.month == targetDate.month && d.day == targetDate.day,
      ).toList();
      
      if (todayEntries.length < medicine.timeSlots.length) {
         // Mark next as taken
         medicine.takenHistory.add(targetDate);
      } else {
         // Reset
         medicine.takenHistory.removeWhere(
          (d) => d.year == targetDate.year && d.month == targetDate.month && d.day == targetDate.day,
        );
      }
    }

    await medicine.save();
    // Force reload from DB to ensure UI has latest state (fixes potential stale object issues)
    await loadMedicines();
    notifyListeners();
  }

  void toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    notifyListeners();
    
    if (!_notificationsEnabled) {
      // Cancel everything
      await AwesomeNotifications().cancelAllSchedules();
    } else {
      // Reschedule all active medicines
      await refreshAllSchedules();
    }
  }

  void updateProfile(String name, String email) {
    _userProfile['name'] = name;
    _userProfile['email'] = email;
    notifyListeners();
  }
}
