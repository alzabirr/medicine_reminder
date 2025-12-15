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
    this.takenHistory = const [],
    this.timeSlots = const [],
    this.instruction,
    this.endDate,
  });
}
