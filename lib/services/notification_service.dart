import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:medi/providers/medicine_provider.dart';
import 'package:medi/screens/medicine_details_screen.dart';

class NotificationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Channel keys are versioned: Android channels can't change their sound after
  // creation, so a fresh key guarantees the current sound config is applied.
  static const String defaultChannelKey = 'medi_reminder_v2_default';
  static const String channelGroupKey = 'basic_channel_group';
  static String _currentChannelKey = defaultChannelKey;
  String get currentChannelKey => _currentChannelKey;

  // Channels created by older versions of the app.
  static const List<String> _legacyChannelKeys = [
    'basic_channel',
    'basic_channel_default',
    'basic_channel_notification_gentle',
    'basic_channel_notification_chime',
    'basic_channel_notification_soft',
    'basic_channel_notification_knock',
    'basic_channel_notification_playful',
    'basic_channel_notification_reminder',
    'basic_channel_death_note',
    'basic_channel_suzume_no_tojimari',
  ];

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

  static NotificationChannel buildChannel({required String channelKey, String? soundSource}) {
    return NotificationChannel(
      channelGroupKey: channelGroupKey,
      channelKey: channelKey,
      channelName: 'Medicine Reminders',
      channelDescription: 'Notifications for your scheduled medicines',
      defaultColor: const Color(0xFF9D50DD),
      ledColor: Colors.white,
      importance: NotificationImportance.Max,
      channelShowBadge: true,
      locked: true,

      enableVibration: true,
      defaultRingtoneType: DefaultRingtoneType.Notification,
      soundSource: soundSource,
      playSound: true,
    );
  }

  /// Updates the notification channel with the specified sound
  Future<void> updateNotificationChannel(String soundPath) async {
    String? soundSource;
    String newChannelKey = defaultChannelKey;

    if (soundPath.startsWith('assets/')) {
      // Bundled asset: the same file lives in android/app/src/main/res/raw
      final String fileName = soundPath.split('/').last;
      final String resourceName = fileName.split('.').first;
      soundSource = 'resource://raw/$resourceName';
      newChannelKey = 'medi_reminder_v2_$resourceName';
    } else if (soundPath != 'default') {
      debugPrint('Warning: Unknown sound path type: $soundPath. Reverting to default.');
    }

    try {
      await AwesomeNotifications().setChannel(
        buildChannel(channelKey: newChannelKey, soundSource: soundSource),
      );
      _currentChannelKey = newChannelKey;
    } catch (e) {
      // Never leave reminders without a working channel
      debugPrint('Failed to set channel $newChannelKey: $e');
      _currentChannelKey = defaultChannelKey;
    }
    debugPrint('Notification Channel Updated to: $_currentChannelKey with sound: $soundSource');
  }

  /// Removes channels left over from older app versions (one-time cleanup).
  Future<void> removeLegacyChannels() async {
    for (final key in _legacyChannelKeys) {
      try {
        await AwesomeNotifications().removeChannel(key);
      } catch (_) {
        // Channel didn't exist
      }
    }
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
      while (navigatorKey.currentContext == null && retryCount < 25) {
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
        channelKey: _currentChannelKey,
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
        return [NotificationPermission.Alert];
      }
    }

    // 2. Precise Alarms (Android 12+)
    // Using permission_handler for reliable check
    if (await Permission.scheduleExactAlarm.isDenied) {
        missingPermissions.add(NotificationPermission.PreciseAlarms);
    }

    return missingPermissions;
  }

  /// Battery optimization (Doze / OEM task killers) is the most common reason
  /// scheduled reminders get delayed or dropped on Android.
  Future<bool> isBatteryOptimizationActive() async {
    try {
      return !(await Permission.ignoreBatteryOptimizations.isGranted);
    } catch (_) {
      return false;
    }
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
        channelKey: _currentChannelKey,
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        category: NotificationCategory.Alarm,
        wakeUpScreen: true,
        fullScreenIntent: true,
        autoDismissible: true,
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

  Future<List<NotificationModel>> listScheduled() {
    return AwesomeNotifications().listScheduledNotifications();
  }

  /// Cancels only the future schedule; a reminder already in the tray stays.
  Future<void> cancelSchedule(int id) async {
    await AwesomeNotifications().cancelSchedule(id);
  }

  Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
  }
}
