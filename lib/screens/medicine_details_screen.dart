import 'dart:io';
import 'package:flutter/material.dart';
import 'package:medi/models/medicine.dart';
import 'package:medi/core/theme.dart';
import 'package:provider/provider.dart';
import 'package:medi/providers/medicine_provider.dart';
import 'package:medi/screens/add_medicine_screen.dart';

class MedicineDetailsScreen extends StatelessWidget {
  final Medicine medicine;

  const MedicineDetailsScreen({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicineProvider>(
      builder: (context, provider, child) {
        // Find the latest version of this medicine from the provider
        final latestMedicine = provider.medicines.firstWhere(
          (m) => m.id == medicine.id,
          orElse: () => medicine, // Fallback to original if not found
        );
        
        return Scaffold(
          backgroundColor: AppTheme.surfaceColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Medicine Details',
              style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.edit_note, color: Theme.of(context).primaryColor, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddMedicineScreen(medicine: latestMedicine),
                    ),
                  ).then((_) {
                     Navigator.pop(context);
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.delete_sweep_outlined, color: Colors.red.shade400, size: 24),
                onPressed: () {
                  _showDeleteConfirmation(context, latestMedicine);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _buildBody(context, latestMedicine),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, Medicine med) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Premium Header Image
          Center(
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                shape: BoxShape.circle,
                boxShadow: AppTheme.neumorphicShadow,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.surfaceColor,
                      boxShadow: AppTheme.neumorphicShadowInset,
                    ),
                  ),
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.surfaceColor,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: med.imagePath != null
                        ? Image.file(
                            File(med.imagePath!),
                            fit: BoxFit.cover,
                          )
                        : Icon(
                            _getIconForType(med.type),
                            size: 60,
                            color: Theme.of(context).primaryColor.withOpacity(0.8),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Medicine Name & Quick Info
          Text(
            med.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 16),
          
          // Identity Chips
          Wrap(
            spacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildModernChip(
                context, 
                med.type, 
                Icons.category_outlined,
                Theme.of(context).primaryColor,
              ),
              _buildModernChip(
                context, 
                med.instruction ?? 'Any Time', 
                Icons.restaurant_outlined,
                Colors.orange.shade400,
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Detail Sections
          _buildSectionHeader(context, 'Schedule'),
          const SizedBox(height: 16),
          _buildDetailCard(
            context,
            'Reminder Times',
            med.timeSlots.isNotEmpty ? med.timeSlots.join(' • ') : 'Not set',
            Icons.alarm,
            Theme.of(context).primaryColor,
          ),
          
          const SizedBox(height: 32),
          _buildSectionHeader(context, 'Course Details'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailCard(
                  context,
                  'Start',
                  '${med.startTime.day}/${med.startTime.month}/${med.startTime.year}',
                  Icons.calendar_today_outlined,
                  Colors.blue.shade400,
                  isCompact: true,
                ),
              ),
              const SizedBox(width: 16),
              if (med.endDate != null)
                Expanded(
                  child: _buildDetailCard(
                    context,
                    'End',
                    '${med.endDate!.day}/${med.endDate!.month}/${med.endDate!.year}',
                    Icons.event_available_outlined,
                    Colors.purple.shade400,
                    isCompact: true,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: AppTheme.textSecondary.withOpacity(0.6),
            letterSpacing: 1.2,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: AppTheme.textSecondary.withOpacity(0.1))),
      ],
    );
  }

  Widget _buildModernChip(BuildContext context, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: AppTheme.neumorphicShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context, String label, String value, IconData icon, Color accentColor, {bool isCompact = false}) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.neumorphicShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: accentColor),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 14 : 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'pills':
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
        return Icons.clean_hands_rounded;
      case 'inhaler':
        return Icons.air_rounded;
      default:
        return Icons.medication_liquid;
    }
  }

  void _showDeleteConfirmation(BuildContext context, Medicine med) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Medicine?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete ${med.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Provider.of<MedicineProvider>(context, listen: false).deleteMedicine(med.id);
              Navigator.pop(ctx); 
              Navigator.pop(context); 
              ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(
                   content: Text('${med.name} moved to trash'),
                   behavior: SnackBarBehavior.floating,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                 ),
              );
            },
            child: const Text('Move to Trash', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}