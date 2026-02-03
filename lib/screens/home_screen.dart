import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:medi/models/medicine.dart';
import 'package:medi/providers/medicine_provider.dart';
import 'package:medi/screens/medicine_details_screen.dart'; // Added
import 'package:medi/widgets/medicine_card.dart';
import 'package:medi/widgets/neumorphic_container.dart';
import 'package:medi/core/theme.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:medi/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week; // Default to week view
  
  @override
  void initState() {
    super.initState();
    // Request permissions after UI is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notificationService = Provider.of<MedicineProvider>(context, listen: false).notificationService;
      final missingPermissions = await notificationService.requestPermissions();
      
      if (missingPermissions.contains(NotificationPermission.PreciseAlarms) && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   // Icon
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                       shape: BoxShape.circle,
                     ),
                     child: Icon(
                       Icons.notifications_active_rounded, 
                       size: 40, 
                       color: Theme.of(context).primaryColor
                     ),
                   ),
                   const SizedBox(height: 20),
                   
                   // Title
                   Text(
                    "Permission Required",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.headlineSmall?.color,
                    ),
                    textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 12),
                   
                   // Content
                   Text(
                    "Turn on reminders to take your medicine on time.",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).textTheme.titleMedium?.color,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 24),
                   
                   // Buttons
                   Row(
                     children: [
                       Expanded(
                         child: OutlinedButton(
                           onPressed: () => Navigator.pop(context),
                           style: OutlinedButton.styleFrom(
                             padding: const EdgeInsets.symmetric(vertical: 16),
                             side: BorderSide(color: Colors.grey.shade300),
                             shape: RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(12),
                             ),
                           ),
                           child: Text(
                             "Cancel",
                             style: TextStyle(color: Colors.grey[700]), 
                           ),
                         ),
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                         child: GestureDetector(
                           onTap: () async {
                              Navigator.pop(context);
                              await Permission.scheduleExactAlarm.request();
                           },
                           child: NeumorphicContainer(
                             padding: const EdgeInsets.symmetric(vertical: 16),
                             borderRadius: 12,
                             color: Theme.of(context).primaryColor, // Colored button
                             child: const Center(
                               child: Text(
                                 "Allow",
                                 style: TextStyle(
                                   color: Colors.white, 
                                   fontWeight: FontWeight.bold,
                                   fontSize: 16,
                                 ),
                               ),
                             ),
                           ),
                         ),
                       ),
                     ],
                   )
                ],
              ),
            ),
          ),
        );
      }
    });
  }

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
      
      // 3. Interval Logic
      final interval = medicine.interval ?? 1;
      
      if (interval == 1) {
        return true; // Daily
      } else if (interval == 7) {
        return medicine.startTime.weekday == day.weekday; // Weekly
      } else if (interval > 1) {
        // Custom interval (e.g. every 2 days)
        final daysDiff = checkDay.difference(start).inDays;
        return daysDiff % interval == 0;
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

            // Display medicines for selected day
            final dailyMedicines = _getMedicinesForDay(_selectedDay, provider.activeMedicines);

            return Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Premium Header
                    Container(
                      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 8, 24, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEEE, MMMM d').format(_selectedDay),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary.withOpacity(0.8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceColor,
                                  shape: BoxShape.circle,
                                  boxShadow: AppTheme.neumorphicShadow,
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.settings_outlined, color: Theme.of(context).primaryColor, size: 22),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceColor,
                                  shape: BoxShape.circle,
                                  boxShadow: AppTheme.neumorphicShadow,
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.calendar_month_rounded, color: Theme.of(context).primaryColor, size: 22),
                                  onPressed: () {
                                    setState(() {
                                      _calendarFormat = _calendarFormat == CalendarFormat.week
                                          ? CalendarFormat.month
                                          : CalendarFormat.week;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Compact Calendar Widget
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2020, 10, 16),
                        lastDay: DateTime.utc(2030, 3, 14),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        headerVisible: false, // Hidden because we have custom header
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
                          todayDecoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          markerDecoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          markersMaxCount: 1,
                          outsideDaysVisible: false,
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600),
                          weekendStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        eventLoader: (day) {
                          return _getMedicinesForDay(day, provider.activeMedicines);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Medicines List
                    Expanded(
                      child: dailyMedicines.isEmpty
                          ? SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 220), // Increased top spacing more
                                  Container(
                                    padding: const EdgeInsets.all(32),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceColor,
                                      shape: BoxShape.circle,
                                      boxShadow: AppTheme.neumorphicShadowInset,
                                    ),
                                    child: Icon(
                                      Icons.medication_liquid_rounded, 
                                      size: 48, 
                                      color: AppTheme.textSecondary.withValues(alpha: 0.2)
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'No medicines for today',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 180), // Kept high as requested
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(top: 8, bottom: 120),
                              itemCount: dailyMedicines.length,
                              itemBuilder: (context, index) {
                                final medicine = dailyMedicines[index];
                                return MedicineCard(
                                  medicine: medicine,
                                  dateContext: _selectedDay,
                                  onSlotTap: (slot) {
                                    provider.toggleTaken(medicine, date: _selectedDay, timeSlot: slot);
                                  },
                                  onCardTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MedicineDetailsScreen(medicine: medicine),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ],
            );
        },
      ),
    );
  }
}
