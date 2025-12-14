import 'package:flutter/material.dart';
import 'package:medi/models/medicine.dart';
import 'package:medi/providers/medicine_provider.dart';
import 'package:medi/widgets/medicine_card.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  List<Medicine> _getMedicinesForDay(DateTime day, List<Medicine> allMedicines) {
    return allMedicines.where((medicine) {
      // Normalize dates to midnight for comparison
      final checkDay = DateTime(day.year, day.month, day.day);
      final start = DateTime(medicine.startTime.year, medicine.startTime.month, medicine.startTime.day);
      
      // 1. Check Start Date
      if (checkDay.isBefore(start)) {
        return false;
      }

      // 2. Check End Date (if exists)
      if (medicine.endDate != null) {
        final end = DateTime(medicine.endDate!.year, medicine.endDate!.month, medicine.endDate!.day);
        if (checkDay.isAfter(end)) {
          return false;
        }
      }
      
      // 3. Interval Logic (Deprecated but keep for safety/legacy)
      // If we are fully moved to "Daily within duration", checks above are sufficient for daily.
      // If we still support "Weekly", check weekday.
      if (medicine.interval == 7) {
        return medicine.startTime.weekday == day.weekday;
      }
      
      // Default to true (Daily) if within range
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: Consumer<MedicineProvider>(
        builder: (context, provider, child) {
          final medicinesForSelectedDay = _getMedicinesForDay(_selectedDay, provider.medicines);

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                eventLoader: (day) {
                  return _getMedicinesForDay(day, provider.medicines);
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                child: medicinesForSelectedDay.isEmpty
                    ? Center(
                        child: Text(
                          'No medicines for this day',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: medicinesForSelectedDay.length,
                        itemBuilder: (context, index) {
                          final medicine = medicinesForSelectedDay[index];
                          // Need to override isTaken logic for specific date?
                          // MedicineCard uses "isTakenToday".
                          // For history viewing, we should update MedicineCard or wrap it.
                          // But user wants to check history.
                          
                          // Check if taken on this specific date
                          final isTakenOnDate = medicine.takenHistory.any(
                            (d) => isSameDay(d, _selectedDay),
                          );

                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.medication, color: Theme.of(context).colorScheme.primary),
                            ),
                            title: Text(
                              medicine.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('${medicine.dosage} • ${medicine.type}'),
                            trailing: isTakenOnDate
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : isSameDay(_selectedDay, DateTime.now())
                                    ? const Icon(Icons.circle_outlined, color: Colors.grey)
                                    : _selectedDay.isBefore(DateTime.now())
                                        ? const Icon(Icons.cancel, color: Colors.red) // Missed
                                        : const Icon(Icons.access_time, color: Colors.grey), // Future
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
