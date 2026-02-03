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
    await AwesomeNotifications().setListeners(
        onActionReceivedMethod:         onActionReceivedMethod,
        onNotificationCreatedMethod:    onNotificationCreatedMethod,
        onNotificationDisplayedMethod:  onNotificationDisplayedMethod,
        onDismissActionReceivedMethod:  onDismissActionReceivedMethod
    );
  }

  /// Updates the notification channel with the specified sound
  Future<void> updateNotificationChannel(String soundPath) async {
    String? soundSource;
    
    if (soundPath == 'default') {
      soundSource = null; // Use default system sound
    } else if (soundPath.startsWith('assets/')) {
      // Bundled asset: Use resource://raw/ approach
      final String fileName = soundPath.split('/').last;
      final String resourceName = fileName.split('.').first;
      soundSource = 'resource://raw/$resourceName';
    } else {
      // Fallback for unknown paths (or previously set custom files that are no longer supported)
      debugPrint('Warning: Unknown sound path type: $soundPath. Reverting to default.');
      soundSource = null;
    }

    await AwesomeNotifications().setChannel(
      NotificationChannel(
        channelGroupKey: 'basic_channel_group',
        channelKey: 'basic_channel', // Keeping same key to avoid multiple channels for now
        channelName: 'Medicine Reminders',
        channelDescription: 'Notifications for your scheduled medicines',
        defaultColor: const Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.Max,
        channelShowBadge: true,
        locked: true,
        defaultRingtoneType: DefaultRingtoneType.Notification,
        soundSource: soundSource,
        playSound: true,
      ),
      forceUpdate: true,
    );
    
    debugPrint('Notification Channel Updated with sound: $soundSource');
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
    
    final payload = receivedAction.payload;
    if (payload != null && payload.containsKey('medicineId')) {
      final medicineId = payload['medicineId'];
      
      // Instead of a fixed delay, we'll wait for the navigator to be available
      int retryCount = 0;
      while (navigatorKey.currentContext == null && retryCount < 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        retryCount++;
      }

      final context = navigatorKey.currentContext;
      if (context != null) {
        try {
          final provider = Provider.of<MedicineProvider>(context, listen: false);
          
          // Ensure provider is initialized
          if (provider.isLoading) {
             await provider.loadMedicines();
          }

          final medicine = provider.medicines.firstWhere(
            (m) => m.id == medicineId,
            orElse: () => throw Exception("Medicine not found"),
          );
          
          debugPrint("Navigating to details for: ${medicine.name}");
          
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => MedicineDetailsScreen(medicine: medicine),
            ),
            (route) => route.isFirst,
          );
        } catch (e) {
          debugPrint("Navigation Error: $e");
        }
      }
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
    bool playSound = true, // Keep parameter for API consistency
    Map<String, String>? payload,
  }) async {
    
    // Note: Sound is controlled at channel level in awesome_notifications
    // The playSound parameter is kept for API consistency but not used here
    
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
