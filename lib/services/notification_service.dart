import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  final fln.FlutterLocalNotificationsPlugin _notificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();
    
    // Get the device's local time zone string
    // Get the device's local time zone string
    // flutter_timezone 5.0+ returns a TimezoneInfo object, older versions return String.
    // Handling both cases dynamically.
    final dynamic localTimezone = await FlutterTimezone.getLocalTimezone();
    final String timeZoneName = localTimezone is String
        ? localTimezone
        : localTimezone.identifier;

    // Set the local location
    tz.setLocalLocation(tz.getLocation(timeZoneName));

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

    final fln.IOSFlutterLocalNotificationsPlugin? iosImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            fln.IOSFlutterLocalNotificationsPlugin>();
    
    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    fln.DateTimeComponents? matchDateTimeComponents,
  }) async {
    // Force the time into the local timezone location
    // This ensures that "8:00 AM" means "8:00 AM in the phone's current timezone"
    tz.TZDateTime tzScheduledTime = tz.TZDateTime(
      tz.local,
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );
     
    // If time is in the past, adjust it based on repeat interval
    if (tzScheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
      if (matchDateTimeComponents == fln.DateTimeComponents.time) {
        // Daily: Schedule for tomorrow
        tzScheduledTime = tzScheduledTime.add(const Duration(days: 1));
      } else if (matchDateTimeComponents == fln.DateTimeComponents.dayOfWeekAndTime) {
        // Weekly: Schedule for next week
        tzScheduledTime = tzScheduledTime.add(const Duration(days: 7));
      } else {
        // One-time: schedule for near future (5s) if strictly in past?
        // Actually, if a user sets a one-time reminder for the past, it should probably happen "now" or warn.
        // But for this app, we mostly use daily.
        final now = tz.TZDateTime.now(tz.local);
        if (tzScheduledTime.isBefore(now)) {
           tzScheduledTime = now.add(const Duration(seconds: 5));
        }
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
            'medicine_channel_updates', 
            'Medicine Reminders',
            channelDescription: 'Notifications for medicine reminders',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: fln.DarwinNotificationDetails(),
        ),
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}

