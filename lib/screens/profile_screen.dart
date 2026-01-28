import 'dart:io';
import 'package:flutter/material.dart';
import 'package:medi/core/theme.dart';
import 'package:medi/providers/medicine_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late String _selectedAvatar;
  bool _isEditing = false;
  final ImagePicker _picker = ImagePicker();

  final List<String> _avatarAssets = [
    'assets/avatar/Aven.jpg',
    'assets/avatar/Eva.png',
    'assets/avatar/Henry.jpg',
    'assets/avatar/Kiro.jpg',
    'assets/avatar/Lilt.png',
    'assets/avatar/Mitsumi.jpg',
    'assets/avatar/Nori.jpg',
    'assets/avatar/Norman.jpg',
    'assets/avatar/Rufus.jpg',
    'assets/avatar/Victor.jpg',
    'assets/avatar/Wilbur.jpg',
    'assets/avatar/Xari.jpg',
    'assets/avatar/Zed.jpg',
    'assets/avatar/Zyno.jpg',
  ];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<MedicineProvider>(context, listen: false);
    _nameController = TextEditingController(text: provider.userProfile['name']);
    _selectedAvatar = provider.userProfile['avatar']!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final provider = Provider.of<MedicineProvider>(context, listen: false);
    provider.updateProfile(_nameController.text, _selectedAvatar);
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedAvatar = image.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).textTheme.titleLarge?.color, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Health Profile',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                'Save',
                style: GoogleFonts.outfit(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Consumer<MedicineProvider>(
        builder: (context, provider, child) {
          final stats = provider.getAdherenceStats();
          final advanced = provider.getAdvancedAnalytics();
          
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      _buildAvatarSection(),
                      const SizedBox(height: 16),
                      _buildNameSection(),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                
                _buildSectionHeader('Overall Performance'),
                const SizedBox(height: 16),
                _buildHealthReportSection(stats, advanced['timeAccuracy'], advanced['comparison']),
                
                const SizedBox(height: 32),
                _buildSectionHeader('30-Day Activity Heatmap'),
                const SizedBox(height: 16),
                _buildMonthlyHeatmap(advanced['heatmap']),

                const SizedBox(height: 32),
                _buildSectionHeader('Weekly Trend'),
                const SizedBox(height: 16),
                _buildTrendChart(advanced['weeklyTrend']),
                
                const SizedBox(height: 32),
                _buildSectionHeader('Achievements'),
                const SizedBox(height: 16),
                _buildAchievementShowcase(advanced['achievements']),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).textTheme.titleLarge?.color,
      ),
    );
  }

  Widget _buildTrendChart(List<Map<String, dynamic>> trend) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.getNeumorphicShadow(context),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: trend.map((day) {
          final double percentage = day['percentage'];
          final DateTime date = day['date'];
          final isToday = date.day == DateTime.now().day;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${percentage.toInt()}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isToday ? Theme.of(context).primaryColor : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 25,
                height: (percentage / 100) * 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.5),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ['M', 'T', 'W', 'T', 'F', 'S', 'S'][date.weekday - 1],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.w900 : FontWeight.w500,
                  color: isToday ? Theme.of(context).primaryColor : AppTheme.textSecondary,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }



  Widget _buildAvatarSection() {
    final bool isAsset = _selectedAvatar.startsWith('assets/');
    
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() => _isEditing = true);
            _showImageSourceSheet();
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).cardColor,
                  border: Border.all(
                    color: _isEditing ? Theme.of(context).primaryColor : Colors.transparent,
                    width: 4,
                  ),
                  boxShadow: AppTheme.getNeumorphicShadow(context),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipOval(
                    child: isAsset 
                      ? Image.asset(_selectedAvatar, fit: BoxFit.cover)
                      : Image.file(File(_selectedAvatar), fit: BoxFit.cover),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Change Profile Picture',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSourceOption(
                  icon: Icons.face_rounded,
                  label: 'Avatars',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _showAvatarPicker();
                  },
                ),
                _buildSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildSourceOption(
                  icon: Icons.grid_view_rounded,
                  label: 'Gallery',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Text(
                'Choose an Avatar',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 20),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _avatarAssets.length,
                  itemBuilder: (context, index) {
                    final avatar = _avatarAssets[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAvatar = avatar;
                          final fileName = avatar.split('/').last.split('.').first;
                          _nameController.text = fileName;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedAvatar == avatar ? Theme.of(context).primaryColor : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: ClipOval(child: Image.asset(avatar)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameSection() {
    if (_isEditing) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: TextField(
          controller: _nameController,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            hintText: 'Your Name',
            border: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3))),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: () => setState(() => _isEditing = true),
      child: Text(
        _nameController.text,
        style: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: Theme.of(context).textTheme.titleLarge?.color,
        ),
      ),
    );
  }

  Widget _buildMonthlyHeatmap(List<double> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.getNeumorphicShadow(context),
      ),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final val = data[index];
              return Container(
                decoration: BoxDecoration(
                  color: val >= 1.0 
                    ? AppTheme.successColor.withOpacity(0.8) 
                    : (val > 0 ? Colors.orange.withOpacity(0.6) : Colors.red.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Last 30 Days Activity', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementShowcase(List<Map<String, dynamic>> achievements) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: achievements.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final ach = achievements[index];
          final isUnlocked = ach['unlocked'];
          return Container(
            width: 80,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUnlocked ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isUnlocked ? Theme.of(context).primaryColor.withOpacity(0.2) : Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(ach['icon'], color: isUnlocked ? Theme.of(context).primaryColor : Colors.grey, size: 28),
                const SizedBox(height: 8),
                Text(
                  ach['title'],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isUnlocked ? Theme.of(context).primaryColor : Colors.grey,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHealthReportSection(Map<String, dynamic> stats, double timeAccuracy, double comparison) {
    final double percentage = stats['percentage'];
    final Color statusColor = percentage > 80 ? AppTheme.successColor : (percentage > 50 ? Colors.orange : Colors.red);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.getNeumorphicShadow(context),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Adherence Report',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              Icon(Icons.analytics_rounded, color: Theme.of(context).primaryColor),
            ],
          ),
          const SizedBox(height: 32),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 12,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                children: [
                  Text(
                    '${percentage.toInt()}%',
                    style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w900),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        comparison >= 0 ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color: comparison >= 0 ? AppTheme.successColor : Colors.red,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${comparison.abs().toInt()}%',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: comparison >= 0 ? AppTheme.successColor : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'vs Last Week',
                    style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Taken', stats['totalTaken'].toString(), AppTheme.successColor),
              _buildStatItem('Accuracy', '${timeAccuracy.toInt()}%', Colors.blue),
              _buildStatItem('Scheduled', stats['totalScheduled'].toString(), Theme.of(context).primaryColor),
            ],
          ),
        ],
      ),
    );
  }




  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: color),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

}
