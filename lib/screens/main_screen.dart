import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:medi/screens/add_medicine_screen.dart';
import 'package:medi/screens/home_screen.dart';


import 'package:medi/screens/trash_screen.dart';
import 'package:medi/widgets/floating_glass_action_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedSwitcher(
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
          
          // Custom Floating Glass Navigation Bar
          FloatingGlassActionBar(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.grid_view_rounded, 'Schedule'),
                _buildAddButton(),
                _buildNavItem(2, Icons.delete_outline_rounded, 'Trash'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade500,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade500,
                fontSize: 12, // Increased from 10
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, // Thicker weights
                letterSpacing: 0.5, // Premium spacing
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => Navigator.restorablePush(context, _addMedicineRouteBuilder),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.add_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }

  static Route<void> _addMedicineRouteBuilder(BuildContext context, Object? arguments) {
    return MaterialPageRoute(builder: (context) => const AddMedicineScreen());
  }
}
