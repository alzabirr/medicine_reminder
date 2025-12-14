import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medi/models/medicine.dart';
import 'package:medi/core/theme.dart';

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback? onTaken;

  const MedicineCard({
    super.key,
    required this.medicine,
    this.onTaken,
  });

  bool get isTakenToday {
    final now = DateTime.now();
    return medicine.takenHistory.any(
      (d) => d.year == now.year && d.month == now.month && d.day == now.day,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                         Icon(
                          medicine.instruction == 'Before Meal' ? Icons.restaurant_menu : Icons.dinner_dining, 
                          size: 14, 
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          medicine.instruction ?? 'Any Time',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
  
              // Action Button with Neumorphic effect
              if (isTakenToday)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.neumorphicShadowInset,
                  ),
                  child: const Icon(Icons.check_circle, color: AppTheme.successColor, size: 28),
                )
              else
                GestureDetector(
                  onTap: onTaken,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.neumorphicShadow,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                ),
            ],
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
