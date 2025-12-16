import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  
  // Singleton pattern not strictly necessary if used via Provider, but good practice
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {
    // Initialization is done in main.dart for Awesome Notifications usually, 
    // but we can put listeners here.
    
    await AwesomeNotifications().setListeners(
        onActionReceivedMethod:         onActionReceivedMethod,
        onNotificationCreatedMethod:    onNotificationCreatedMethod,
        onNotificationDisplayedMethod:  onNotificationDisplayedMethod,
        onDismissActionReceivedMethod:  onDismissActionReceivedMethod
    );
  }

  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future <void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    debugPrint("Notification created: ${receivedNotification.id}");
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future <void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
     debugPrint("Notification displayed: ${receivedNotification.id}");
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future <void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    // Dismiss logic
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future <void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    // Navigate to details page if needed
    debugPrint("Action received: ${receivedAction.id}");
  }

  Future<void> requestPermissions() async {
    // Check if notifications are allowed
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      // Request full set of permissions including Precise Alarms
      await AwesomeNotifications().requestPermissionToSendNotifications(
        channelKey: 'basic_channel',
        permissions: [
          NotificationPermission.Alert,
          NotificationPermission.Sound,
          NotificationPermission.Badge,
          NotificationPermission.Vibration,
          NotificationPermission.Light,
          NotificationPermission.PreciseAlarms, // Critical for timely delivery
          NotificationPermission.FullScreenIntent,
        ],
      );
    } else {
        // Even if basic notifications are allowed, check for Precise Alarms specifically
        List<NotificationPermission> permissionsAllowed = await AwesomeNotifications().checkPermissionList(
            channelKey: 'basic_channel',
            permissions: [
                NotificationPermission.PreciseAlarms,
                NotificationPermission.FullScreenIntent,
            ]
        );
        
        if (!permissionsAllowed.contains(NotificationPermission.PreciseAlarms)) {
             await AwesomeNotifications().requestPermissionToSendNotifications(
                channelKey: 'basic_channel',
                permissions: [
                     NotificationPermission.PreciseAlarms,
                     NotificationPermission.FullScreenIntent,
                ]
            );
        }
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    
    // Convert to local time zone logic handled by Awesome Notifications 'NotificationCalendar'
    // It uses the device's local time automatically.
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'basic_channel', // Must match main.dart
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default, // or BigText
        category: NotificationCategory.Alarm, // To ensure it rings loud
        wakeUpScreen: true,
        fullScreenIntent: true,
        autoDismissible: false,
        backgroundColor: Colors.deepPurple,
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        millisecond: 0,
        repeats: true, // Daily
        allowWhileIdle: true,
        preciseAlarm: true,
      ),
    );
    
    debugPrint("Scheduled notification $id for $hour:$minute");
  }

  Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }
}
