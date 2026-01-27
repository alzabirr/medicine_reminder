import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi/core/theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:medi/widgets/neumorphic_container.dart';

class PermissionRequiredScreen extends StatelessWidget {
  final VoidCallback? onContinue;

  const PermissionRequiredScreen({super.key, this.onContinue});

  Future<void> _openSettings() async {
    await openAppSettings();
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
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, left: 1),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 28,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Icon
              NeumorphicContainer(
                padding: const EdgeInsets.all(40),
                borderRadius: 50,
                child: Icon(
                  Icons.notifications_off_rounded,
                  size: 80,
                  color: AppTheme.errorColor,
                ),
              ),
              const SizedBox(height: 48),
              
              // Title
              Text(
                'Permission Required',
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
                'To ensure you receive medicine reminders on time, this app requires notification access. Please enable it in settings.',
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
              
              // Open Settings Button
              GestureDetector(
                onTap: _openSettings,
                child: NeumorphicContainer(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  borderRadius: 30,
                  color: AppTheme.primaryColor,
                  child: Center(
                    child: Text(
                      'Open Settings',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              if (onContinue != null) ...[
                // Continue Anyway Button
                GestureDetector(
                  onTap: onContinue,
                  child: Text(
                    "I've enabled it",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
