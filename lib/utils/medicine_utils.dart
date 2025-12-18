import 'package:flutter/material.dart';
import 'package:medi/models/medicine.dart';

class MedicineUtils {
  /// Parses a time string like "Morning: 08:00 AM" or "20:00" into a TimeOfDay.
  static TimeOfDay? parseTime(String timeSlot) {
    try {
      final pivotIndex = timeSlot.indexOf(':');
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
  static Duration? getTimeUntilNextDose(Medicine medicine) {
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

    // Check today's slots
    for (final slot in medicine.timeSlots) {
      final time = parseTime(slot);
      if (time == null) continue;

      final scheduledDateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      
      if (scheduledDateTime.isAfter(now)) {
        if (nextDoseDate == null || scheduledDateTime.isBefore(nextDoseDate)) {
          nextDoseDate = scheduledDateTime;
        }
      }
    }

    // If no more slots today, check if we can look at tomorrow
    if (nextDoseDate == null) {
      // Check if medicine has an end date and if tomorrow would be beyond it
      final tomorrow = today.add(const Duration(days: 1));
      
      if (medicine.endDate != null) {
        final end = DateTime(medicine.endDate!.year, medicine.endDate!.month, medicine.endDate!.day);
        if (tomorrow.isAfter(end)) {
          // Medicine ends today, no more doses
          return null;
        }
      }
      
      // Check tomorrow's slots
      for (final slot in medicine.timeSlots) {
        final time = parseTime(slot);
        if (time == null) continue;

        // Tomorrow
        final scheduledDateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute).add(const Duration(days: 1));
        
        if (nextDoseDate == null || scheduledDateTime.isBefore(nextDoseDate)) {
          nextDoseDate = scheduledDateTime;
        }
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
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  /// Checks if all time slots for today have passed
  /// Returns true if all scheduled times are in the past
  static bool areAllTimeSlotsPassedToday(Medicine medicine) {
    if (medicine.timeSlots.isEmpty) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(medicine.startTime.year, medicine.startTime.month, medicine.startTime.day);
    
    // If medicine hasn't started yet, times haven't passed
    if (today.isBefore(start)) return false;
    
    // If medicine has ended, consider it as "passed"
    if (medicine.endDate != null) {
      final end = DateTime(medicine.endDate!.year, medicine.endDate!.month, medicine.endDate!.day);
      if (today.isAfter(end)) return true;
    }

    // Check if all time slots for today are in the past
    for (final slot in medicine.timeSlots) {
      final time = parseTime(slot);
      if (time == null) continue;

      final scheduledDateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      
      // If any time slot is still in the future, not all have passed
      if (scheduledDateTime.isAfter(now)) {
        return false;
      }
    }

    // All time slots are in the past
    return true;
  }
}
