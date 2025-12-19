import 'package:flutter/material.dart';
import 'package:medi/providers/medicine_provider.dart';
import 'package:medi/widgets/medicine_card.dart';
import 'package:provider/provider.dart';
import 'package:medi/core/theme.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  void _showDeleteConfirmation(BuildContext context, MedicineProvider provider, String medicineId, String medicineName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(
            "Delete Permanently?",
            style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontWeight: FontWeight.w700, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          content: Text(
            "This will permanently erase \"$medicineName\". You cannot undo this action.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7), fontSize: 14),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel", style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextButton(
                onPressed: () {
                  provider.deletePermanently(medicineId);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$medicineName deleted permanently'),
                      backgroundColor: Colors.black87,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Text("Delete", style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer<MedicineProvider>(
          builder: (context, provider, child) {
            final deletedMedicines = provider.deletedMedicines;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Premium Header (Matches HomeScreen)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trash History',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4), 
                    ],
                  ),
                ),

                Expanded(
                  child: deletedMedicines.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 120),
                          itemCount: deletedMedicines.length,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            final medicine = deletedMedicines[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Dismissible(
                                  key: Key(medicine.id),
                                  direction: DismissDirection.horizontal,
                                  
                                  // Swipe Right -> Restore (Green-ish Glass)
                                  background: Container(
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    color: AppTheme.successColor.withOpacity(0.15),
                                    child: Icon(Icons.restore_from_trash_rounded, color: AppTheme.successColor, size: 28),
                                  ),
                                  
                                  // Swipe Left -> Delete Forever (Red-ish Glass)
                                  secondaryBackground: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    color: Theme.of(context).colorScheme.error.withOpacity(0.15),
                                    child: Icon(Icons.delete_forever_rounded, color: Theme.of(context).colorScheme.error, size: 28),
                                  ),

                                  confirmDismiss: (direction) async {
                                    if (direction == DismissDirection.startToEnd) {
                                      await provider.restoreMedicine(medicine);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${medicine.name} restored'),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: AppTheme.successColor,
                                          ),
                                        );
                                      }
                                      return false;
                                    } else {
                                      _showDeleteConfirmation(context, provider, medicine.id, medicine.name);
                                      return false;
                                    }
                                  },
                                  
                                  child: Opacity(
                                    opacity: 0.6,
                                    child: MedicineCard(
                                      medicine: medicine,
                                      onCardTap: null,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              shape: BoxShape.circle,
              boxShadow: AppTheme.neumorphicShadowInset,
            ),
            child: Icon(
              Icons.delete_sweep_rounded,
              size: 48,
              color: AppTheme.textSecondary.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Trash is Empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Deleted medicines will appear here',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 60), // Space for bottom nav
        ],
      ),
    );
  }
}
