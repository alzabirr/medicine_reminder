import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:medi/core/theme.dart';
import 'package:medi/screens/main_screen.dart';
import 'package:provider/provider.dart';
import 'package:medi/providers/medicine_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await AwesomeNotifications().initialize(
    null, // default icon
    [
      NotificationChannel(
        channelGroupKey: 'basic_channel_group',
        channelKey: 'basic_channel',
        channelName: 'Basic Notifications',
        channelDescription: 'Notification channel for medicine reminders',
        defaultColor: const Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        channelShowBadge: true,
        locked: true,
        defaultRingtoneType: DefaultRingtoneType.Alarm,
      )
    ],
    // Channel groups are only visual and are optional
    channelGroups: [
      NotificationChannelGroup(
        channelGroupKey: 'basic_channel_group',
        channelGroupName: 'Basic group',
      )
    ],
    debug: true,
  );
  
  final medicineProvider = MedicineProvider();
  await medicineProvider.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => medicineProvider),
      ],
      child: const MedicineReminderApp(),
    ),
  );
}

class MedicineReminderApp extends StatelessWidget {
  const MedicineReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
       
      restorationScopeId: 'medi_app',
      theme: AppTheme.lightTheme,

      home: const MainScreen(),
    );
  }
}
