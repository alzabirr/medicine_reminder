import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:medi/providers/medicine_provider.dart';
import 'package:medi/screens/medicine_details_screen.dart';
import 'package:medi/models/medicine.dart';

class NotificationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
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
    debugPrint("=== Notification Action Received ===");
    debugPrint("Action ID: ${receivedAction.id}");
    debugPrint("Payload: ${receivedAction.payload}");
    
    final payload = receivedAction.payload;
    if (payload != null && payload.containsKey('medicineId')) {
      final medicineId = payload['medicineId'];
      
      // Delay to ensure navigatorKey is assigned and context is ready
      Future.delayed(const Duration(milliseconds: 600), () {
        final context = navigatorKey.currentContext;
        debugPrint("Navigator context available: ${context != null}");
        
        if (context != null) {
          try {
            final provider = Provider.of<MedicineProvider>(context, listen: false);
            final medicine = provider.medicines.firstWhere(
              (m) => m.id == medicineId,
              orElse: () => throw Exception("Medicine not found in provider"),
            );
            
            debugPrint("Navigating to details for: ${medicine.name}");
            
            // Push notification details. If already on a detail page, replace it.
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => MedicineDetailsScreen(medicine: medicine),
              ),
            );
          } catch (e) {
            debugPrint("Navigation Error: $e");
          }
        }
      });
    }
  }

  Future<List<NotificationPermission>> requestPermissions() async {
    List<NotificationPermission> missingPermissions = [];

    // 1. Basic Notifications
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      bool userGranted = await AwesomeNotifications().requestPermissionToSendNotifications(
        channelKey: 'basic_channel',
        permissions: [
          NotificationPermission.Alert,
          NotificationPermission.Sound,
          NotificationPermission.Badge,
          NotificationPermission.Vibration,
          NotificationPermission.Light,
          NotificationPermission.FullScreenIntent,
        ],
      );
      if (!userGranted) {
        // user denied basic notifications
        return []; 
      }
    }

    // 2. Precise Alarms (Android 12+)
    // Using permission_handler for reliable check
    if (await Permission.scheduleExactAlarm.isDenied) {
        missingPermissions.add(NotificationPermission.PreciseAlarms);
    }
    
    return missingPermissions;
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    int? weekday, // 1-7 (Mon-Sun)
    DateTime? day, // Specific day
    bool repeats = true,
    Map<String, String>? payload,
  }) async {
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'basic_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Alarm,
        wakeUpScreen: true,
        fullScreenIntent: true,
        autoDismissible: false,
        backgroundColor: Colors.deepPurple,
        payload: payload,
      ),
      schedule: NotificationCalendar(
        weekday: weekday,
        day: day?.day,
        month: day?.month,
        year: day?.year,
        hour: hour,
        minute: minute,
        second: 0,
        millisecond: 0,
        repeats: repeats, 
        allowWhileIdle: true,
        preciseAlarm: true,
      ),
    );
  }

  Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }
}
