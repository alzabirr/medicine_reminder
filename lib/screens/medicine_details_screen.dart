import 'dart:io';
import 'package:flutter/material.dart';
import 'package:medi/models/medicine.dart';
import 'package:medi/core/theme.dart';
import 'package:provider/provider.dart';
import 'package:medi/providers/medicine_provider.dart';
import 'package:medi/utils/medicine_utils.dart';
import 'package:medi/screens/add_medicine_screen.dart';
import 'package:medi/widgets/floating_glass_action_bar.dart';
import 'package:intl/intl.dart';

class MedicineDetailsScreen extends StatelessWidget {
  final Medicine medicine;

  const MedicineDetailsScreen({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicineProvider>(
      builder: (context, provider, child) {
        final latestMedicine = provider.medicines.firstWhere(
          (m) => m.id == medicine.id,
          orElse: () => medicine,
        );
        
        return Scaffold(
          backgroundColor: AppTheme.surfaceColor,
          extendBody: true, // Allow body to go under the glass bar
          appBar: _buildAppBar(context),
          body: Stack(
            children: [
              _buildBody(context, latestMedicine),
              _buildBottomActionBar(context, latestMedicine),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Text(
        'Medicine Info',
        style: TextStyle(
          color: Theme.of(context).textTheme.titleLarge?.color,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(BuildContext context, Medicine med) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 120.0), // Extra bottom padding for floating bar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildVibrantHeader(context, med),
          const SizedBox(height: 24),
          _buildMedicineIdentity(context, med),
          const SizedBox(height: 32),
          _buildProgressSection(context, med),
          const SizedBox(height: 32),
          _buildSectionLabel(context, 'Schedule Timeline'),
          const SizedBox(height: 16),
          _buildTimeline(context, med),
          const SizedBox(height: 32),
          _buildSectionLabel(context, 'Course Info'),
          const SizedBox(height: 16),
          _buildCourseInfoCards(context, med),
        ],
      ),
    );
  }

  Widget _buildVibrantHeader(BuildContext context, Medicine med) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          
          // Main Neumorphic Container
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              shape: BoxShape.circle,
              boxShadow: AppTheme.neumorphicShadow,
            ),
            child: Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surfaceColor,
                  boxShadow: AppTheme.neumorphicShadowInset,
                ),
                padding: const EdgeInsets.all(20),
                child: Container(
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  clipBehavior: Clip.antiAlias,
                  child: med.imagePath != null
                      ? Image.file(File(med.imagePath!), fit: BoxFit.cover)
                      : MedicineUtils.buildTypeIcon(
                          context, 
                          med.type, 
                          size: 60,
                          color: primaryColor,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineIdentity(BuildContext context, Medicine med) {
    return Column(
      children: [
        Text(
          med.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMiniBadge(context, med.type, Icons.medication_outlined, Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            _buildMiniBadge(context, med.instruction ?? 'Any Time', Icons.info_outline, Colors.orange),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniBadge(BuildContext context, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context, Medicine med) {
    // Calculate progress
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(med.startTime.year, med.startTime.month, med.startTime.day);
    
    int totalDays = 1;
    if (med.endDate != null) {
      totalDays = med.endDate!.difference(start).inDays + 1;
    }
    
    final elapsedDays = today.difference(start).inDays + 1;
    final progress = (elapsedDays / totalDays).clamp(0.0, 1.0);
    final isCompleted = med.endDate != null && today.isAfter(med.endDate!);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Course Progress',
              style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary, fontSize: 15),
            ),
            Text(
              isCompleted ? 'Completed' : '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                color: isCompleted ? Colors.green : Theme.of(context).primaryColor,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.darkShadow.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withValues(alpha: 0.6)],
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStatCard(context, 'Doses Taken', '${med.takenHistory.length}', Icons.check_circle_outline, Colors.green),
            const SizedBox(width: 12),
            _buildStatCard(context, 'Day', '$elapsedDays / $totalDays', Icons.calendar_today, Colors.blue),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.neumorphicShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color.withValues(alpha: 0.7)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, Medicine med) {
    return Column(
      children: med.timeSlots.map((slot) {
        final pivotIndex = slot.indexOf(':');
        final label = pivotIndex != -1 ? slot.substring(0, pivotIndex).trim() : slot;
        final time = pivotIndex != -1 ? slot.substring(pivotIndex + 1).trim() : '';

        Color accentColor;
        IconData icon;
        
        if (label.contains('Morning')) {
          accentColor = Colors.orange;
          icon = Icons.wb_sunny_rounded;
        } else if (label.contains('Noon')) {
          accentColor = Colors.blue;
          icon = Icons.wb_cloudy_rounded;
        } else if (label.contains('Night')) {
          accentColor = Colors.indigo;
          icon = Icons.nightlight_round;
        } else {
          accentColor = Theme.of(context).primaryColor;
          icon = Icons.alarm;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.neumorphicShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                    Text(time, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: AppTheme.neumorphicShadowInset,
                ),
                child: const Icon(Icons.notifications_active_outlined, size: 16, color: AppTheme.textSecondary),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCourseInfoCards(BuildContext context, Medicine med) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            context, 
            'Start Date', 
            DateFormat('MMM dd, yyyy').format(med.startTime), 
            Icons.calendar_month,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            context, 
            'End Date', 
            med.endDate != null ? DateFormat('MMM dd, yyyy').format(med.endDate!) : 'Ongoing', 
            Icons.event_available,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.neumorphicShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Theme.of(context).primaryColor.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppTheme.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Divider(color: AppTheme.darkShadow.withValues(alpha: 0.2), thickness: 2),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(BuildContext context, Medicine med) {
    return FloatingGlassActionBar(
      mainAction: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddMedicineScreen(medicine: med),
            ),
          ).then((_) {
            if (context.mounted) Navigator.pop(context);
          });
        },
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withValues(alpha: 0.8)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_note_rounded, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  'Edit Medicine',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
      secondaryAction: GestureDetector(
        onTap: () => _showDeleteConfirmation(context, med),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 24),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Medicine med) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Medicine?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to delete ${med.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w700)),
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
                   duration: const Duration(seconds: 1),
                 ),
              );
            },
            child: const Text('Move to Trash', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
