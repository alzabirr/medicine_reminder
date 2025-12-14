import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:medi/core/theme.dart';
import 'package:medi/screens/main_screen.dart';
import 'package:provider/provider.dart';
import 'package:medi/providers/medicine_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
       
      theme: AppTheme.lightTheme,

      home: const MainScreen(),
    );
  }
}
