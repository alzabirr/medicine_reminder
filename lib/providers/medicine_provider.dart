import 'package:flutter/material.dart';
import 'package:medi/models/medicine.dart';
import 'package:medi/services/database_service.dart';
import 'package:medi/services/notification_service.dart';
import 'package:medi/services/notification_service.dart';

class MedicineProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  NotificationService get notificationService => _notificationService;

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
    // Permissions should be requested from UI, not here blocking startup
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

  // Soft Delete: Move to Trash
  Future<void> deleteMedicine(String id) async {
    final medicineIndex = _medicines.indexWhere((m) => m.id == id);
    if (medicineIndex != -1) {
       final medicine = _medicines[medicineIndex];
       
       // 1. Cancel notifications
       for (final slotString in medicine.timeSlots) {
          final pivotIndex = slotString.indexOf(':');
          final label = pivotIndex != -1 
              ? slotString.substring(0, pivotIndex).trim() 
              : slotString;
          await _notificationService.cancelNotification((id + label).hashCode);
       }
       
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
    await _scheduleNotifications(medicine);
    
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
    if (frequency != null) medicine.interval = frequency;
    
    await medicine.save();

    // 3. Schedule New Notifications
    await _scheduleNotifications(medicine);
    
    notifyListeners();
  }

  Future<void> _scheduleNotifications(Medicine medicine) async {
    // Validate if medicine should be active
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(medicine.startTime.year, medicine.startTime.month, medicine.startTime.day);
    
    // 1. Check if medicine has already ended (BLOCK these)
    if (medicine.endDate != null) {
      final end = DateTime(medicine.endDate!.year, medicine.endDate!.month, medicine.endDate!.day);
      if (today.isAfter(end)) {
        debugPrint('Medicine ${medicine.name} has already ended. No notifications scheduled.');
        return;
      }
    }
    
    // 2. For future medicines, schedule from start date
    // For current/past start dates, schedule from today
    DateTime scheduleFromDate;
    if (today.isBefore(start)) {
      // Future medicine - schedule from start date
      scheduleFromDate = start;
      debugPrint('Medicine ${medicine.name} starts in the future. Scheduling from ${start.year}-${start.month}-${start.day}');
    } else {
      // Current or past start date - schedule from today
      scheduleFromDate = today;
    }
    
    // 3. Interval Logic (Smart filtering for scheduling)
    final diffDays = today.difference(start).inDays;
    
    bool shouldShowToday = false;
    if (medicine.interval <= 1) {
      shouldShowToday = true;
    } else if (medicine.interval == 7) {
      shouldShowToday = start.weekday == now.weekday;
    } else {
      // Every X Days logic
      shouldShowToday = diffDays % medicine.interval == 0;
    }

    if (!shouldShowToday && !today.isBefore(start)) {
      debugPrint('Medicine ${medicine.name} is not scheduled for today (Interval: ${medicine.interval}). No notification for today.');
      // Note: This logic only blocks TODAY's notification. 
      // AwesomeNotifications scheduling with NotificationCalendar(day: ...) 
      // usually repeats BASED on that day. 
      // However, for complex intervals like "Every 2 days", we can't easily 
      // represent that in a single NotificationCalendar if it doesn't align with weekly/monthly.
    }
    
    // If it's a future start date, we should only schedule TODAY if today is >= start.
    // However, if we schedule a generic daily repeating one, it might ring too early.
    // For now, let's skip scheduling if today is before start, 
    // AND provide a mechanism to re-schedule when the app opens or dates change.
    
    if (today.isBefore(start)) {
      debugPrint('Medicine ${medicine.name} starts in the future (${start.year}-${start.month}-${start.day}). Skipping scheduling for now.');
      return;
    }

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
        
        final notificationId = (medicine.id + label).hashCode;

        if (medicine.interval == 1) {
          // Daily
          await _notificationService.scheduleNotification(
            id: notificationId,
            title: 'Daily: ${medicine.name}',
            body: 'Time for your dose ${medicine.instruction != null ? ' • ' + medicine.instruction! : ''}',
            hour: hour,
            minute: minute,
            repeats: true,
          );
        } else if (medicine.interval == 7) {
          // Weekly
          await _notificationService.scheduleNotification(
            id: notificationId,
            title: 'Weekly: ${medicine.name}',
            body: 'Your weekly dose is due ${medicine.instruction != null ? ' • ' + medicine.instruction! : ''}',
            hour: hour,
            minute: minute,
            weekday: start.weekday,
            repeats: true,
          );
        } else {
          // Every X days - schedule next 10 occurrences manually as AwesomeNotifications 
          // doesn't support "Every X days" repetition natively in NotificationCalendar.
          for (int i = 0; i < 10; i++) {
            final occurrenceDate = start.add(Duration(days: i * medicine.interval));
            if (occurrenceDate.isBefore(today)) continue;
            
            // Limit to roughly a month out
            if (occurrenceDate.difference(today).inDays > 60) break;

            await _notificationService.scheduleNotification(
              id: (medicine.id + label + i.toString()).hashCode,
              title: 'Medi: ${medicine.name}',
              body: 'Time for your dose ${medicine.instruction != null ? ' • ' + medicine.instruction! : ''}',
              hour: hour,
              minute: minute,
              day: occurrenceDate,
              repeats: false, // Single day notification
            );
          }
        }
        
      } catch (e) {
        debugPrint('Error scheduling notification: $e');
      }
    }
  }

  Future<void> toggleTaken(Medicine medicine, {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    
    debugPrint('=== Toggle Taken Debug ===');
    debugPrint('Medicine: ${medicine.name}');
    debugPrint('Target Date: $targetDate');
    debugPrint('Current takenHistory length: ${medicine.takenHistory.length}');
    debugPrint('takenHistory type: ${medicine.takenHistory.runtimeType}');
    
    final todayEntries = medicine.takenHistory.where(
      (d) => d.year == targetDate.year && d.month == targetDate.month && d.day == targetDate.day,
    ).toList();
    
    final isTakenMax = todayEntries.length >= medicine.timeSlots.length;

    if (!isTakenMax) {
      debugPrint('Adding another dose for today...');
      try {
        medicine.takenHistory.add(targetDate);
      } catch (e) {
        medicine.takenHistory = List<DateTime>.from(medicine.takenHistory);
        medicine.takenHistory.add(targetDate);
      }
    } else {
      debugPrint('Resetting doses for today (Cycle)...');
      try {
        medicine.takenHistory.removeWhere(
          (d) => d.year == targetDate.year && d.month == targetDate.month && d.day == targetDate.day,
        );
      } catch (e) {
        medicine.takenHistory = List<DateTime>.from(medicine.takenHistory);
        medicine.takenHistory.removeWhere(
          (d) => d.year == targetDate.year && d.month == targetDate.month && d.day == targetDate.day,
        );
      }
    }

    debugPrint('New takenHistory length: ${medicine.takenHistory.length}');
    debugPrint('Saving medicine...');
    
    await medicine.save();
    
    debugPrint('Medicine saved successfully');
    
    // Force reload from DB to ensure UI has latest state (fixes potential stale object issues)
    await loadMedicines();
    
    debugPrint('Medicines reloaded');
    debugPrint('========================');
    
    notifyListeners();
  }
}
