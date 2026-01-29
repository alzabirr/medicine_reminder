import 'dart:io';
import 'package:flutter/material.dart';
import 'package:medi/core/theme.dart';
import 'package:provider/provider.dart';
import 'package:medi/providers/medicine_provider.dart';
import 'package:medi/providers/theme_provider.dart';
import 'package:medi/screens/profile_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<MedicineProvider, ThemeProvider>(
      builder: (context, medProvider, themeProvider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  _buildProfileSection(context, medProvider),
                  const SizedBox(height: 32),
                  _buildSectionLabel('Preferences'),
                  const SizedBox(height: 16),
                  _buildSettingItem(
                    context,
                    icon: Icons.notifications_active_outlined,
                    title: 'Notifications',
                    subtitle: medProvider.notificationsEnabled ? 'Reminders are ON' : 'Reminders are OFF',
                    trailing: Switch.adaptive(
                      value: medProvider.notificationsEnabled,
                      activeColor: Theme.of(context).primaryColor,
                      onChanged: (val) => medProvider.toggleNotifications(),
                    ),
                  ),


                  const SizedBox(height: 32),
                  _buildSectionLabel('App Settings'),
                  const SizedBox(height: 16),
                  _buildSettingItem(
                    context,
                    icon: Icons.language_rounded,
                    onTap: () => _showInfoDialog(context, 'Language', 'Multiple languages support coming soon! \n\nStay tuned for Bengali and more.'),
                    title: 'Language',
                    subtitle: 'English (US)',
                  ),
                  const SizedBox(height: 16),
                  _buildSettingItem(
                    context,
                    icon: Icons.security_rounded,
                    onTap: () => _showInfoDialog(context, 'Privacy Policy', 'Your data is stored locally on your device. We do not collect or share any personal medical information.'),
                    title: 'Privacy Policy',
                    subtitle: 'Read our terms of service',
                  ),
                  const SizedBox(height: 16),
                  _buildSettingItem(
                    context,
                    icon: Icons.info_outline_rounded,
                    onTap: () => _showInfoDialog(
                      context, 
                      'About MediRemind', 
                      'MediRemind is your personal healthcare companion, designed to help you stay consistent with your medications. \n\n🔒 Privacy First: All your health data remains stored locally on your device. \n\n✨ Goal: To provide a premium, easy-to-use experience for better health management. '
                    ),
                    title: 'About MediRemind',
                    subtitle: 'Mission, Privacy & Mission',
                  ),
                  const SizedBox(height: 32),
                  _buildSectionLabel('Personalization'),
                  const SizedBox(height: 16),
                  _buildSettingItem(
                    context,
                    icon: Icons.palette_outlined,
                    onTap: () => _showColorPickerSheet(context, themeProvider),
                    title: 'Accent Color',
                    subtitle: 'Current: ${themeProvider.accentColor.value.toRadixString(16).toUpperCase().substring(2)}',
                    trailing: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: themeProvider.accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).textTheme.titleLarge?.color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Manage your health and preferences',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection(BuildContext context, MedicineProvider provider) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.getNeumorphicShadow(context),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                boxShadow: AppTheme.getNeumorphicShadowInset(context),
              ),
              child: ClipOval(
                child: provider.userProfile['avatar']!.startsWith('assets/')
                    ? Image.asset(
                        provider.userProfile['avatar']!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.person_rounded, color: Theme.of(context).primaryColor, size: 32),
                      )
                    : Image.file(
                        File(provider.userProfile['avatar']!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.person_rounded, color: Theme.of(context).primaryColor, size: 32),
                      ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.userProfile['name']!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  Text(
                    'Your Health Profile',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
                boxShadow: AppTheme.getNeumorphicShadow(context),
              ),
              child: Icon(Icons.arrow_forward_ios_rounded, color: Theme.of(context).primaryColor, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: AppTheme.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingItem(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.getNeumorphicShadow(context),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Theme.of(context).primaryColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  void _showColorPickerSheet(BuildContext context, ThemeProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40, offset: const Offset(0, -10)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Signature Color',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 24),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select wait suits your style best',
              style: GoogleFonts.outfit(
                color: AppTheme.textSecondary.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            _buildColorGrid(context, provider),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildColorGrid(BuildContext context, ThemeProvider provider) {
    final List<Map<String, dynamic>> colors = [
     
     // Custom Colors
      {'color': const Color(0xFFD02752), 'name': 'Crimson'},
      {'color': const Color(0xFF8A244B), 'name': 'Maroon'},
      {'color': const Color(0xFF111F35), 'name': 'Midnight Blue'},
      {'color': const Color(0xFF30364F), 'name': 'Deep Navy'},
      {'color': const Color(0xFF36656B), 'name': 'Teal Blue'},
      {'color': const Color(0xFF628141), 'name': 'Olive Green'},
      {'color': const Color(0xFF6F8F72), 'name': 'Sage Green'},
      {'color': const Color(0xFFB12C00), 'name': 'Burnt Orange'},
      {'color': const Color(0xFF6A1E55), 'name': 'Plum'},
      {'color': const Color(0xFFFF204E), 'name': 'Flash Pink'},
      {'color': const Color(0xFF009688), 'name': 'Teal'},
      {'color': const Color(0xFF06B6D4), 'name': 'Cyan'},
      {'color': const Color(0xFF03A9F4), 'name': 'Light Blue'},
      {'color': const Color(0xFF2196F3), 'name': 'Blue'},
      {'color': const Color(0xFF64748B), 'name': 'Slate'},
      {'color': const Color(0xFF71717A), 'name': 'Zinc'},
      {'color': const Color(0xFF78716C), 'name': 'Stone'},
      {'color': const Color(0xFF795548), 'name': 'Brown'},
      {'color': const Color(0xFF455A64), 'name': 'Blue Grey'},
      
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final colorData = colors[index];
        final Color color = colorData['color'];
        final isSelected = provider.accentColor.value == color.value;

        return GestureDetector(
          onTap: () => provider.setAccentColor(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.8)],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                : null,
          ),
        );
      },
    );
  }


  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
        ],
      ),
    );
  }
}
