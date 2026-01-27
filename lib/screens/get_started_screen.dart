import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi/core/theme.dart';
import 'package:lottie/lottie.dart';
import 'package:medi/screens/main_screen.dart';
import 'package:medi/screens/notification_permission_screen.dart';
import 'package:medi/screens/permission_required_screen.dart';
import 'package:medi/utils/navigation_utils.dart';
import 'package:medi/widgets/neumorphic_container.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 1),
            // Lottie Animation
            SizedBox(
              height: 350,
              width: double.infinity,
              child: Lottie.asset(
                'assets/animations/get_started.json',
                fit: BoxFit.fitWidth,
              ),
            ),
            const SizedBox(height: 24),
            
            // Text Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  // Title
                  Text(
                    'Stay Healthy, Stay on Track',
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
                  
                  // Subtitle
                  Text(
                    'Your personal medicine reminder to help you never miss a dose again.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(flex: 5),
            
            // Get Started Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    SmoothPageRoute(page: const NotificationPermissionScreen()),
                  );
                },
                child: NeumorphicContainer(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                  borderRadius: 30,
                  color: AppTheme.primaryColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Get Started',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Invisible, Layout-matching Text to align button with next screen
            Text(
              "Placeholder",
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.transparent, 
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
