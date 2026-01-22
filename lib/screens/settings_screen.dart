import 'package:flutter/material.dart';
import 'package:medi/core/theme.dart';
import 'package:provider/provider.dart';
import 'package:medi/providers/medicine_provider.dart';
import 'package:medi/providers/theme_provider.dart';

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
                  const SizedBox(height: 16),
                  _buildSettingItem(
                    context,
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    subtitle: themeProvider.isDarkMode ? 'Dark theme active' : 'Light theme active',
                    trailing: Switch.adaptive(
                      value: themeProvider.isDarkMode,
                      activeColor: Theme.of(context).primaryColor,
                      onChanged: (val) => themeProvider.toggleTheme(val),
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
                    onTap: () => _showInfoDialog(context, 'About', 'MediRemind v1.0.0 \n\nDesigned for your health. \nCreated with Flutter.'),
                    title: 'About',
                    subtitle: 'Version 1.0.0',
                  ),
                  const SizedBox(height: 40),
                  _buildLogoutButton(context),
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
    return Container(
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
            child: Icon(Icons.person_rounded, color: Theme.of(context).primaryColor, size: 32),
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
                  provider.userProfile['email']!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showEditProfileDialog(context, provider),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
                boxShadow: AppTheme.getNeumorphicShadow(context),
              ),
              child: Icon(Icons.edit_note_rounded, color: Theme.of(context).primaryColor, size: 20),
            ),
          ),
        ],
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

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mock Logout: You session is active')),
        );
      },
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
        ),
        child: const Center(
          child: Text(
            'Sign Out',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, MedicineProvider provider) {
    final nameController = TextEditingController(text: provider.userProfile['name']);
    final emailController = TextEditingController(text: provider.userProfile['email']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.updateProfile(nameController.text, emailController.text);
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
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
