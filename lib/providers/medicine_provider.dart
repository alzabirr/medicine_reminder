import 'package:flutter/material.dart';
import 'package:medi/models/medicine.dart';
import 'package:medi/services/database_service.dart';
import 'package:medi/services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;

class MedicineProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  List<Medicine> _medicines = [];
  List<Medicine> get medicines => _medicines;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    await _databaseService.init();
    await _notificationService.init();
    await loadMedicines();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMedicines() async {
    _medicines = _databaseService.getMedicines();
    notifyListeners();
  }

  Future<void> addMedicine(Medicine medicine) async {
    await _databaseService.addMedicine(medicine);
    
    // Map slots to hours
    final Map<String, int> slotHours = {
      'Morning': 8,
      'Noon': 13,
      'Night': 21,
    };

    for (final slot in medicine.timeSlots) {
      final hour = slotHours[slot] ?? 8;
      
      // Create a unique ID for this slot notification
      // Combining medicine ID and slot name to ensure uniqueness
      final notificationId = (medicine.id + slot).hashCode;

      final now = DateTime.now();
      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        0,
      );
      
      // Always daily for these specific slots
      const matchDateTimeComponents = fln.DateTimeComponents.time;

      try {
        await _notificationService.scheduleNotification(
          id: notificationId,
          title: 'Time to take your meds! (${slot})',
          body: 'Take ${medicine.name} ${medicine.instruction ?? ""}',
          scheduledTime: scheduledTime,
          matchDateTimeComponents: matchDateTimeComponents,
        );
      } catch (e) {
        debugPrint('Error scheduling notification for $slot: $e');
      }
    }

    await loadMedicines();
  }

  Future<void> deleteMedicine(String id) async {
    // We need to fetch the medicine before deleting to know which slots to cancel
    // Or we can just try to cancel all possible slots blindly if we don't have the object easily.
    // Ideally, get from DB first.
    final medicine = _medicines.firstWhere((m) => m.id == id, orElse: () => _medicines.first); // Fallback risky?
    
    if (_medicines.any((m) => m.id == id)) {
        for (final slot in ['Morning', 'Noon', 'Night']) {
            await _notificationService.cancelNotification((id + slot).hashCode);
        }
        // Also cancel legacy ID just in case
        await _notificationService.cancelNotification(id.hashCode);
    }

    await _databaseService.deleteMedicine(id);
    await loadMedicines();
  }

  Future<void> toggleTaken(Medicine medicine) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if already taken today
    final isTaken = medicine.takenHistory.any(
      (d) => d.year == now.year && d.month == now.month && d.day == now.day,
    );

    if (isTaken) {
      // Remove today from history (Undo)
      medicine.takenHistory.removeWhere(
        (d) => d.year == now.year && d.month == now.month && d.day == now.day,
      );
    } else {
      // Add today to history
      medicine.takenHistory.add(now); // Store exact time
    }

    await medicine.save(); // HiveObject save
    notifyListeners();
  }
}
