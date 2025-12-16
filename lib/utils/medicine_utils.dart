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

  /// Returns the Duration until the next scheduled dose for today.
  /// If all doses for today are passed, it might return the time until tomorrow's first dose.
  static Duration? getTimeUntilNextDose(Medicine medicine) {
    if (medicine.timeSlots.isEmpty) return null;

    final now = DateTime.now();
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

    // If no more slots today, check tomorrow's first slot
    if (nextDoseDate == null) {
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
}
