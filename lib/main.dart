import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:medi/core/theme.dart';
import 'package:medi/screens/main_screen.dart';
import 'package:medi/screens/get_started_screen.dart';
import 'package:provider/provider.dart';
import 'package:medi/providers/medicine_provider.dart';
import 'package:medi/services/notification_service.dart';

import 'package:medi/providers/theme_provider.dart';

import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive and open settings box for onboarding check
  await Hive.initFlutter();
  await Hive.openBox('settings');
  final bool isOnboardingDone = Hive.box('settings').get('onboarding_done', defaultValue: false);
  
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
        importance: NotificationImportance.Max,
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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MedicineReminderApp(isOnboardingDone: isOnboardingDone),
    ),
  );
}

class MedicineReminderApp extends StatelessWidget {
  final bool isOnboardingDone;
  
  const MedicineReminderApp({super.key, required this.isOnboardingDone});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
       
      navigatorKey: NotificationService.navigatorKey,
      restorationScopeId: 'medi_app',
      theme: AppTheme.lightTheme,
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: AppTheme.primaryColor,
        colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.primaryColor, brightness: Brightness.dark),
      ),
      themeMode: themeProvider.themeMode,
      home: isOnboardingDone ? const MainScreen() : const GetStartedScreen(),
    );
  }
}
