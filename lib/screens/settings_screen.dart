import 'dart:io';
import 'package:flutter/material.dart';
import 'package:medi/core/theme.dart';
import 'package:provider/provider.dart';
import 'package:medi/providers/medicine_provider.dart';
import 'package:medi/providers/theme_provider.dart';
import 'package:medi/screens/profile_screen.dart';
import 'package:medi/widgets/sound_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<MedicineProvider, ThemeProvider>(
      builder: (context, medProvider, themeProvider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
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
                    icon: Icons.music_note_rounded,
                    title: 'Notification Sound',
                    subtitle: _getSoundName(medProvider.notificationSound),
                    onTap: () => _showSoundPicker(context),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionLabel('Safety'),
                  const SizedBox(height: 16),
                  _buildEmergencyContactSection(context, medProvider),
                  const SizedBox(height: 32),
                  _buildSectionLabel('Personalization'),
                  const SizedBox(height: 16),
                  _buildSettingItem(
                    context,
                    icon: Icons.palette_outlined,
                    onTap: () => _showColorPickerSheet(context, themeProvider),
                    title: 'App Theme Color',
                    subtitle: 'Current: ${_getColorName(themeProvider.accentColor)}',
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
                  const SizedBox(height: 32),
                  _buildSectionLabel('App Settings'),
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
                    subtitle: 'Mission & Privacy',
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
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 40, offset: const Offset(0, -10)),
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
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Choose App Theme',
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
                color: AppTheme.textSecondary.withValues(alpha: 0.6),
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

  static const List<Map<String, dynamic>> _appColors = [
      {'color': Color(0xFFD02752), 'name': 'Ruby Red'},
      {'color': Color(0xFF8A244B), 'name': 'Wine'},
      {'color': Color(0xFF111F35), 'name': 'Night'},
      {'color': Color(0xFF30364F), 'name': 'Navy'},
      {'color': Color(0xFF36656B), 'name': 'Ocean'},
      {'color': Color(0xFF628141), 'name': 'Forest'},
      {'color': Color(0xFF6F8F72), 'name': 'Sage'},
      {'color': Color(0xFFB12C00), 'name': 'Sunset'},
      {'color': Color(0xFF6A1E55), 'name': 'Berry'},
      {'color': Color(0xFFFF204E), 'name': 'Rose'},
      {'color': Color(0xFF009688), 'name': 'Teal'},
      {'color': Color(0xFF06B6D4), 'name': 'Sky'},
      {'color': Color(0xFF03A9F4), 'name': 'Blue'},
      {'color': Color(0xFF2196F3), 'name': 'Royal'},
      {'color': Color(0xFF64748B), 'name': 'Slate'},
      {'color': Color(0xFF71717A), 'name': 'Grey'},
      {'color': Color(0xFF78716C), 'name': 'Stone'},
      {'color': Color(0xFF795548), 'name': 'Coffee'},
      {'color': Color(0xFF455A64), 'name': 'Storm'},
  ];

  String _getColorName(Color color) {
    try {
      final match = _appColors.firstWhere((item) => (item['color'] as Color).value == color.value);
      return match['name'] as String;
    } catch (e) {
      return 'Custom';
    }
  }

  Widget _buildColorGrid(BuildContext context, ThemeProvider provider) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _appColors.length,
      itemBuilder: (context, index) {
        final colorData = _appColors[index];
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
                colors: [color, color.withValues(alpha: 0.8)],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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

  void _showSoundPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const SoundPickerSheet(),
    );
  }

  String _getSoundName(String soundPath) {
    if (soundPath == 'default') return 'System Default';
    if (soundPath.startsWith('assets/')) {
      // Extract filename and make it readable
      final filename = soundPath.split('/').last.split('.').first;
      return filename.replaceAll('_', ' ').split(' ').map((word) {
        return word[0].toUpperCase() + word.substring(1);
      }).join(' ');
    }
    return 'Custom Sound';
  }

  Widget _buildEmergencyContactSection(BuildContext context, MedicineProvider provider) {
    // Determine how many contacts to show in preview (e.g. max 2)
    final contacts = provider.emergencyContacts;
    final hasContacts = contacts.isNotEmpty;
    // Find primary contact
    final primaryContact = contacts.firstWhere(
      (c) => c['isPrimary'] == 'true',
      orElse: () => contacts.isNotEmpty ? contacts.first : {'name': '', 'phone': ''},
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.getNeumorphicShadow(context),
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              // Icon
              InkWell(
                onTap: () => _showEmergencyContactManager(context, provider),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.emergency_rounded, color: Colors.redAccent, size: 24),
                ),
              ),
              const SizedBox(width: 16),
              
              // Text Area (Tappable to open manager)
              Expanded(
                child: InkWell(
                  onTap: () => _showEmergencyContactManager(context, provider),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency Contacts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasContacts 
                              ? '${primaryContact['name']} • ${primaryContact['phone']}' 
                              : 'Add trusted contacts',
                          style: TextStyle(
                            fontSize: 13,
                            color: hasContacts ? Theme.of(context).primaryColor : AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Actions
              if (hasContacts && primaryContact['phone']!.isNotEmpty) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _launchDialer(primaryContact['phone']!),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.call_rounded, color: Colors.green, size: 22),
                  tooltip: 'Call Emergency Contact',
                ),
              ],
              
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _showEmergencyContactManager(context, provider),
                icon: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Theme.of(context).primaryColor),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Manage Contacts',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchDialer(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void _showEmergencyContactManager(BuildContext context, MedicineProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EmergencyContactManagerSheet(),
    );
  }
}

class _EmergencyContactManagerSheet extends StatefulWidget {
  @override
  State<_EmergencyContactManagerSheet> createState() => _EmergencyContactManagerSheetState();
}

class _EmergencyContactManagerSheetState extends State<_EmergencyContactManagerSheet> {
  @override
  Widget build(BuildContext context) {
    return Consumer<MedicineProvider>(
      builder: (context, provider, child) {
        final contacts = provider.emergencyContacts;

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency Contacts',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 24),
                        ),
                        Text(
                          'Tap to call, swipe to delete',
                          style: TextStyle(
                            color: AppTheme.textSecondary.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              
              // List
              Expanded(
                child: contacts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.contact_phone_outlined, size: 48, color: Theme.of(context).primaryColor),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No contacts added yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.titleLarge?.color
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 250,
                              child: Text(
                                'Add family members or caregivers for quick access in emergencies.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.7)),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: contacts.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final contact = contacts[index];
                          final isPrimary = contact['isPrimary'] == 'true';
                          
                          return Dismissible(
                            key: ValueKey('${contact['name']}_${contact['phone']}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: Theme.of(context).cardColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  title: const Text('Delete Contact?', style: TextStyle(fontWeight: FontWeight.w900)),
                                  content: Text('Are you sure you want to remove ${contact['name']}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) {
                              provider.removeEmergencyContact(index);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${contact['name']} removed')),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: isPrimary 
                                    ? Border.all(color: Theme.of(context).primaryColor, width: 1.5)
                                    : Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                                boxShadow: AppTheme.getNeumorphicShadow(context),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => _launchDialer(contact['phone']!),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Theme.of(context).primaryColor.withValues(alpha: 0.2),
                                                Theme.of(context).primaryColor.withValues(alpha: 0.05),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              contact['name']!.isNotEmpty ? contact['name']![0].toUpperCase() : '?',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w900,
                                                color: Theme.of(context).primaryColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    contact['name']!,
                                                    style: const TextStyle(
                                                      fontSize: 16, 
                                                      fontWeight: FontWeight.w800
                                                    ),
                                                  ),

                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.phone_rounded, size: 14, color: AppTheme.textSecondary.withValues(alpha: 0.7)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    contact['phone']!,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: AppTheme.textSecondary,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            isPrimary ? Icons.star_rounded : Icons.star_outline_rounded,
                                            color: isPrimary ? Theme.of(context).primaryColor : AppTheme.textSecondary.withValues(alpha: 0.3),
                                            size: 24,
                                          ),
                                          onPressed: isPrimary ? null : () {
                                            provider.setPrimaryContact(index);
                                            // Keep dialog open to show state change
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('${contact['name']} set as primary contact')),
                                            );
                                          },
                                          tooltip: 'Set as primary',
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.edit_outlined, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                                          onPressed: () => _showAddEditDialog(context, provider, index: index, contact: contact),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.call_rounded, color: Colors.green, size: 20),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              
              // Add Button
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddEditDialog(context, provider),
                    icon: const Icon(Icons.person_add_rounded),
                    label: const Text('Add Contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchDialer(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void _showAddEditDialog(BuildContext context, MedicineProvider provider, {int? index, Map<String, String>? contact}) {
    final nameController = TextEditingController(text: contact?['name'] ?? '');
    final phoneController = TextEditingController(text: contact?['phone'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          contact == null ? 'New Contact' : 'Edit Info',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          if (contact != null) ...[
             TextButton.icon(
              onPressed: () {
                 provider.removeEmergencyContact(index!);
                 Navigator.pop(ctx);
              },
              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
              label: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const Spacer(), 
          ] else ...[
             TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('Cancel'),
            ),
            const Spacer(),
          ],
          
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                if (contact == null) {
                  provider.addEmergencyContact(nameController.text, phoneController.text);
                } else {
                  provider.updateEmergencyContact(index!, nameController.text, phoneController.text);
                }
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.spaceBetween,
      ),
    );
  }
}
