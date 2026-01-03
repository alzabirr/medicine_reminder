import 'package:flutter/material.dart';
import 'package:medi/models/medicine.dart';

class MedicineUtils {
  /// Parses a time string like "Morning: 08:00 AM" or "20:00" into a TimeOfDay.
  static TimeOfDay? parseTime(String timeSlot) {
    try {
      // final pivotIndex = timeSlot.indexOf(':'); // Removed unused

      // If we have a label like "Morning: ...", skip it. 
      // But wait, hours also have ':' (e.g. 08:00). 
      // We need to be careful. Usually labels are "Label: 08:00 AM".
      // Let's look for the *last* colon, or rely on regex like the provider does.
      
      // Let's use the same robust regex strategy as the provider for consistency.
      final RegExp timeRegex = RegExp(r'(\d{1,2})[:\s\u00A0\u2007\u202F]+(\d{2})\s*(AM|PM|am|pm)?');
      final match = timeRegex.firstMatch(timeSlot);

      if (match != null) {
        int h = int.parse(match.group(1)!);
        int m = int.parse(match.group(2)!);
        final period = match.group(3)?.toLowerCase();

        if (period == 'pm' && h != 12) h += 12;
        if (period == 'am' && h == 12) h = 0;

        return TimeOfDay(hour: h, minute: m);
      }
    } catch (e) {
      debugPrint('Error parsing time: $timeSlot - $e');
    }
    return null;
  }

  /// Returns the Duration until the next scheduled dose.
  /// For future medicines (start date in the future), returns time until start date.
  /// For current medicines, returns time until the next dose today/tomorrow.
  /// Returns null if all doses have passed and medicine has ended.
  static Duration? getTimeUntilNextDose(Medicine medicine, {int takenCount = 0}) {
    if (medicine.timeSlots.isEmpty) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(medicine.startTime.year, medicine.startTime.month, medicine.startTime.day);
    
    // If medicine hasn't started yet, show countdown to start date + first time slot
    if (today.isBefore(start)) {
      // Find the earliest time slot
      TimeOfDay? earliestTime;
      for (final slot in medicine.timeSlots) {
        final time = parseTime(slot);
        if (time == null) continue;
        
        if (earliestTime == null || 
            (time.hour < earliestTime.hour || 
             (time.hour == earliestTime.hour && time.minute < earliestTime.minute))) {
          earliestTime = time;
        }
      }
      
      if (earliestTime != null) {
        final startDateTime = DateTime(
          start.year,
          start.month,
          start.day,
          earliestTime.hour,
          earliestTime.minute,
        );
        return startDateTime.difference(now);
      }
      
      // If no valid time found, just return time to start date
      return start.difference(now);
    }
    
    // For current medicines, find next dose
    DateTime? nextDoseDate;

    // Sort time slots to ensure we skip the earliest ones correctly
    final List<TimeOfDay> sortedSlots = medicine.timeSlots
        .map((s) => parseTime(s))
        .where((t) => t != null)
        .cast<TimeOfDay>()
        .toList()
      ..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));

    // Check today's slots, skipping those already taken
    int skipped = 0;
    for (final time in sortedSlots) {
      if (skipped < takenCount) {
        skipped++;
        continue;
      }

      final scheduledDateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      
      if (scheduledDateTime.isAfter(now)) {
        if (nextDoseDate == null || scheduledDateTime.isBefore(nextDoseDate)) {
          nextDoseDate = scheduledDateTime;
        }
      }
    }

    // If no more slots today (everyone taken or passed), check future days
    if (nextDoseDate == null) {
      // Find the next VALID scheduled day
      DateTime searchDay = today.add(const Duration(days: 1));
      
      // Limit search to 365 days to prevent infinite loops (if medicine ended)
      for (int i = 0; i < 365; i++) {
        if (medicine.endDate != null) {
          final end = DateTime(medicine.endDate!.year, medicine.endDate!.month, medicine.endDate!.day);
          if (searchDay.isAfter(end)) return null; 
        }

        if (isScheduledForDay(medicine, searchDay)) {
          if (sortedSlots.isNotEmpty) {
            final time = sortedSlots.first;
            nextDoseDate = DateTime(searchDay.year, searchDay.month, searchDay.day, time.hour, time.minute);
            break;
          }
        }
        searchDay = searchDay.add(const Duration(days: 1));
      }
    }

    if (nextDoseDate != null) {
      return nextDoseDate.difference(now);
    }

    return null;
  }

  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      final minutes = duration.inMinutes % 60;
      final seconds = duration.inSeconds % 60;
      return '${duration.inHours}h ${minutes}m ${seconds}s';
    } else {
      final seconds = duration.inSeconds % 60;
      return '${duration.inMinutes}m ${seconds}s';
    }
  }

  static bool areAllTimeSlotsPassedToday(Medicine medicine, {int takenCount = 0, DateTime? checkDate}) {
    if (medicine.timeSlots.isEmpty) return false;

    final now = DateTime.now();
    final today = checkDate ?? DateTime(now.year, now.month, now.day);
    final todayMidnight = DateTime(today.year, today.month, today.day);

    // 1. If not scheduled for this day, it's technically "passed" (nothing to do)
    if (!isScheduledForDay(medicine, todayMidnight)) return true;

    // 2. Sort time slots
    final List<TimeOfDay> sortedSlots = medicine.timeSlots
        .map((s) => parseTime(s))
        .where((t) => t != null)
        .cast<TimeOfDay>()
        .toList()
      ..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));

    int passedOrTaken = 0;
    for (int i = 0; i < sortedSlots.length; i++) {
       if (i < takenCount) {
         passedOrTaken++;
         continue;
       }
       
       final time = sortedSlots[i];
       // Check if this specific slot time has passed on the target day
       final scheduledDateTime = DateTime(todayMidnight.year, todayMidnight.month, todayMidnight.day, time.hour, time.minute);
       
       if (scheduledDateTime.isBefore(now)) {
         passedOrTaken++;
       }
    }

    return passedOrTaken >= sortedSlots.length;
  }

  /// Returns true if the medicine is scheduled for the given date based on its frequency/interval.
  static bool isScheduledForDay(Medicine medicine, DateTime day) {
    final checkDay = DateTime(day.year, day.month, day.day);
    final start = DateTime(medicine.startTime.year, medicine.startTime.month, medicine.startTime.day);
    
    // 1. Check Start Date
    if (checkDay.isBefore(start)) return false;

    // 2. Check End Date
    if (medicine.endDate != null) {
      final end = DateTime(medicine.endDate!.year, medicine.endDate!.month, medicine.endDate!.day);
      if (checkDay.isAfter(end)) return false;
    }

    // 3. Interval Logic
    if (medicine.interval <= 1) return true; // Every Day
    if (medicine.interval == 7) return start.weekday == day.weekday; // Weekly
    
    // Every X Days
    final diffDays = checkDay.difference(start).inDays;
    return diffDays % medicine.interval == 0;
  }
}
