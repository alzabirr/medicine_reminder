import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medi/models/medicine.dart';
import 'package:medi/core/theme.dart';
import 'package:medi/utils/medicine_utils.dart';

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback? onCardTap;
  final VoidCallback? onTaken;
  final DateTime? dateContext; // Context date for display logic

  const MedicineCard({
    super.key,
    required this.medicine,
    this.onTaken,
    this.onCardTap,
    this.dateContext,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    
    // Check if manually marked as taken
    // Use dateContext if available for checking history, otherwise today
    final checkDate = dateContext ?? now;
    final manuallyTaken = medicine.takenHistory.any(
      (d) => d.year == checkDate.year && d.month == checkDate.month && d.day == checkDate.day,
    );
    // Check if all time slots have passed (Auto-Complete)
    // Only valid if checkDate is Today or Past
    final isFutureDate = dateContext != null && 
        DateTime(dateContext!.year, dateContext!.month, dateContext!.day).isAfter(
          DateTime(now.year, now.month, now.day)
        );
        
    final allTimesPassed = !isFutureDate && MedicineUtils.areAllTimeSlotsPassedToday(medicine);
    
    // Effectively taken if either manually marked or auto-completed
    final isTakenToday = manuallyTaken || allTimesPassed;

    // Calculate Progress for Badge
    final start = DateTime(medicine.startTime.year, medicine.startTime.month, medicine.startTime.day);
    final end = medicine.endDate != null 
        ? DateTime(medicine.endDate!.year, medicine.endDate!.month, medicine.endDate!.day)
        : start;
    
    final totalDays = end.difference(start).inDays + 1;
    final takenDates = medicine.takenHistory.map((d) => DateTime(d.year, d.month, d.day)).toSet();
    
    // Fix: If virtually taken today (auto or manual) but not in history set, add today virtually
    if (isTakenToday) {
       takenDates.add(DateTime(checkDate.year, checkDate.month, checkDate.day));
    }
    
    final daysCompleted = takenDates.length;
    final isCourseComplete = daysCompleted >= totalDays;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), // Compacted (8 -> 6)
      child: GestureDetector(
        onTap: onCardTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.neumorphicShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0), // Compacted (16 -> 14)
            child: Row(
              children: [
                // Premium Layered Icon (Mini-Detail Style)
                Container(
                  width: 58, // Compacted (66 -> 58)
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.neumorphicShadow,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 48, // Proportional
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surfaceColor,
                          boxShadow: AppTheme.neumorphicShadowInset,
                        ),
                      ),
                      Container(
                        width: 40, // Proportional
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surfaceColor,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: medicine.imagePath != null
                            ? Image.file(File(medicine.imagePath!), fit: BoxFit.cover)
                            : Icon(
                                _getIconForType(medicine.type),
                                color: Theme.of(context).primaryColor,
                                size: 24, // Compacted (28 -> 24)
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
    
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        medicine.name,
                        style: TextStyle(
                           fontWeight: FontWeight.w700,
                           fontSize: 16, // Fine-tuned (18 -> 16)
                           color: AppTheme.textPrimary,
                           letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4), // Balanced gap (6 -> 4)
                      // Time Slots
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: medicine.timeSlots.map((timeSlot) {
                          final time = MedicineUtils.parseTime(timeSlot);
                          if (time == null) return const SizedBox.shrink();
                          
                          final now = DateTime.now();
                          bool hasPassed = false;
                          
                          if (isFutureDate) {
                             hasPassed = false;
                          } else {
                             final scheduledDateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
                             hasPassed = scheduledDateTime.isBefore(now);
                          }
                          
                          final colonIndex = timeSlot.indexOf(':');
                          final timeText = colonIndex != -1 ? timeSlot.substring(colonIndex + 1).trim() : timeSlot;
                          
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // Leaner for balanced look
                            decoration: BoxDecoration(
                              color: hasPassed 
                                  ? AppTheme.successColor.withOpacity(0.1)
                                  : Theme.of(context).primaryColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (hasPassed) ...[
                                  Icon(Icons.check, size: 10, color: AppTheme.successColor),
                                  const SizedBox(width: 3),
                                ],
                                Text(
                                  timeText,
                                  style: TextStyle(
                                    color: hasPassed ? AppTheme.successColor : Theme.of(context).primaryColor,
                                    fontSize: 12, // Fine-tuned (14 -> 12)
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6), // Balanced gap (8 -> 6) // Better gap (6 -> 8)
                      // Context Bar (Instruction + Day Badge)
                      Row(
                        children: [
                          Icon(Icons.restaurant_menu, size: 12, color: AppTheme.textSecondary.withOpacity(0.6)), // Scaled (14 -> 12)
                          const SizedBox(width: 4),
                          Text(
                            medicine.instruction ?? 'Any Time',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12, // Fine-tuned (14 -> 12)
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isTakenToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Day $daysCompleted/$totalDays',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10, // Fine-tuned
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      // Next Dose Indicator
                      Builder(
                        builder: (context) {
                          Duration? remaining;
                          if (isTakenToday) {
                            TimeOfDay? earliestTime;
                            for (final slot in medicine.timeSlots) {
                              final time = MedicineUtils.parseTime(slot);
                              if (time != null) {
                                if (earliestTime == null || 
                                    (time.hour < earliestTime.hour || 
                                     (time.hour == earliestTime.hour && time.minute < earliestTime.minute))) {
                                  earliestTime = time;
                                }
                              }
                            }
                            if (earliestTime != null) {
                              final now = DateTime.now();
                              final tomorrow = DateTime(now.year, now.month, now.day + 1, earliestTime.hour, earliestTime.minute);
                              remaining = tomorrow.difference(now);
                              if (medicine.endDate != null) {
                                final end = DateTime(medicine.endDate!.year, medicine.endDate!.month, medicine.endDate!.day);
                                final tomorrowDate = DateTime(now.year, now.month, now.day + 1);
                                if (tomorrowDate.isAfter(end)) remaining = null;
                              }
                            }
                          } else {
                            remaining = MedicineUtils.getTimeUntilNextDose(medicine);
                          }

                          if (remaining == null) return const SizedBox.shrink();
                          
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.alarm, size: 12, color: Theme.of(context).primaryColor), // Scaled (14 -> 12)
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Next in ${MedicineUtils.formatDuration(remaining)}',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 12, // Fine-tuned (14 -> 12)
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                ),
    
                // Final Check Circle
                if (isTakenToday && isCourseComplete)
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.successColor,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ), 
    ); // Padding
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'pill':
      case 'tablet':
        return Icons.medication;
      case 'liquid':
      case 'syrup':
        return Icons.local_drink;
      case 'injection':
        return Icons.vaccines;
      case 'drop':
        return Icons.water_drop;
      default:
        return Icons.medication_liquid;
    }
  }
}
