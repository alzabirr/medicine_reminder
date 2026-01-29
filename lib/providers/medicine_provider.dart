import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:medi/models/medicine.dart';
import 'package:medi/services/database_service.dart';
import 'package:medi/services/notification_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

class MedicineProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  NotificationService get notificationService => _notificationService;
  
  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  Map<String, String> _userProfile = {
    'name': 'User Name',
    'avatar': 'assets/avatar/Aven.jpg',
    'bloodGroup': 'Select',
    'weight': '—',
    'allergies': 'None',
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
    await _loadProfile();
    
    // Initial schedule refresh on app startup
    await refreshAllSchedules();
    
    _isLoading = false;
    notifyListeners();
  }

  Map<String, dynamic> getAdherenceStats() {
    int totalScheduled = 0;
    int totalTaken = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var medicine in activeMedicines) {
      final start = DateTime(medicine.startTime.year, medicine.startTime.month, medicine.startTime.day);
      final end = medicine.endDate != null 
          ? DateTime(medicine.endDate!.year, medicine.endDate!.month, medicine.endDate!.day)
          : today;
      
      final reportEnd = end.isBefore(today) ? end : today;
      
      if (reportEnd.isBefore(start)) continue;

      final daysCount = reportEnd.difference(start).inDays + 1;
      
      int mScheduled = 0;
      for (int i = 0; i < daysCount; i++) {
        final currentDate = start.add(Duration(days: i));
        final isToday = currentDate.year == today.year && currentDate.month == today.month && currentDate.day == today.day;
        
        bool isDoseDay = false;
        if (medicine.interval == 1) isDoseDay = true;
        else if (medicine.interval == 7) isDoseDay = currentDate.weekday == start.weekday;
        else isDoseDay = currentDate.difference(start).inDays % medicine.interval == 0;

        if (isDoseDay) {
          for (var slot in medicine.timeSlots) {
            if (isToday) {
              // Only count if slot time has passed
              final slotTime = _parseSlotTime(slot);
              if (slotTime != null) {
                final scheduledDT = DateTime(today.year, today.month, today.day, slotTime.hour, slotTime.minute);
                if (now.isAfter(scheduledDT)) mScheduled++;
              }
            } else {
              mScheduled++;
            }
          }
        }
      }
      
      totalScheduled += mScheduled;
      
      // Calculate taken: Manual + Automatic for non-manually marked past slots
      int mTaken = medicine.takenHistory.where((dt) {
        final d = DateTime(dt.year, dt.month, dt.day);
        return (d.isAtSameMomentAs(start) || d.isAfter(start)) && 
               (d.isAtSameMomentAs(reportEnd) || d.isBefore(reportEnd));
      }).length;

      // Check for automatic doses that might not have manual entries
      int autoCount = 0;
      // We iterate through all days in report window
      for (int i = 0; i < daysCount; i++) {
        final currentDate = start.add(Duration(days: i));
        bool isDoseDay = false;
        if (medicine.interval == 1) isDoseDay = true;
        else if (medicine.interval == 7) isDoseDay = currentDate.weekday == start.weekday;
        else isDoseDay = currentDate.difference(start).inDays % medicine.interval == 0;

        if (isDoseDay) {
          for (var slot in medicine.timeSlots) {
            final time = _parseSlotTime(slot);
            if (time != null) {
              final scheduledDT = DateTime(currentDate.year, currentDate.month, currentDate.day, time.hour, time.minute);
              if (now.isAfter(scheduledDT)) {
                // Check if manually taken
                bool manuallyTaken = medicine.takenHistory.any((dt) => 
                  dt.year == currentDate.year && dt.month == currentDate.month && dt.day == currentDate.day &&
                  dt.hour == time.hour && dt.minute == time.minute
                );
                if (!manuallyTaken) autoCount++;
              }
            }
          }
        }
      }

      totalTaken += (mTaken + autoCount);
    }

    final double percentage = totalScheduled > 0 ? (totalTaken / totalScheduled) * 100 : 0.0;

    return {
      'totalScheduled': totalScheduled,
      'totalTaken': totalTaken,
      'percentage': percentage.clamp(0.0, 100.0),
    };
  }

  TimeOfDay? _parseSlotTime(String slot) {
    final pivotIndex = slot.indexOf(':');
    if (pivotIndex == -1) return null;
    final timeStr = slot.substring(pivotIndex + 1).trim();
    final RegExp timeRegex = RegExp(r'(\d{1,2})[:\s\u00A0\u2007\u202F]+(\d{2})\s*(AM|PM|am|pm)?');
    final match = timeRegex.firstMatch(timeStr);
    if (match != null) {
      int h = int.parse(match.group(1)!);
      int m = int.parse(match.group(2)!);
      final period = match.group(3)?.toLowerCase();
      if (period == 'pm' && h != 12) h += 12;
      if (period == 'am' && h == 12) h = 0;
      return TimeOfDay(hour: h, minute: m);
    }
    return null;
  }

  Map<String, dynamic> getAdvancedAnalytics() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // 1. History Trend (All days from earliest to latest)
    List<Map<String, dynamic>> weeklyTrend = [];
    final history = getActiveDaysHistory();
    // We want the trend in chronological order for the chart (oldest to newest)
    weeklyTrend = history.reversed.map((day) => {
      'date': day['date'],
      'percentage': (day['percentage'] as double) * 100,
    }).toList();

    // 2. Streaks
    int currentStreak = 0;
    int bestStreak = 0;
    int tempStreak = 0;
    
    // Count backwards from yesterday for current streak
    // Today might be partial, so we check if today is fully taken or still in progress
    bool checkedToday = false;
    
    // Simple streak logic: check each day starting from today backwards
    for (int i = 0; ; i++) {
      final targetDate = today.subtract(Duration(days: i));
      int dayScheduled = 0;
      int dayTaken = 0;
      bool hasActiveMeds = false;

      for (var medicine in activeMedicines) {
        final start = DateTime(medicine.startTime.year, medicine.startTime.month, medicine.startTime.day);
        final end = medicine.endDate != null 
            ? DateTime(medicine.endDate!.year, medicine.endDate!.month, medicine.endDate!.day)
            : null;

        if (targetDate.isBefore(start)) continue;
        if (end != null && targetDate.isAfter(end)) continue;
        
        hasActiveMeds = true;

        bool isDoseDay = false;
        if (medicine.interval == 1) {
          isDoseDay = true;
        } else if (medicine.interval == 7) {
          isDoseDay = targetDate.weekday == start.weekday;
        } else {
          isDoseDay = targetDate.difference(start).inDays % medicine.interval == 0;
        }

        if (isDoseDay) {
          dayScheduled += medicine.timeSlots.length;
          dayTaken += medicine.takenHistory.where((dt) {
            return dt.year == targetDate.year && dt.month == targetDate.month && dt.day == targetDate.day;
          }).length;
        }
      }

      if (!hasActiveMeds && i > 0) break; // End of history
      if (!hasActiveMeds && i == 0) continue; // Skip today if no meds scheduled

      if (dayScheduled > 0 && dayTaken >= dayScheduled) {
        tempStreak++;
        if (i == 0 || (i > 0 && currentStreak == i)) {
           currentStreak = tempStreak;
        }
      } else if (dayScheduled > 0) {
        if (i == 0) {
          // Today not finished, don't break streak yet if yesterday was good
          continue;
        }
        break; // Streak broken
      } else if (i > 0 && dayScheduled == 0) {
          // No meds scheduled on this day, streak continues
          tempStreak++;
          if (currentStreak == i) currentStreak++;
      }
      
      if (tempStreak > bestStreak) bestStreak = tempStreak;
      if (i > 365) break; // Safety limit
    }

    // 3. Medicine Breakdown
    List<Map<String, dynamic>> medicineStats = [];
    int totalDosesEvaluated = 0;
    int onTimeDoses = 0;

    for (var medicine in activeMedicines) {
      final start = DateTime(medicine.startTime.year, medicine.startTime.month, medicine.startTime.day);
      final daysCount = today.difference(start).inDays + 1;
      
      int mScheduled = 0;
      for (int i = 0; i < daysCount; i++) {
        final currentDate = start.add(Duration(days: i));
        final isToday = currentDate.year == today.year && currentDate.month == today.month && currentDate.day == today.day;
        
        bool isDoseDay = false;
        if (medicine.interval == 1) isDoseDay = true;
        else if (medicine.interval == 7) isDoseDay = currentDate.weekday == start.weekday;
        else isDoseDay = currentDate.difference(start).inDays % medicine.interval == 0;

        if (isDoseDay) {
          for (var slot in medicine.timeSlots) {
            if (isToday) {
              final slotTime = _parseSlotTime(slot);
              if (slotTime != null) {
                final scheduledDT = DateTime(today.year, today.month, today.day, slotTime.hour, slotTime.minute);
                if (now.isAfter(scheduledDT)) mScheduled++;
              }
            } else {
              mScheduled++;
            }
          }
        }
      }

      int mTaken = medicine.takenHistory.where((dt) {
        final d = DateTime(dt.year, dt.month, dt.day);
        return !d.isBefore(start) && !d.isAfter(today);
      }).length;

      // 4. Time Accuracy (Was it taken within 30 mins?)
      for (var takenDate in medicine.takenHistory) {
        // Find corresponding slot
        for (var slot in medicine.timeSlots) {
          final slotTime = _parseSlotTime(slot);
          if (slotTime != null) {
            final scheduledToday = DateTime(takenDate.year, takenDate.month, takenDate.day, slotTime.hour, slotTime.minute);
            final diff = takenDate.difference(scheduledToday).inMinutes.abs();
            if (diff <= 30) {
              onTimeDoses++;
              break; 
            }
          }
        }
      }
      totalDosesEvaluated += mTaken;

      medicineStats.add({
        'name': medicine.name,
        'percentage': mScheduled > 0 ? (mTaken / mScheduled) * 100 : 100.0,
        'taken': mTaken,
        'scheduled': mScheduled,
      });
    }

    // 5. Activity Log (Last 10 events)
    List<Map<String, dynamic>> activityLog = [];
    for (var medicine in activeMedicines) {
      for (var dt in medicine.takenHistory) {
        activityLog.add({
          'name': medicine.name,
          'time': dt,
          'type': 'taken',
        });
      }
    }
    activityLog.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));
    activityLog = activityLog.take(10).toList();

    // 6. Rank Logic
    final overallAdherence = getAdherenceStats()['percentage'];
    String rank = 'Bronze';
    if (overallAdherence >= 95) rank = 'Platinum';
    else if (overallAdherence >= 85) rank = 'Gold';
    else if (overallAdherence >= 70) rank = 'Silver';

    // 7. Time of Day Analysis
    Map<String, int> takenBySlot = {'Morning': 0, 'Noon': 0, 'Night': 0};
    int totalTakenDoses = 0;
    for (var medicine in activeMedicines) {
      for (var dt in medicine.takenHistory) {
        totalTakenDoses++;
        if (dt.hour >= 5 && dt.hour < 12) takenBySlot['Morning'] = takenBySlot['Morning']! + 1;
        else if (dt.hour >= 12 && dt.hour < 17) takenBySlot['Noon'] = takenBySlot['Noon']! + 1;
        else if (dt.hour >= 17 || dt.hour < 5) takenBySlot['Night'] = takenBySlot['Night']! + 1;
      }
    }
    String bestTime = 'None';
    int maxTaken = 0;
    takenBySlot.forEach((k, v) {
      if (v > maxTaken) {
        maxTaken = v;
        bestTime = k;
      }
    });

    // 8. XP & Level System
    int totalXP = totalTakenDoses * 10;
    int level = (totalXP / 100).floor() + 1;
    double levelProgress = (totalXP % 100) / 100;

    // 9. Monthly Heatmap (Last 30 days)
    List<double> monthlyHeatmap = [];
    for (int i = 29; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      int scheduled = 0;
      int taken = 0;
      
      for (var med in activeMedicines) {
        final start = DateTime(med.startTime.year, med.startTime.month, med.startTime.day);
        if (date.isBefore(start)) continue;

        bool isDoseDay = false;
        if (med.interval == 1) isDoseDay = true;
        else if (med.interval == 7) isDoseDay = date.weekday == start.weekday;
        else isDoseDay = date.difference(start).inDays % med.interval == 0;

        if (isDoseDay) {
          scheduled += med.timeSlots.length;
          taken += med.takenHistory.where((dt) => dt.year == date.year && dt.month == date.month && dt.day == date.day).length;
        }
      }
      monthlyHeatmap.add(scheduled > 0 ? (taken / scheduled).clamp(0.0, 1.0) : 1.0);
    }

    // 10. Weekly Comparison
    double lastWeekAdherence = 0;
    int lwScheduled = 0;
    int lwTaken = 0;
    for (int i = 13; i >= 7; i--) {
       final date = today.subtract(Duration(days: i));
       for (var med in activeMedicines) {
          final start = DateTime(med.startTime.year, med.startTime.month, med.startTime.day);
          if (date.isBefore(start)) continue;
          bool isDoseDay = false;
          if (med.interval == 1) isDoseDay = true;
          else if (med.interval == 7) isDoseDay = date.weekday == start.weekday;
          else isDoseDay = date.difference(start).inDays % med.interval == 0;
          if (isDoseDay) {
            lwScheduled += med.timeSlots.length;
            lwTaken += med.takenHistory.where((dt) => dt.year == date.year && dt.month == date.month && dt.day == date.day).length;
          }
       }
    }
    lastWeekAdherence = lwScheduled > 0 ? (lwTaken / lwScheduled) * 100 : 100.0;
    double comparison = overallAdherence - lastWeekAdherence;

    // 11. Achievements
    List<Map<String, dynamic>> achievements = [
      {'title': 'Alpha', 'icon': Icons.bolt_rounded, 'unlocked': totalTakenDoses >= 1},
      {'title': 'Consistent', 'icon': Icons.calendar_today_rounded, 'unlocked': currentStreak >= 3},
      {'title': 'Master', 'icon': Icons.emoji_events_rounded, 'unlocked': currentStreak >= 7},
      {'title': 'Punctual', 'icon': Icons.timer_rounded, 'unlocked': (totalDosesEvaluated > 0 ? (onTimeDoses / totalDosesEvaluated) * 100 : 0) >= 90},
    ];

    return {
      'weeklyTrend': weeklyTrend,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'medicineStats': medicineStats,
      'timeAccuracy': totalDosesEvaluated > 0 ? (onTimeDoses / totalDosesEvaluated) * 100 : 100.0,
      'activityLog': activityLog,
      'rank': rank,
      'bestTime': bestTime,
      'totalXP': totalXP,
      'level': level,
      'levelProgress': levelProgress,
      'heatmap': monthlyHeatmap,
      'comparison': comparison,
      'achievements': achievements,
    };
  }

  List<Map<String, dynamic>> getActiveDaysHistory() {
    final Map<String, Map<String, dynamic>> days = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // 1. Find the earliest start and latest end dates among currently active medicines
    DateTime? earliestStart;
    DateTime? latestEnd;
    
    for (var medicine in activeMedicines) {
      final start = DateTime(medicine.startTime.year, medicine.startTime.month, medicine.startTime.day);
      if (earliestStart == null || start.isBefore(earliestStart)) {
        earliestStart = start;
      }
      
      final currentMedEnd = medicine.endDate != null 
          ? DateTime(medicine.endDate!.year, medicine.endDate!.month, medicine.endDate!.day)
          : today;
          
      if (latestEnd == null || currentMedEnd.isAfter(latestEnd)) {
        latestEnd = currentMedEnd;
      }
    }

    if (earliestStart == null || latestEnd == null) return [];
    
    // Ensure history range starts from the first medicine and always goes up to Today
    final actualEnd = (latestEnd == null || latestEnd.isBefore(today)) ? today : latestEnd;

    // 2. Build a continuous timeline from earliest start to actual end
    final daysCount = actualEnd.difference(earliestStart).inDays + 1;
    for (int i = 0; i < daysCount; i++) {
      final currentDate = earliestStart.add(Duration(days: i));
      final dateKey = '${currentDate.year}-${currentDate.month}-${currentDate.day}';
      
      days[dateKey] = {
        'date': currentDate,
        'takenCount': 0,
        'scheduledCount': 0,
      };

      // 3. For each day, check currently active medicines
      for (var medicine in activeMedicines) {
        final medStart = DateTime(medicine.startTime.year, medicine.startTime.month, medicine.startTime.day);
        
        // Skip if medicine hadn't started yet or had already ended
        if (currentDate.isBefore(medStart)) continue;
        if (medicine.endDate != null && currentDate.isAfter(medicine.endDate!)) continue;

        // Check if it's a dose day for THIS medicine
        bool isDoseDay = false;
        if (medicine.interval == 1) isDoseDay = true;
        else if (medicine.interval == 7) isDoseDay = currentDate.weekday == medStart.weekday;
        else isDoseDay = currentDate.difference(medStart).inDays % medicine.interval == 0;

        if (isDoseDay) {
          final int totalSlots = medicine.timeSlots.length;
          days[dateKey]!['scheduledCount'] = (days[dateKey]!['scheduledCount'] as int) + totalSlots;

          // Count taken doses (manual + auto)
          final manualTaken = medicine.takenHistory.where((dt) => 
            dt.year == currentDate.year && dt.month == currentDate.month && dt.day == currentDate.day
          ).length;

          int autoTaken = 0;
          for (var slot in medicine.timeSlots) {
            final time = _parseSlotTime(slot);
            if (time != null) {
              final scheduledDT = DateTime(currentDate.year, currentDate.month, currentDate.day, time.hour, time.minute);
              if (now.isAfter(scheduledDT)) {
                autoTaken++;
              }
            }
          }
          days[dateKey]!['takenCount'] = (days[dateKey]!['takenCount'] as int) + (manualTaken > autoTaken ? manualTaken : autoTaken);
        }
      }
    }
    
    final List<Map<String, dynamic>> result = [];
    
    days.forEach((key, data) {
      final int scheduled = data['scheduledCount'];
      final int taken = data['takenCount'];
      
      final double percentage = scheduled > 0 ? (taken / scheduled).clamp(0.0, 1.0) : 1.0;
          
      result.add({
        'date': data['date'],
        'percentage': percentage,
        'taken': taken,
        'scheduled': scheduled,
      });
    });
    
    // Sort descending (newest activity first)
    result.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    return result;
  }
  
  Map<String, dynamic> getStatsForDay(DateTime date) {
    final now = DateTime.now();
    final targetDate = DateTime(date.year, date.month, date.day);
    List<Map<String, dynamic>> takenMeds = [];
    List<Map<String, dynamic>> upcomingMeds = [];
    
    for (var medicine in activeMedicines) {
        final start = DateTime(medicine.startTime.year, medicine.startTime.month, medicine.startTime.day);
        if (targetDate.isBefore(start)) continue;
        if (medicine.endDate != null) {
             final end = DateTime(medicine.endDate!.year, medicine.endDate!.month, medicine.endDate!.day);
             if (targetDate.isAfter(end)) continue;
        }

        bool isDoseDay = false;
        if (medicine.interval == 1) isDoseDay = true;
        else if (medicine.interval == 7) isDoseDay = targetDate.weekday == start.weekday;
        else isDoseDay = targetDate.difference(start).inDays % medicine.interval == 0;
        
        if (!isDoseDay) continue;

        final manualTakenToday = medicine.takenHistory.where((dt) => 
           dt.year == targetDate.year && dt.month == targetDate.month && dt.day == targetDate.day
        ).toList();
        
        int autoTakenCount = 0;
        List<DateTime> displayHistory = List.from(manualTakenToday);

        for (var slot in medicine.timeSlots) {
          final time = _parseSlotTime(slot);
          if (time != null) {
            final scheduledToday = DateTime(targetDate.year, targetDate.month, targetDate.day, time.hour, time.minute);
            if (now.isAfter(scheduledToday)) {
              autoTakenCount++;
              // If not already in manual history, add a "placeholder" for display
              bool alreadyTracked = manualTakenToday.any((dt) => dt.hour == time.hour && dt.minute == time.minute);
              if (!alreadyTracked) {
                displayHistory.add(scheduledToday);
              }
            }
          }
        }

        final finalTakenCount = manualTakenToday.length > autoTakenCount ? manualTakenToday.length : autoTakenCount;

        if (finalTakenCount > 0) {
           takenMeds.add({
             'medicine': medicine,
             'takenCount': finalTakenCount,
             'totalSlots': medicine.timeSlots.length,
             'history': displayHistory..sort(),
           });
        }

        // Upcoming doses (only relevant if targetDate is today or future, though history usually only shows today/past)
        if (targetDate.isAtSameMomentAs(DateTime(now.year, now.month, now.day))) {
            List<String> upcomingSlots = [];
            for (var slot in medicine.timeSlots) {
              final time = _parseSlotTime(slot);
              if (time != null) {
                final scheduledToday = DateTime(targetDate.year, targetDate.month, targetDate.day, time.hour, time.minute);
                if (scheduledToday.isAfter(now)) {
                  upcomingSlots.add(slot);
                }
              }
            }
            if (upcomingSlots.isNotEmpty) {
              upcomingMeds.add({
                'medicine': medicine,
                'slots': upcomingSlots,
              });
            }
        }
    }
    
    return {
      'date': targetDate,
      'taken': takenMeds,
      'upcoming': upcomingMeds,
    };
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
    final normalizedDate = DateTime(targetDate.year, targetDate.month, targetDate.day);
    
    // Ensure we are working with a fresh mutable list to trigger Hive detection
    final List<DateTime> newHistory = List<DateTime>.from(medicine.takenHistory);

    if (timeSlot != null) {
      final pivotIndex = timeSlot.indexOf(':');
      final timeStr = pivotIndex != -1 ? timeSlot.substring(pivotIndex + 1).trim() : timeSlot;
      
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
      
      final bool alreadyTaken = newHistory.any((dt) => 
        dt.year == normalizedDate.year && 
        dt.month == normalizedDate.month && 
        dt.day == normalizedDate.day &&
        dt.hour == hour &&
        dt.minute == minute
      );
      
      if (alreadyTaken) {
        newHistory.removeWhere((dt) => 
            dt.year == normalizedDate.year && 
            dt.month == normalizedDate.month && 
            dt.day == normalizedDate.day &&
            dt.hour == hour &&
            dt.minute == minute
        );
      } else {
        newHistory.add(DateTime(normalizedDate.year, normalizedDate.month, normalizedDate.day, hour, minute));
      }
      
    } else {
      final todayEntries = newHistory.where(
        (d) => d.year == normalizedDate.year && d.month == normalizedDate.month && d.day == normalizedDate.day,
      ).toList();
      
      if (todayEntries.length < (medicine.timeSlots.isNotEmpty ? medicine.timeSlots.length : 1)) {
         newHistory.add(DateTime(normalizedDate.year, normalizedDate.month, normalizedDate.day, DateTime.now().hour, DateTime.now().minute));
      } else {
         newHistory.removeWhere(
          (d) => d.year == normalizedDate.year && d.month == normalizedDate.month && d.day == normalizedDate.day,
        );
      }
    }

    // Force re-assignment to ensure Hive detects change
    medicine.takenHistory = newHistory;
    await medicine.save();
    
    // Explicitly refresh from database
    await loadMedicines();
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

  Future<void> _loadProfile() async {
    final box = await Hive.openBox('settings');
    final name = box.get('userName', defaultValue: 'User Name');
    final avatar = box.get('userAvatar', defaultValue: 'assets/avatar/Aven.jpg');
    final bloodGroup = box.get('userBloodGroup', defaultValue: 'Select');
    final weight = box.get('userWeight', defaultValue: '—');
    final allergies = box.get('userAllergies', defaultValue: 'None');
    
    _userProfile = {
      'name': name,
      'avatar': avatar,
      'bloodGroup': bloodGroup,
      'weight': weight,
      'allergies': allergies,
    };
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String avatar,
    String? bloodGroup,
    String? weight,
    String? allergies,
  }) async {
    _userProfile['name'] = name;
    _userProfile['avatar'] = avatar;
    if (bloodGroup != null) _userProfile['bloodGroup'] = bloodGroup;
    if (weight != null) _userProfile['weight'] = weight;
    if (allergies != null) _userProfile['allergies'] = allergies;
    
    final box = await Hive.openBox('settings');
    await box.put('userName', name);
    await box.put('userAvatar', avatar);
    if (bloodGroup != null) await box.put('userBloodGroup', bloodGroup);
    if (weight != null) await box.put('userWeight', weight);
    if (allergies != null) await box.put('userAllergies', allergies);
    
    notifyListeners();
  }
}
