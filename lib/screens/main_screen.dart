import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:medi/screens/add_medicine_screen.dart';
import 'package:medi/screens/home_screen.dart';


import 'package:medi/screens/trash_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const TrashScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: _currentIndex == 2 ? const TrashScreen(key: ValueKey('trash')) : 
               const HomeScreen(key: ValueKey('home')),
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Theme(
            data: Theme.of(context).copyWith(
              navigationBarTheme: NavigationBarThemeData(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.4),
                indicatorColor: Theme.of(context).primaryColor.withOpacity(0.1),
                labelTextStyle: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w700, fontSize: 12);
                  }
                  return TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6), fontWeight: FontWeight.w500, fontSize: 12);
                }),
                iconTheme: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return IconThemeData(color: Theme.of(context).primaryColor, size: 26);
                  }
                  return IconThemeData(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6), size: 24);
                }),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              elevation: 0,
              height: 70,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              onDestinationSelected: (index) {
                if (index == 1) {
                  Navigator.restorablePush(context, _addMedicineRouteBuilder);
                } else {
                  setState(() {
                    _currentIndex = index;
                  });
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.grid_view_rounded),
                  selectedIcon: Icon(Icons.grid_view_rounded),
                  label: 'Schedule',
                ),

                NavigationDestination(
                  icon: Icon(Icons.add_circle_rounded, size: 38),
                  selectedIcon: Icon(Icons.add_circle_rounded, size: 38),
                  label: 'Add',
                ),
                NavigationDestination(
                  icon: Icon(Icons.delete_outline_rounded),
                  selectedIcon: Icon(Icons.delete_rounded),
                  label: 'Trash',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Route<void> _addMedicineRouteBuilder(BuildContext context, Object? arguments) {
    return MaterialPageRoute(builder: (context) => const AddMedicineScreen());
  }
}
