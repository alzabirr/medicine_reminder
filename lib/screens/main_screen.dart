import 'package:flutter/material.dart';
import 'package:medi/screens/add_medicine_screen.dart';
import 'package:medi/screens/home_screen.dart';
import 'package:medi/screens/history_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const HistoryScreen(),
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
        child: _screens[_currentIndex == 2 ? 1 : 0],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
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
            icon: Icon(Icons.cottage_outlined),
            selectedIcon: Icon(Icons.cottage),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline, size: 32),
            selectedIcon: Icon(Icons.add_circle, size: 32),
            label: 'Add Medicine',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }

  static Route<void> _addMedicineRouteBuilder(BuildContext context, Object? arguments) {
    return MaterialPageRoute(builder: (context) => const AddMedicineScreen());
  }
}
