import 'package:flutter/material.dart';
import 'dart:ui' as dart_ui; // Added for ImageFilter
import 'package:medi/models/medicine.dart'; // Added
import 'package:medi/providers/medicine_provider.dart';
import 'package:medi/screens/add_medicine_screen.dart';
import 'package:medi/widgets/medicine_card.dart';
import 'package:medi/widgets/medicine_card.dart';
import 'package:medi/core/transitions.dart';
import 'package:medi/core/theme.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart'; // Added

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week; // Default to week view

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
      
      // 3. Interval Logic (Daily default)
      if (medicine.interval == 7) {
        return medicine.startTime.weekday == day.weekday;
      }
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<MedicineProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Filter medicines for selected day
            final medicinesForDay = _getMedicinesForDay(_selectedDay, provider.medicines);

            return Column(
              children: [
                // Calendar Widget
                Container(
                  padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top, 8, 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).canvasColor, // Default surface
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                  child: Column(
                    children: [
                      // Calendar
                      TableCalendar(
                        firstDay: DateTime.utc(2020, 10, 16),
                        lastDay: DateTime.utc(2030, 3, 14),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        availableCalendarFormats: const {
                          CalendarFormat.week: 'Week',
                          CalendarFormat.month: 'Month',
                        },
                        onFormatChanged: (format) {
                          setState(() {
                            _calendarFormat = format;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
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
                          // Today
                          todayDecoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                          
                          // Selected
                          selectedDecoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          
                          // Markers
                          markerDecoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            shape: BoxShape.circle,
                          ),
                          markersMaxCount: 1,
                        ),
                        eventLoader: (day) {
                          return _getMedicinesForDay(day, provider.medicines);
                        },
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          leftChevronIcon: Icon(Icons.chevron_left, color: Theme.of(context).primaryColor),
                          rightChevronIcon: Icon(Icons.chevron_right, color: Theme.of(context).primaryColor),
                        ),
                      ),
                      // Week/Month Toggle Button (Bottom Center)
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _calendarFormat = _calendarFormat == CalendarFormat.week
                                  ? CalendarFormat.month
                                  : CalendarFormat.week;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: AppTheme.neumorphicShadow,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _calendarFormat == CalendarFormat.week
                                      ? Icons.calendar_view_month
                                      : Icons.calendar_view_week,
                                  size: 20,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _calendarFormat == CalendarFormat.week ? 'Show Month' : 'Show Week',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Medicines List
              Expanded(
                child: medicinesForDay.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No medicines for ${_selectedDay.day}/${_selectedDay.month}',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey[400],
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: medicinesForDay.length,
                        itemBuilder: (context, index) {
                          final medicine = medicinesForDay[index];

                          return Dismissible(
                            key: Key(medicine.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              color: Theme.of(context).colorScheme.error,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (direction) {
                              provider.deleteMedicine(medicine.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${medicine.name} deleted')),
                              );
                            },
                            child: MedicineCard(
                              medicine: medicine,
                              onTaken: () {
                                provider.toggleTaken(medicine);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            SlideUpRoute(page: const AddMedicineScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Med'),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
