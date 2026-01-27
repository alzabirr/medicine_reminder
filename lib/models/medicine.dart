import 'package:hive/hive.dart';

part 'medicine.g.dart';

@HiveType(typeId: 0)
class Medicine extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String dosage; // e.g., "1 Tablet", "5ml"

  @HiveField(3)
  String type; // e.g., "Pill", "Liquid", "Injection"

  @HiveField(4)
  int interval; // Deprecated

  @HiveField(5)
  DateTime startTime; // Deprecated

  @HiveField(8, defaultValue: [])
  List<String> timeSlots; // ["Morning", "Noon", "Night"]

  @HiveField(9)
  String? instruction; // "Before Meal", "After Meal"

  @HiveField(10)
  DateTime? endDate;

  @HiveField(6)
  String? imagePath;

  @HiveField(11, defaultValue: false)
  bool isDeleted;

  @HiveField(7)
  List<DateTime> takenHistory; // To track when it was taken

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.type,
    this.interval = 1,
    required this.startTime,
    this.imagePath,
    List<DateTime>? takenHistory,
    this.timeSlots = const [],
    this.instruction,
    this.endDate,
    this.isDeleted = false,
  }) : takenHistory = takenHistory ?? [];

  bool isSlotTaken(DateTime date, String timeSlot) {
    if (takenHistory.isEmpty) return false;
    
    // Parse the time slot to get expected hour/minute
    final pivotIndex = timeSlot.indexOf(':');
    final timeStr = pivotIndex != -1 
          ? timeSlot.substring(pivotIndex + 1).trim() 
          : timeSlot;
          
    int hour = 0;
    int minute = 0;
    
    final RegExp timeRegex = RegExp(r'(\d{1,2})[:\s\u00A0\u2007\u202F]+(\d{2})\s*(AM|PM|am|pm)?');
    final match = timeRegex.firstMatch(timeStr);

    if (match != null) {
        int h = int.parse(match.group(1)!);
        int m = int.parse(match.group(2)!);
        final period = match.group(3)?.toLowerCase(); 

        if (period == 'pm' && h != 12) h += 12;
        if (period == 'am' && h == 12) h = 0;
        
        hour = h;
        minute = m;
    } else {
      return false;
    }

    // Check if any taken entry matches this specific date + time
    return takenHistory.any((dt) => 
      dt.year == date.year && 
      dt.month == date.month && 
      dt.day == date.day &&
      dt.hour == hour &&
      dt.minute == minute
    );
  }
}
