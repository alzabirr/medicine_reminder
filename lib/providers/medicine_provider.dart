import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:medi/models/medicine.dart';
import 'package:medi/services/database_service.dart';
import 'package:medi/services/notification_service.dart';
import 'package:medi/utils/medicine_utils.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class MedicineProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  NotificationService get notificationService => _notificationService;
  
  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  String _notificationSound = 'default';
  String get notificationSound => _notificationSound;

  Map<String, String> _userProfile = {
    'name': 'User Name',
    'avatar': 'assets/avatar/Aven.jpg',
    'bloodGroup': 'Select',
    'weight': '—',
    'height': '—',
    'age': '—',
    'gender': 'Select',
  };
  Map<String, String> get userProfile => _userProfile;

  List<Map<String, String>> _emergencyContacts = [];
  List<Map<String, String>> get emergencyContacts => _emergencyContacts;

  double? get bmi {
    // Try to extract numbers from potentially flexible strings like "65 kg" or "5'8 ft"
    final weightStr = _userProfile['weight']?.replaceAll(RegExp(r'[^0-9.]'), '');
    
    double? weight = double.tryParse(weightStr ?? '');
    double? heightInMeters;

    final hStr = _userProfile['height']?.toLowerCase() ?? '';
    
    // Check if height is in feet/inches format e.g. "5.8" or "5'8"
    if (hStr.contains("'") || hStr.contains("ft")) {
       final parts = hStr.split(RegExp(r"['\sft]+"));
       if (parts.length >= 2) {
         final feet = double.tryParse(parts[0]);
         final inches = double.tryParse(parts[1]);
         if (feet != null && inches != null) {
           final totalInches = (feet * 12) + inches;
           heightInMeters = totalInches * 0.0254;
         }
       } else if (parts.isNotEmpty) {
         final feet = double.tryParse(parts[0]);
         if (feet != null) {
           heightInMeters = feet * 0.3048;
         }
       }
    } else {
      final filteredHStr = hStr.replaceAll(RegExp(r'[^0-9.]'), '');
      if (filteredHStr.isNotEmpty) {
        final hNum = double.tryParse(filteredHStr);
        if (hNum != null && hNum > 0) {
          if (hNum < 3) {
            // Likely Meters (e.g. 1.72)
            heightInMeters = hNum;
          } else if (hNum < 10) {
            // Likely Feet (e.g. 5.8)
            heightInMeters = hNum * 0.3048;
          } else {
            // Likely Centimeters (e.g. 172)
            heightInMeters = hNum / 100;
          }
        }
      }
    }
    
    if (weight != null && heightInMeters != null && heightInMeters > 0) {
      return weight / (heightInMeters * heightInMeters);
    }
    return null;
  }

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
    
    // Load profile and preferences FIRST before scheduling
    await _loadProfile();
    
    await loadMedicines();
    
    // Initial schedule refresh on app startup - will only run if notifications are enabled
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
        if (medicine.interval == 1) {
          isDoseDay = true;
        } else if (medicine.interval == 7) {
          isDoseDay = currentDate.weekday == start.weekday;
        } else {
          isDoseDay = currentDate.difference(start).inDays % medicine.interval == 0;
        }

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
        if (medicine.interval == 1) {
          isDoseDay = true;
        } else if (medicine.interval == 7) {
          isDoseDay = currentDate.weekday == start.weekday;
        } else {
          isDoseDay = currentDate.difference(start).inDays % medicine.interval == 0;
        }

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

    // 6. Overall Adherence
    final overallAdherence = getAdherenceStats()['percentage'];

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
        if (med.interval == 1) {
          isDoseDay = true;
        } else if (med.interval == 7) {
          isDoseDay = date.weekday == start.weekday;
        } else {
          isDoseDay = date.difference(start).inDays % med.interval == 0;
        }

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
          if (med.interval == 1) {
            isDoseDay = true;
          } else if (med.interval == 7) {
            isDoseDay = date.weekday == start.weekday;
          } else {
            isDoseDay = date.difference(start).inDays % med.interval == 0;
          }
          if (isDoseDay) {
            lwScheduled += med.timeSlots.length;
            lwTaken += med.takenHistory.where((dt) => dt.year == date.year && dt.month == date.month && dt.day == date.day).length;
          }
       }
    }
    lastWeekAdherence = lwScheduled > 0 ? (lwTaken / lwScheduled) * 100 : 100.0;
    double comparison = overallAdherence - lastWeekAdherence;

    // 11. Achievements


    return {
      'weeklyTrend': weeklyTrend,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'medicineStats': medicineStats,
      'timeAccuracy': totalDosesEvaluated > 0 ? (onTimeDoses / totalDosesEvaluated) * 100 : 100.0,
      'activityLog': activityLog,
      'bestTime': bestTime,
      'totalXP': totalXP,
      'level': level,
      'levelProgress': levelProgress,
      'heatmap': monthlyHeatmap,
      'comparison': comparison,
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
        if (medicine.interval == 1) {
          isDoseDay = true;
        } else if (medicine.interval == 7) {
          isDoseDay = currentDate.weekday == medStart.weekday;
        } else {
          isDoseDay = currentDate.difference(medStart).inDays % medicine.interval == 0;
        }

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
        if (medicine.interval == 1) {
          isDoseDay = true;
        } else if (medicine.interval == 7) {
          isDoseDay = targetDate.weekday == start.weekday;
        } else {
          isDoseDay = targetDate.difference(start).inDays % medicine.interval == 0;
        }
        
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
    // Reload first so the new medicine is part of the schedule plan
    await loadMedicines();
    await refreshAllSchedules(); // Centralized scheduling
  }

  // Soft Delete: Move to Trash
  Future<void> deleteMedicine(String id) async {
    final medicineIndex = _medicines.indexWhere((m) => m.id == id);
    if (medicineIndex != -1) {
       final medicine = _medicines[medicineIndex];

       // Soft delete
       medicine.isDeleted = true;
       await medicine.save();
    }

    await loadMedicines();
    // Removes this medicine's reminders
    await refreshAllSchedules();
  }

  // Restore from Trash
  Future<void> restoreMedicine(Medicine medicine) async {
    medicine.isDeleted = false;
    await medicine.save();

    await loadMedicines();

    // Reschedule notifications
    await refreshAllSchedules();
  }

  // Hard Delete: Permanent Removal
  Future<void> deletePermanently(String id) async {
    await _databaseService.deleteMedicine(id);
    await loadMedicines();
    await refreshAllSchedules();
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
    // 1. Update Medicine Object
    medicine.name = name;
    medicine.type = type;
    medicine.timeSlots = timeSlots;
    medicine.instruction = instruction;
    medicine.startTime = startDate;
    medicine.endDate = endDate;
    if (imagePath != null) medicine.imagePath = imagePath;
    if (frequency != null) medicine.interval = frequency;
    
    await medicine.save();

    // 2. Re-sync notifications (old slots are removed, new ones added)
    await loadMedicines();
    await refreshAllSchedules();
  }

  // ---------------------------------------------------------------------------
  // Notification scheduling
  //
  // Every refresh builds the full list of reminders that *should* exist and
  // diffs it against what is actually scheduled in the OS. This keeps the
  // number of alarms under Android's per-app limit (500 – going over makes new
  // alarms silently fail), never schedules dates in the past, and repairs any
  // alarm the system dropped.
  // ---------------------------------------------------------------------------

  /// Keep well below Android's 500 concurrent alarm limit.
  static const int _maxScheduledAlarms = 400;

  /// How far ahead individual (non-repeating) reminders are scheduled.
  /// The window rolls forward every time the app is opened.
  static const int _scheduleWindowDays = 30;

  Future<void> _scheduleChain = Future.value();

  // Centralized Scheduling Logic. Calls are serialized so concurrent refreshes
  // (startup, resume, edits) can never interleave and undo each other.
  Future<void> refreshAllSchedules() {
    final next = _scheduleChain.then((_) => _syncSchedules()).catchError((Object e) {
      debugPrint('Error refreshing schedules: $e');
    });
    _scheduleChain = next;
    return next;
  }

  Future<void> _syncSchedules() async {
    if (!_notificationsEnabled) {
      await AwesomeNotifications().cancelAllSchedules();
      return;
    }

    final now = DateTime.now();
    debugPrint('Refreshing all schedules at $now');

    final planned = _buildReminderPlan(now);

    List<NotificationModel> existing = [];
    try {
      existing = await _notificationService.listScheduled();
    } catch (e) {
      debugPrint('Could not list scheduled notifications: $e');
    }

    final Map<int, String?> existingSigs = {};
    for (final model in existing) {
      final id = model.content?.id;
      if (id != null) existingSigs[id] = model.content?.payload?['sig'];
    }

    // 1. Remove schedules that are no longer wanted
    final plannedIds = planned.map((r) => r.id).toSet();
    for (final id in existingSigs.keys) {
      if (!plannedIds.contains(id)) {
        try {
          await _notificationService.cancelSchedule(id);
        } catch (e) {
          debugPrint('Error cancelling schedule $id: $e');
        }
      }
    }

    // 2. Create missing or changed schedules
    int created = 0;
    for (final r in planned) {
      if (existingSigs[r.id] == r.signature) continue;
      try {
        await _notificationService.scheduleNotification(
          id: r.id,
          title: r.title,
          body: r.body,
          hour: r.hour,
          minute: r.minute,
          weekday: r.weekday,
          day: r.day,
          repeats: r.repeats,
          payload: {'medicineId': r.medicineId, 'sig': r.signature},
        );
        created++;
      } catch (e) {
        debugPrint('Error scheduling notification ${r.id}: $e');
      }
    }
    debugPrint('Schedules synced: ${planned.length} planned, $created (re)created');
  }

  List<_PlannedReminder> _buildReminderPlan(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final windowEnd = DateTime(today.year, today.month, today.day + _scheduleWindowDays);
    final channel = _notificationService.currentChannelKey;

    final List<_PlannedReminder> repeating = [];
    final List<_PlannedReminder> oneOff = [];

    for (final medicine in activeMedicines) {
      final start = DateTime(medicine.startTime.year, medicine.startTime.month, medicine.startTime.day);
      final end = medicine.endDate != null
          ? DateTime(medicine.endDate!.year, medicine.endDate!.month, medicine.endDate!.day)
          : null;

      // Already finished
      if (end != null && end.isBefore(today)) continue;

      final interval = medicine.interval < 1 ? 1 : medicine.interval;
      final prefix = interval == 1 ? 'Daily' : (interval == 7 ? 'Weekly' : 'Medi');
      final title = '$prefix: ${medicine.name}';

      // Unique times only: two slots at the same minute would be one alarm anyway
      final Map<String, ({String label, TimeOfDay time})> slots = {};
      for (final slotString in medicine.timeSlots) {
        final parsed = MedicineUtils.parseSlot(slotString);
        if (parsed == null) {
          debugPrint('Skipping unparseable time slot "$slotString" of ${medicine.name}');
          continue;
        }
        slots.putIfAbsent('${parsed.time.hour}:${parsed.time.minute}', () => parsed);
      }

      for (final slot in slots.values) {
        final hour = slot.time.hour;
        final minute = slot.time.minute;
        final body = [
          slot.label.isNotEmpty ? '${slot.label} dose' : 'Time for your dose',
          if (medicine.instruction != null && medicine.instruction!.isNotEmpty) medicine.instruction!,
        ].join(' • ');
        final hhmm = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

        // A single repeating alarm is used when the course has already started
        // and doesn't end within the window. Once the end date falls inside
        // the window (on a later refresh) it switches to individual alarms.
        final canRepeat = (interval == 1 || interval == 7) &&
            !start.isAfter(today) &&
            (end == null || end.isAfter(windowEnd));

        if (canRepeat) {
          final weekday = interval == 7 ? start.weekday : null;
          final key = '${medicine.id}|repeat|$interval|$hhmm';
          repeating.add(_PlannedReminder(
            id: _stableId(key),
            signature: _stableHash('$key|$title|$body|$channel|${weekday ?? ''}').toRadixString(16),
            medicineId: medicine.id,
            title: title,
            body: body,
            hour: hour,
            minute: minute,
            weekday: weekday,
            repeats: true,
            fireAt: _nextOccurrence(now, hour, minute, weekday),
          ));
          continue;
        }

        for (var date = start.isAfter(today) ? start : today;
            !date.isAfter(windowEnd) && (end == null || !date.isAfter(end));
            date = DateTime(date.year, date.month, date.day + 1)) {
          if (!_isDoseDay(date, start, interval)) continue;

          final fireAt = DateTime(date.year, date.month, date.day, hour, minute);
          if (!fireAt.isAfter(now)) continue; // never schedule in the past
          if (_isDoseTaken(medicine, fireAt)) continue; // already marked as taken

          final dateKey = '${date.year}-${date.month}-${date.day}';
          final key = '${medicine.id}|$dateKey|$hhmm';
          oneOff.add(_PlannedReminder(
            id: _stableId(key),
            signature: _stableHash('$key|$title|$body|$channel').toRadixString(16),
            medicineId: medicine.id,
            title: title,
            body: body,
            hour: hour,
            minute: minute,
            day: date,
            repeats: false,
            fireAt: fireAt,
          ));
        }
      }
    }

    // Respect the alarm budget: nearest reminders win, the rest get scheduled
    // on a later refresh as the window moves forward.
    oneOff.sort((a, b) => a.fireAt.compareTo(b.fireAt));
    final budget = _maxScheduledAlarms - repeating.length;
    final plan = [...repeating, ...oneOff.take(budget < 0 ? 0 : budget)];

    // Guard against (extremely unlikely) ID collisions
    final seen = <int>{};
    return plan.where((r) => seen.add(r.id)).toList();
  }

  static bool _isDoseDay(DateTime date, DateTime start, int interval) {
    if (interval == 1) return true;
    if (interval == 7) return date.weekday == start.weekday;
    // Count days in UTC so DST transitions don't shift the cycle
    final days = DateTime.utc(date.year, date.month, date.day)
        .difference(DateTime.utc(start.year, start.month, start.day))
        .inDays;
    return days >= 0 && days % interval == 0;
  }

  static bool _isDoseTaken(Medicine medicine, DateTime fireAt) {
    return medicine.takenHistory.any((dt) =>
        dt.year == fireAt.year &&
        dt.month == fireAt.month &&
        dt.day == fireAt.day &&
        dt.hour == fireAt.hour &&
        dt.minute == fireAt.minute);
  }

  static DateTime _nextOccurrence(DateTime now, int hour, int minute, int? weekday) {
    var candidate = DateTime(now.year, now.month, now.day, hour, minute);
    while (!candidate.isAfter(now) || (weekday != null && candidate.weekday != weekday)) {
      candidate = DateTime(candidate.year, candidate.month, candidate.day + 1, hour, minute);
    }
    return candidate;
  }

  /// FNV-1a: unlike String.hashCode it is identical across app runs and
  /// Dart versions, so IDs stay stable between refreshes and app updates.
  static int _stableHash(String input) {
    int hash = 0x811c9dc5;
    for (final unit in utf8.encode(input)) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  /// Positive, non-zero 31-bit notification id.
  static int _stableId(String key) {
    final id = _stableHash(key) & 0x7FFFFFFF;
    return id == 0 ? 1 : id;
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

    // Skip the reminder for a dose marked as taken early (or restore it)
    await refreshAllSchedules();
  }

  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    await _saveNotificationPreferences();
    notifyListeners();

    // Cancels everything when disabled, reschedules when enabled
    await refreshAllSchedules();
  }

  Future<void> setNotificationSound(String soundPath) async {
    _notificationSound = soundPath;
    await _saveNotificationPreferences();
    
    // Update the notification channel with the new sound (creates a new channel key on Android)
    await _notificationService.updateNotificationChannel(soundPath);
    
    // Force reschedule all notifications to use the new channel with the new sound
    await refreshAllSchedules();
    
    notifyListeners();
  }

  List<Map<String, String>> getDefaultSounds() {
    return [
      {'name': 'System Default', 'path': 'default'},
      {'name': 'Gentle Bell 🔔', 'path': 'assets/sounds/notification_gentle.mp3'},
      {'name': 'Soft Chime ✨', 'path': 'assets/sounds/notification_chime.wav'},
      {'name': 'Soft Touch 🌸', 'path': 'assets/sounds/notification_soft.mp3'},
      {'name': 'Knock Knock 🚪', 'path': 'assets/sounds/notification_knock.mp3'},
      {'name': 'Playful 🎵', 'path': 'assets/sounds/notification_playful.mp3'},
      {'name': 'Medicine Reminder 💊', 'path': 'assets/sounds/notification_reminder.mp3'},
      {'name': 'Death Note 📓', 'path': 'assets/sounds/death_note.mp3'},
      {'name': 'Suzume ✨', 'path': 'assets/sounds/suzume_no_tojimari.mp3'},
    ];
  }

  Future<void> _loadProfile() async {
    final box = await Hive.openBox('settings');
    final name = box.get('userName', defaultValue: 'User Name');
    final avatar = box.get('userAvatar', defaultValue: 'assets/avatar/Aven.jpg');
    final bloodGroup = box.get('userBloodGroup', defaultValue: 'Select');
    final weight = box.get('userWeight', defaultValue: '—');
    final height = box.get('userHeight', defaultValue: '—');
    final age = box.get('userAge', defaultValue: '—');
    final gender = box.get('userGender', defaultValue: 'Select');
    
    _userProfile = {
      'name': name,
      'avatar': avatar,
      'bloodGroup': bloodGroup,
      'weight': weight,
      'height': height,
      'age': age,
      'gender': gender,
    };
    
    final ecListJson = box.get('emergencyContacts', defaultValue: '[]');
    try {
      final List<dynamic> decoded = jsonDecode(ecListJson);
      _emergencyContacts = decoded.map((e) => Map<String, String>.from(e)).toList();
    } catch (e) {
      _emergencyContacts = [];
    }

    await _loadNotificationPreferences();
    notifyListeners();
  }

  Future<void> _saveNotificationPreferences() async {
    final box = await Hive.openBox('settings');
    await box.put('notificationsEnabled', _notificationsEnabled);
    await box.put('notificationSound', _notificationSound);
  }

  Future<void> _loadNotificationPreferences() async {
    final box = await Hive.openBox('settings');
    _notificationsEnabled = box.get('notificationsEnabled', defaultValue: true);
    _notificationSound = box.get('notificationSound', defaultValue: 'default');
    
    // Ensure channel is up to date with saved preference
    await _notificationService.updateNotificationChannel(_notificationSound);
  }

  Future<void> updateProfile({
    required String name,
    required String avatar,
    String? bloodGroup,
    String? weight,
    String? height,
    String? age,
    String? gender,
  }) async {
    _userProfile['name'] = name;
    _userProfile['avatar'] = avatar;
    if (bloodGroup != null) _userProfile['bloodGroup'] = bloodGroup;
    if (weight != null) _userProfile['weight'] = weight;
    if (height != null) _userProfile['height'] = height;
    if (age != null) _userProfile['age'] = age;
    if (gender != null) _userProfile['gender'] = gender;
    
    final box = await Hive.openBox('settings');
    await box.put('userName', name);
    await box.put('userAvatar', avatar);
    if (bloodGroup != null) await box.put('userBloodGroup', bloodGroup);
    if (weight != null) await box.put('userWeight', weight);
    if (height != null) await box.put('userHeight', height);
    if (age != null) await box.put('userAge', age);
    if (gender != null) await box.put('userGender', gender);
    
    notifyListeners();
  }

  Future<void> addEmergencyContact(String name, String phone) async {
    _emergencyContacts = [
      ..._emergencyContacts,
      {'name': name, 'phone': phone, 'isPrimary': 'false'}
    ];
    await _saveEmergencyContacts();
    notifyListeners();
  }

  Future<void> updateEmergencyContact(int index, String name, String phone) async {
    if (index >= 0 && index < _emergencyContacts.length) {
      final oldContact = _emergencyContacts[index];
      final isPrimary = oldContact['isPrimary'] == 'true';
      
      final newList = List<Map<String, String>>.from(_emergencyContacts);
      newList[index] = {
        'name': name, 
        'phone': phone,
        'isPrimary': isPrimary.toString()
      };
      _emergencyContacts = newList;
      await _saveEmergencyContacts();
      notifyListeners();
    }
  }

  Future<void> removeEmergencyContact(int index) async {
    if (index >= 0 && index < _emergencyContacts.length) {
      final newList = List<Map<String, String>>.from(_emergencyContacts);
      newList.removeAt(index);
      _emergencyContacts = newList;
      await _saveEmergencyContacts();
      notifyListeners();
    }
  }

  Future<void> setPrimaryContact(int index) async {
    if (index >= 0 && index < _emergencyContacts.length) {
      final newList = _emergencyContacts.map((c) {
        final contact = Map<String, String>.from(c);
        contact['isPrimary'] = 'false';
        return contact;
      }).toList();
      
      newList[index]['isPrimary'] = 'true';
      _emergencyContacts = newList;
      
      await _saveEmergencyContacts();
      notifyListeners();
    }
  }
  
  Future<void> _saveEmergencyContacts() async {
    final box = await Hive.openBox('settings');
    await box.put('emergencyContacts', jsonEncode(_emergencyContacts));
  }
}

class _PlannedReminder {
  final int id;
  final String signature;
  final String medicineId;
  final String title;
  final String body;
  final int hour;
  final int minute;
  final int? weekday;
  final DateTime? day;
  final bool repeats;
  final DateTime fireAt;

  const _PlannedReminder({
    required this.id,
    required this.signature,
    required this.medicineId,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
    this.weekday,
    this.day,
    required this.repeats,
    required this.fireAt,
  });
}
