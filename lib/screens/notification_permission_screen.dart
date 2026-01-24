import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi/core/theme.dart';
import 'package:medi/screens/main_screen.dart';
import 'package:medi/services/notification_service.dart';
import 'package:medi/screens/permission_required_screen.dart';
import 'package:medi/utils/navigation_utils.dart';
import 'package:medi/widgets/neumorphic_container.dart';
import 'package:hive_flutter/hive_flutter.dart';

class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  State<NotificationPermissionScreen> createState() => _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState extends State<NotificationPermissionScreen> {
  bool _isLoading = false;

  Future<void> _requestPermission() async {
    setState(() => _isLoading = true);
    try {
      await NotificationService().requestPermissions();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _navigateToMain();
      }
    }
  }

  void _navigateToMain() {
    Hive.box('settings').put('onboarding_done', true);
    Navigator.of(context).pushAndRemoveUntil(
      SmoothPageRoute(page: const MainScreen()),
      (route) => false,
    );
  }

  void _navigateToPermissionRequired() {
    Navigator.of(context).push(
      SmoothPageRoute(
        page: PermissionRequiredScreen(
          onContinue: () {
            Hive.box('settings').put('onboarding_done', true);
            Navigator.of(context).pushAndRemoveUntil(
              SmoothPageRoute(page: const MainScreen()),
              (route) => false,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // Back Button
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.surfaceColor, // Optional: subtle background or transparent
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Icon Container
              NeumorphicContainer(
                padding: const EdgeInsets.all(40),
                borderRadius: 50,
                child: Icon(
                  Icons.notifications_active_rounded,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 48),
              
              // Title
              Text(
                'Enable Notifications',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              
              // Description
              Text(
                'Please allow notifications to get reminders for your medicines on time.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                  letterSpacing: 0.2,
                ),
              ),
              
              const Spacer(),
              
              // Allow Button
              GestureDetector(
                onTap: _isLoading ? null : _requestPermission,
                child: NeumorphicContainer(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  borderRadius: 30,
                  // Using surface color + primary text as requested in previous turn for neumorphic look
                  child: Center(
                    child: _isLoading 
                      ? const SizedBox(
                          width: 24, 
                          height: 24, 
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(
                          'Allow',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Don't Allow Button
              GestureDetector(
                onTap: _navigateToPermissionRequired,
                child: Text(
                  "Don't Allow",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
