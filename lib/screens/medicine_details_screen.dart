import 'dart:io';
import 'package:flutter/material.dart';
import 'package:medi/models/medicine.dart';
import 'package:medi/core/theme.dart';
import 'package:provider/provider.dart';
import 'package:medi/providers/medicine_provider.dart';

class MedicineDetailsScreen extends StatelessWidget {
  final Medicine medicine;

  const MedicineDetailsScreen({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              _showDeleteConfirmation(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image or Icon Header
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.neumorphicShadow,
                ),
                padding: const EdgeInsets.all(4), // Border spacing
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.surfaceColor,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: medicine.imagePath != null
                      ? Image.file(
                          File(medicine.imagePath!),
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          Icons.medication,
                          size: 64,
                          color: Theme.of(context).primaryColor,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Medicine Name
            Text(
              medicine.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${medicine.type} • ${medicine.instruction}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 48),

            // Details Grid
            _buildDetailRow(context, 'Frequency', medicine.timeSlots.isNotEmpty ? medicine.timeSlots.join('\n') : 'Daily'),
            const SizedBox(height: 24),
            _buildDetailRow(context, 'Start Date', '${medicine.startTime.day}/${medicine.startTime.month}/${medicine.startTime.year}'),
            const SizedBox(height: 24),
            if (medicine.endDate != null)
              _buildDetailRow(context, 'End Date', '${medicine.endDate!.day}/${medicine.endDate!.month}/${medicine.endDate!.year}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.neumorphicShadowInset,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Medicine?'),
        content: Text('Are you sure you want to delete ${medicine.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<MedicineProvider>(context, listen: false).deleteMedicine(medicine.id);
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close details screen
              ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('${medicine.name} deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
