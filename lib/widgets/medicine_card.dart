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

  const MedicineCard({
    super.key,
    required this.medicine,
    this.onTaken,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isTakenToday = false;
    final now = DateTime.now();
    isTakenToday = medicine.takenHistory.any(
      (d) => d.year == now.year && d.month == now.month && d.day == now.day,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onCardTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.neumorphicShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icon / Image with Neumorphic effect
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.neumorphicShadowInset,
                  ),
                  child: medicine.imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(File(medicine.imagePath!), fit: BoxFit.cover),
                        )
                      : Icon(
                          _getIconForType(medicine.type),
                          color: Theme.of(context).primaryColor,
                          size: 32,
                        ),
                ),
                const SizedBox(width: 16),
    
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${medicine.timeSlots.isNotEmpty ? medicine.timeSlots.join(', ') : "Daily"}', 
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 4),
                       Row(
                        children: [
                          Text(
                            medicine.instruction ?? 'Any Time',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                      
                      // Next Dose Indicator
                      if (!isTakenToday) ...[
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            final remaining = MedicineUtils.getTimeUntilNextDose(medicine);
                            if (remaining == null) return const SizedBox.shrink();
                            
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time_filled, size: 14, color: Theme.of(context).primaryColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Next in ${MedicineUtils.formatDuration(remaining)}',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        ),
                      ],
                    ],
                  ),
                ),
    
                // Right Side: Taken Indicator
                if (isTakenToday)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(
                      Icons.check_circle,
                      color: AppTheme.successColor,
                      size: 32,
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
