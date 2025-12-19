import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medi/models/medicine.dart';
import 'package:medi/core/theme.dart';
import 'package:medi/utils/medicine_utils.dart';

import 'dart:async';

class MedicineCard extends StatefulWidget {
  final Medicine medicine;
  final VoidCallback? onCardTap;
  final VoidCallback? onTaken;
  final DateTime? dateContext;

  const MedicineCard({
    super.key,
    required this.medicine,
    this.onTaken,
    this.onCardTap,
    this.dateContext,
  });

  @override
  State<MedicineCard> createState() => _MedicineCardState();
}

class _MedicineCardState extends State<MedicineCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start a timer to update the countdown every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final checkDate = widget.dateContext ?? now;
    final targetDay = DateTime(checkDate.year, checkDate.month, checkDate.day);
    final todayMidnight = DateTime(now.year, now.month, now.day);
    
    // Doses taken on the date currently being VIEWED (for slot visuals)
    final takenCountForDate = widget.medicine.takenHistory.where(
      (d) => d.year == targetDay.year && d.month == targetDay.month && d.day == targetDay.day,
    ).length;
    
    // Doses taken TODAY (for actual countdown and course completion logic)
    final takenCountToday = widget.medicine.takenHistory.where(
      (d) => d.year == todayMidnight.year && d.month == todayMidnight.month && d.day == todayMidnight.day,
    ).length;

    // Course progress
    final startAtMidnight = DateTime(widget.medicine.startTime.year, widget.medicine.startTime.month, widget.medicine.startTime.day);
    final displayDay = targetDay.difference(startAtMidnight).inDays + 1;
    final totalDays = widget.medicine.endDate != null 
        ? widget.medicine.endDate!.difference(startAtMidnight).inDays + 1
        : 1;
    final displayDayClamped = displayDay.clamp(1, totalDays);

    // Course is fully finished ONLY if past end date OR (on end date AND today is complete)
    bool isFullyFinished = false;
    if (widget.medicine.endDate != null) {
      final endAtMidnight = DateTime(widget.medicine.endDate!.year, widget.medicine.endDate!.month, widget.medicine.endDate!.day);
      if (todayMidnight.isAfter(endAtMidnight)) {
        isFullyFinished = true;
      } else if (todayMidnight.isAtSameMomentAs(endAtMidnight)) {
        isFullyFinished = MedicineUtils.areAllTimeSlotsPassedToday(widget.medicine, takenCount: takenCountToday);
      }
    }
    
    final isCurrentDay = targetDay.isAtSameMomentAs(todayMidnight);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: widget.onCardTap,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.getNeumorphicShadow(context),
            border: null, // Removed border for Course Finish
          ),
          child: Opacity(
            opacity: isFullyFinished ? 0.85 : 1.0,
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  // Premium Layered Icon
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.getNeumorphicShadow(context),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).cardColor,
                            boxShadow: AppTheme.getNeumorphicShadowInset(context),
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).cardColor,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: widget.medicine.imagePath != null
                              ? Image.file(File(widget.medicine.imagePath!), fit: BoxFit.cover)
                              : Icon(
                                  _getIconForType(widget.medicine.type),
                                  color: Theme.of(context).primaryColor,
                                  size: 24,
                                ),
                        ),
                        if (isFullyFinished)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle,
                                color: AppTheme.successColor,
                                size: 18,
                              ),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.medicine.name,
                                style: TextStyle(
                                   fontWeight: FontWeight.w700,
                                   fontSize: 16,
                                   color: AppTheme.textPrimary,
                                   letterSpacing: -0.3,
                                   // Removed strike-through
                                ),
                              ),
                            ),
                            // Day Progress Badge (Always Show)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$displayDayClamped/$totalDays',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Time Slots
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: widget.medicine.timeSlots.map((timeSlot) {
                            // Find index of this slot
                            final index = widget.medicine.timeSlots.indexOf(timeSlot);
                            final time = MedicineUtils.parseTime(timeSlot);
                            if (time == null) return const SizedBox.shrink();
                            
                            // Mark as DONE if taken OR if time has passed for this specific day
                            bool isTaken = index < takenCountForDate;
                            bool hasPassed = false;
                            
                            final scheduledDateTime = DateTime(targetDay.year, targetDay.month, targetDay.day, time.hour, time.minute);
                            hasPassed = scheduledDateTime.isBefore(now);
                            
                            final isDone = isTaken || hasPassed;
                            
                            final colonIndex = timeSlot.indexOf(':');
                            final timeText = colonIndex != -1 ? timeSlot.substring(colonIndex + 1).trim() : timeSlot;
                            
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDone
                                    ? AppTheme.successColor.withOpacity(0.1)
                                    : Theme.of(context).primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isDone) ...[
                                    Icon(Icons.check, size: 10, color: AppTheme.successColor),
                                    const SizedBox(width: 3),
                                  ],
                                  Text(
                                    timeText,
                                    style: TextStyle(
                                      color: isDone ? AppTheme.successColor : Theme.of(context).primaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 6),
                        
                        // Instruction
                        Row(
                          children: [
                            Icon(Icons.restaurant_menu, size: 12, color: AppTheme.textSecondary.withOpacity(0.6)),
                            const SizedBox(width: 4),
                            Text(
                              widget.medicine.instruction ?? 'Any Time',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        
                        // Next Dose Indicator (Live Countdown)
                        Builder(
                          builder: (context) {
                            // Only show live countdown if viewing the current day and course is NOT finished
                            if (!isCurrentDay || isFullyFinished) return const SizedBox.shrink();

                            Duration? remaining = MedicineUtils.getTimeUntilNextDose(widget.medicine, takenCount: takenCountToday);
  
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
                                    child: Icon(Icons.alarm, size: 12, color: Theme.of(context).primaryColor),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Next in ${MedicineUtils.formatDuration(remaining)}',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 12,
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
                ],
              ),
            ),
          ),
        ),
      ), 
    );
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
      case 'topical':
        return Icons.healing;
      case 'inhaler':
        return Icons.air_rounded;
      default:
        return Icons.medication_liquid;
    }
  }
}
