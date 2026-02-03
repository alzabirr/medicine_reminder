import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:medi/core/theme.dart';
import 'package:medi/models/medicine.dart';

class DailyReportSheet extends StatelessWidget {
  final Map<String, dynamic> stats;

  const DailyReportSheet({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final DateTime date = stats['date'];
    final List<Map<String, dynamic>> takenList = stats['taken'] ?? [];
    final List<Map<String, dynamic>> upcomingList = stats['upcoming'] ?? [];

    int totalTaken = takenList.fold(0, (sum, item) => sum + (item['takenCount'] as int));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE').format(date),
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    DateFormat('MMMM d, yyyy').format(date),
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$totalTaken Taken',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (takenList.isEmpty && upcomingList.isEmpty)
             Padding(
               padding: const EdgeInsets.symmetric(vertical: 32),
               child: Center(
                 child: Text('No activity recorded for this day.', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
               ),
             ),
             
          if (takenList.isNotEmpty) ...[
            Text(
              'TAKEN',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppTheme.successColor,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            ...takenList.map((item) {
              final med = item['medicine'] as Medicine;
              final history = item['history'] as List<DateTime>;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          med.name,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        const Spacer(),
                        Text(
                          '${item['takenCount']} / ${item['totalSlots']}',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: history.map((dt) => Chip(
                        label: Text(DateFormat('hh:mm a').format(dt)),
                        labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        backgroundColor: AppTheme.successColor.withValues(alpha: 0.1),
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    )
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
          
          if (upcomingList.isNotEmpty) ...[
            Text(
              'UPCOMING',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).primaryColor,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            ...upcomingList.map((item) {
              final med = item['medicine'] as Medicine;
              final List<String> slots = item['slots'] as List<String>;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.upcoming_rounded, color: Theme.of(context).primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          med.name,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: slots.map((slot) {
                        final colonIndex = slot.indexOf(':');
                        final timeText = colonIndex != -1 ? slot.substring(colonIndex + 1).trim() : slot;
                        return Chip(
                          label: Text(timeText),
                          labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor),
                          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    )
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
