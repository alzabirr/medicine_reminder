import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final fln.FlutterLocalNotificationsPlugin _notificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();

    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings (minimal for now)
    const fln.DarwinInitializationSettings initializationSettingsDarwin =
        fln.DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const fln.InitializationSettings initializationSettings = fln.InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> requestPermissions() async {
    final fln.AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            fln.AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    fln.DateTimeComponents? matchDateTimeComponents,
  }) async {
    // If scheduledTime is in the past, adjust it to the future for the first occurrence
    // This logic relies on 'matchDateTimeComponents' to handle repetitions,
    // but zonedSchedule with absolute time needs a future time effectively.
    // However, if matchDateTimeComponents is set, it matches components (e.g. time)
    // regardless of the exact date, USUALLY. 
    // But safe practice: if it's already passed for today, schedule for tomorrow?
    // Actually, zonedSchedule with matchDateTimeComponents uses the time component.
    
    // Convert to TZDateTime
    tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
     
    // If time is in the past, adjust it based on repeat interval
    if (tzScheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
      if (matchDateTimeComponents == fln.DateTimeComponents.time) {
        // Daily: Schedule for tomorrow
        tzScheduledTime = tzScheduledTime.add(const Duration(days: 1));
      } else if (matchDateTimeComponents == fln.DateTimeComponents.dayOfWeekAndTime) {
        // Weekly: Schedule for next week
        tzScheduledTime = tzScheduledTime.add(const Duration(days: 7));
      } else {
        // If not repeating and in past, schedule for 1 minute from now (or just log/skip)
        // For safely, let's bump it to 5 seconds future so the user gets notified "immediately"
        // or just accept it might fail if we don't change it. 
        // Better: don't schedule past non-repeating alarms, or make them "now".
        final now = tz.TZDateTime.now(tz.local);
        tzScheduledTime = tz.TZDateTime.from(now.add(const Duration(seconds: 5)), tz.local); 
      }
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        const fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'medicine_channel',
            'Medicine Reminders',
            channelDescription: 'Notifications for medicine reminders',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: fln.DarwinNotificationDetails(),
        ),
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    } catch (e) {
      print('Error scheduling notification (likely exact alarm permission): $e');
      // Fallback or just log? For now just log to prevent crash.
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}

