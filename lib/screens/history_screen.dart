import 'package:flutter/material.dart';
import 'package:medi/models/medicine.dart';
import 'package:medi/providers/medicine_provider.dart';
import 'package:medi/screens/medicine_details_screen.dart';
import 'package:medi/widgets/medicine_card.dart';
import 'package:provider/provider.dart';
import 'package:medi/core/theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Medicines'),
        centerTitle: true,
      ),
      body: Consumer<MedicineProvider>(
        builder: (context, provider, child) {
          final allMedicines = provider.medicines;

          if (allMedicines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.history_edu_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No medicine history yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[400],
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100, top: 16),
            itemCount: allMedicines.length,
            itemBuilder: (context, index) {
              final medicine = allMedicines[index];
              return Dismissible(
                key: Key(medicine.id),
                direction: DismissDirection.horizontal, // Allow both Swipe Right (Take) and Left (Delete)
                
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: AppTheme.successColor,
                  child: const Icon(Icons.check_circle, color: Colors.white, size: 32),
                ),
                
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Theme.of(context).colorScheme.error,
                  child: const Icon(Icons.delete, color: Colors.white, size: 32),
                ),

                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    provider.toggleTaken(medicine);
                    return false; 
                  } else {
                    return true;
                  }
                },
                
                onDismissed: (direction) {
                  if (direction == DismissDirection.endToStart) {
                    provider.deleteMedicine(medicine.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('${medicine.name} deleted')),
                    );
                  }
                },
                child: MedicineCard(
                      medicine: medicine,
                      onCardTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MedicineDetailsScreen(medicine: medicine),
                          ),
                        );
                      },
                    ),
              );
            },
          );
        },
      ),
    );
  }
}
