import 'dart:io';
import 'package:flutter/material.dart';
import 'package:medi/core/theme.dart';
import 'package:medi/providers/medicine_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medi/widgets/report/daily_report_sheet.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _heightFeetController;
  late TextEditingController _heightInchesController;
  late TextEditingController _ageController;
  late String _selectedAvatar;
  String? _selectedBloodGroup;
  String? _selectedGender;
  bool _isEditing = false;
  bool _isHeightInFeet = false;
  final ImagePicker _picker = ImagePicker();

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _genders = ['Male', 'Female', 'Other'];

  final List<String> _avatarAssets = [
    'assets/avatar/Aven.jpg',
    'assets/avatar/Eva.png',
    'assets/avatar/Henry.jpg',
    'assets/avatar/Kiro.jpg',
    'assets/avatar/Lilly.png',
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
    _weightController = TextEditingController(text: provider.userProfile['weight'] == '—' ? '' : provider.userProfile['weight']);
    _ageController = TextEditingController(text: provider.userProfile['age'] == '—' ? '' : provider.userProfile['age']);
    _selectedAvatar = provider.userProfile['avatar']!;
    _selectedBloodGroup = provider.userProfile['bloodGroup'] == 'Select' ? null : provider.userProfile['bloodGroup'];
    _selectedGender = provider.userProfile['gender'] == 'Select' ? null : provider.userProfile['gender'];

    // Height Parsing
    final hStr = provider.userProfile['height'] ?? '—';
    _heightController = TextEditingController();
    _heightFeetController = TextEditingController();
    _heightInchesController = TextEditingController();

    if (hStr.contains("'") || hStr.contains("ft")) {
      _isHeightInFeet = true;
      final parts = hStr.split(RegExp(r"['\sft]+"));
      if (parts.length >= 2) {
        _heightFeetController.text = parts[0];
        _heightInchesController.text = parts[1];
      } else if (parts.isNotEmpty) {
        _heightFeetController.text = parts[0];
      }
    } else {
      _isHeightInFeet = false;
      _heightController.text = hStr == '—' ? '' : hStr.replaceAll(RegExp(r'[^0-9.]'), '');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final provider = Provider.of<MedicineProvider>(context, listen: false);
    String heightVal = '—';
    if (_isHeightInFeet) {
      if (_heightFeetController.text.isNotEmpty) {
        heightVal = "${_heightFeetController.text}'${_heightInchesController.text.isEmpty ? '0' : _heightInchesController.text} ft";
      }
    } else {
      if (_heightController.text.isNotEmpty) {
        heightVal = "${_heightController.text} cm";
      }
    }

    provider.updateProfile(
      name: _nameController.text,
      avatar: _selectedAvatar,
      bloodGroup: _selectedBloodGroup ?? 'Select',
      weight: _weightController.text.isEmpty ? '—' : _weightController.text,
      height: heightVal,
      age: _ageController.text.isEmpty ? '—' : _ageController.text,
      gender: _selectedGender ?? 'Select',
    );
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
                const SizedBox(height: 32),
                
                if (!_isEditing) _buildInfoGrid(provider),
                if (_isEditing) _buildEditHealthDetails(),
                const SizedBox(height: 32),
                _buildSectionHeader('Overall Adherence Breakdown'),
                const SizedBox(height: 16),
                _buildAdherencePieChart(provider.getActiveDaysHistory()),

                const SizedBox(height: 32),
                _buildSectionHeader('Adherence History Trend'),
                const SizedBox(height: 16),
                _buildTrendChart(advanced['weeklyTrend']),
                


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
    if (trend.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: 240,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.getNeumorphicShadow(context),
      ),
      child: Stack(
        children: [
          // Background guidelines
          Padding(
            padding: const EdgeInsets.only(top: 45, bottom: 55, left: 24, right: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(height: 1, color: AppTheme.textSecondary.withValues(alpha: 0.05)),
                Container(height: 1, color: AppTheme.textSecondary.withValues(alpha: 0.05)),
                Container(height: 1, color: AppTheme.textSecondary.withValues(alpha: 0.1)),
              ],
            ),
          ),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: trend.reversed.map((day) {
                final double percentage = day['percentage'];
                final DateTime date = day['date'];
                final isToday = date.year == DateTime.now().year && 
                                date.month == DateTime.now().month && 
                                date.day == DateTime.now().day;

                Color barColor;
                if (percentage >= 100) barColor = AppTheme.successColor;
                else if (percentage >= 50) barColor = Colors.orange;
                else barColor = Colors.indigoAccent;

                return GestureDetector(
                  onTap: () => _showDailyReport(date),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          percentage >= 100 ? '✓' : '${percentage.toInt()}%',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: isToday ? Theme.of(context).primaryColor : barColor.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            // Empty track
                            Container(
                              width: 18,
                              height: 110,
                              decoration: BoxDecoration(
                                color: AppTheme.textSecondary.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            // Animated bar
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: percentage),
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeOutQuart,
                              builder: (context, value, child) => Container(
                                width: 18,
                                height: (value / 100) * 110,
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          DateFormat('E').format(date).toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                            color: isToday ? Theme.of(context).primaryColor : AppTheme.textSecondary.withValues(alpha: 0.8),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          DateFormat('d/M').format(date),
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                            color: isToday ? Theme.of(context).primaryColor.withValues(alpha: 0.7) : AppTheme.textSecondary.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildAvatarSection() {
    final bool isAsset = _selectedAvatar.startsWith('assets/');
    
    return Column(
      children: [
        Stack(
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
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() => _isEditing = true);
                  _showImageSourceSheet();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withValues(alpha: 0.8),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
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
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 40, offset: const Offset(0, -10)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
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
              color: color.withValues(alpha: 0.1),
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
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.3))),
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


  Widget _buildAdherencePieChart(List<Map<String, dynamic>> history) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
           color: Theme.of(context).cardColor,
           borderRadius: BorderRadius.circular(24),
           boxShadow: AppTheme.getNeumorphicShadow(context),
        ),
        child: Column(
          children: [
            Icon(Icons.pie_chart_outline_rounded, size: 48, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'No activity recorded yet.',
              style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    int perfect = 0;
    int struggling = 0;
    int totalTakenDoses = 0;
    int totalScheduledDoses = 0;

    for (var day in history) {
      totalTakenDoses += (day['taken'] as int? ?? 0);
      totalScheduledDoses += (day['scheduled'] as int? ?? 0);
      
      final double p = day['percentage'] ?? 0.0;
      if (p >= 1.0) perfect++;
      else struggling++;
    }

    final int totalDays = history.length;
    final double overallAdherence = totalScheduledDoses > 0 ? (totalTakenDoses / totalScheduledDoses) : 0.0;

    return GestureDetector(
      onTap: () => _showHistoryLogSheet(history),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(32),
          boxShadow: AppTheme.getNeumorphicShadow(context),
        ),
        child: Column(
          children: [
            Row(
              children: [
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return CustomPaint(
                          size: const Size(150, 150),
                          painter: PieChartPainter(
                            perfect: totalDays > 0 ? (perfect / totalDays) * value : 0.0,
                            partial: 0.0,
                            struggling: totalDays > 0 ? (struggling / totalDays) * value : 0.0,
                            colors: [AppTheme.successColor, Colors.orange, Colors.indigoAccent],
                            backgroundColor: Theme.of(context).cardColor,
                          ),
                        );
                      },
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(overallAdherence * 100).toInt()}%',
                          style: GoogleFonts.outfit(
                            fontSize: 28, 
                            fontWeight: FontWeight.w900, 
                            color: AppTheme.successColor,
                            height: 1,
                          ),
                        ),
                        Text(
                          'Adherence',
                          style: GoogleFonts.outfit(
                            fontSize: 10, 
                            color: AppTheme.textSecondary, 
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  children: [
                    _buildLegendItem('Completed day', perfect, totalDays, AppTheme.successColor),
                    const SizedBox(height: 12),
                    _buildLegendItem('Upcoming day', struggling, totalDays, Colors.indigoAccent),
                  ],
                ),
              ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Based on $totalDays days of history',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
               
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, int total, Color color) {
    final double percentage = total > 0 ? (count / total) * 100 : 0.0;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              Text(
                '${percentage.toInt()}% of history',
                style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Text(
          count.toString(),
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: color),
        ),
      ],
    );
  }
  
  void _showHistoryLogSheet(List<Map<String, dynamic>> history) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(44)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Activity History',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900, 
                            fontSize: 26,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Full track of your progress',
                          style: GoogleFonts.outfit(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${history.length} Days',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).primaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  physics: const BouncingScrollPhysics(),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final day = history[index];
                    final date = day['date'] as DateTime;
                    final percentage = day['percentage'] as double;
                    
                    // Month/Year header logic
                    bool showHeader = false;
                    if (index == 0) {
                      showHeader = true;
                    } else {
                      final prevDate = history[index - 1]['date'] as DateTime;
                      if (date.month != prevDate.month || date.year != prevDate.year) {
                        showHeader = true;
                      }
                    }

                    Color color;
                    IconData icon;
                    String status;
                    
                    if (percentage >= 1.0) {
                      color = AppTheme.successColor;
                      icon = Icons.check_circle_rounded;
                      status = 'Completed day';
                    } else {
                      color = Colors.indigoAccent;
                      icon = Icons.calendar_today_rounded;
                      status = 'Upcoming day';
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHeader) ...[
                          if (index != 0) const SizedBox(height: 32),
                          Text(
                            DateFormat('MMMM yyyy').format(date).toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textSecondary.withValues(alpha: 0.4),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _showDailyReport(date);
                          },
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                // Timeline line and dot
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 2,
                                      color: AppTheme.textSecondary.withValues(alpha: 0.05),
                                    ),
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: AppTheme.getNeumorphicShadow(context),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                DateFormat('EEEE, d').format(date),
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.w800, 
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(icon, size: 14, color: color),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    status,
                                                    style: GoogleFonts.outfit(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 13,
                                                      color: color.withValues(alpha: 0.8),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${(percentage * 100).toInt()}%',
                                              style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 22,
                                                color: color,
                                                height: 1.1,
                                              ),
                                            ),
                                            Text(
                                              'SCORE',
                                              style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 8,
                                                color: AppTheme.textSecondary.withValues(alpha: 0.3),
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  void _showDailyReport(DateTime date) {
    final provider = Provider.of<MedicineProvider>(context, listen: false);
    final stats = provider.getStatsForDay(date);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          child: DailyReportSheet(stats: stats),
        ),
      ),
    );
  }

  Widget _buildInfoGrid(MedicineProvider provider) {
    final profile = provider.userProfile;
    final bmiVal = provider.bmi;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.getNeumorphicShadow(context),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildInfoItem(Icons.water_drop_rounded, 'Blood', profile['bloodGroup']!, Colors.redAccent)),
              const SizedBox(width: 8),
              Expanded(child: _buildInfoItem(Icons.cake_rounded, 'Age', profile['age']!, Colors.purpleAccent)),
              const SizedBox(width: 8),
              Expanded(child: _buildInfoItem(Icons.wc_rounded, 'Gender', profile['gender']!, Colors.teal)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildInfoItem(Icons.monitor_weight_rounded, 'Weight', profile['weight']!, Colors.blueAccent)),
              const SizedBox(width: 8),
              Expanded(child: _buildInfoItem(Icons.height_rounded, 'Height', profile['height']!, Colors.green)),
              const SizedBox(width: 8),
              Expanded(child: _buildInfoItem(
                Icons.speed_rounded, 
                'BMI', 
                bmiVal != null ? bmiVal.toStringAsFixed(1) : '—', 
                Colors.orangeAccent,
                onTap: bmiVal != null ? () => _showBMIDetails(bmiVal) : null,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
            Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800)),
          ],
        ),
      ],
    );
  }

  Widget _buildEditHealthDetails() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.getNeumorphicShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart_rounded, color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 10),
              Text(
                'Health Information',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900, 
                  fontSize: 18,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildDropDownField(
                  'Blood Group', 
                  _bloodGroups, 
                  _selectedBloodGroup, 
                  (val) => setState(() => _selectedBloodGroup = val),
                  Icons.water_drop_rounded,
                  Colors.redAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropDownField(
                  'Gender', 
                  _genders, 
                  _selectedGender, 
                  (val) => setState(() => _selectedGender = val),
                  Icons.wc_rounded,
                  Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'Age', 
                  _ageController, 
                  TextInputType.number,
                  Icons.cake_rounded,
                  Colors.purpleAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'Weight', 
                  _weightController, 
                  TextInputType.text,
                  Icons.monitor_weight_rounded,
                  Colors.blueAccent,
                  hint: "e.g. 65 kg",
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           Text(
                            'Height', 
                            style: GoogleFonts.outfit(
                              fontSize: 12, 
                              color: AppTheme.textSecondary.withValues(alpha: 0.7), 
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _isHeightInFeet = !_isHeightInFeet),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _isHeightInFeet ? 'Switch to CM' : 'Switch to FEET',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isHeightInFeet)
                      _buildTextField(
                        '', 
                        _heightController, 
                        TextInputType.number,
                        Icons.height_rounded,
                        Colors.green,
                        hint: "CM (e.g. 172)",
                        showLabel: false,
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              '', 
                              _heightFeetController, 
                              TextInputType.number,
                              Icons.height_rounded,
                              Colors.green,
                              hint: "Feet",
                              showLabel: false,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildTextField(
                              '', 
                              _heightInchesController, 
                              TextInputType.number,
                              Icons.straighten_rounded,
                              Colors.green,
                              hint: "Inches",
                              showLabel: false,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tip: Use 5\'8 format for height to get BMI in feet.',
            style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textSecondary.withValues(alpha: 0.5), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(height: 2),
            Text(
              label, 
              style: GoogleFonts.outfit(
                fontSize: 9, 
                color: AppTheme.textSecondary, 
                fontWeight: FontWeight.w700
              )
            ),
            Text(
              value, 
              style: GoogleFonts.outfit(
                fontSize: 13, 
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              )
            ),
          ],
        ),
      ),
    );
  }

  void _showBMIDetails(double bmi) {
    String category = '';
    String advice = '';
    Color categoryColor = Colors.green;

    if (bmi < 18.5) {
      category = 'Underweight';
      advice = 'You may need to eat more frequently and choose nutrient-rich foods.';
      categoryColor = Colors.orange;
    } else if (bmi < 25) {
      category = 'Normal';
      advice = 'Great job! Maintain your healthy lifestyle with balanced diet and exercise.';
      categoryColor = Colors.green;
    } else if (bmi < 30) {
      category = 'Overweight';
      advice = 'Consider increasing physical activity and managing calorie intake.';
      categoryColor = Colors.orange;
    } else {
      category = 'Obese';
      advice = 'It is recommended to consult a healthcare provider for a personalized health plan.';
      categoryColor = Colors.red;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your BMI Details',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Text(
                    bmi.toStringAsFixed(1),
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: categoryColor,
                    ),
                  ),
                  Text(
                    category,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: categoryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              advice,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            _buildBMIRangeInfo(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBMIRangeInfo() {
    return Column(
      children: [
        _buildRangeRow('Underweight', '< 18.5', Colors.orange),
        _buildRangeRow('Normal', '18.5 - 24.9', Colors.green),
        _buildRangeRow('Overweight', '25.0 - 29.9', Colors.orange),
        _buildRangeRow('Obese', '≥ 30.0', Colors.red),
      ],
    );
  }

  Widget _buildRangeRow(String label, String range, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          Text(range, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }



  Widget _buildDropDownField(String label, List<String> items, String? value, Function(String?) onChanged, IconData icon, Color iconColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label, 
            style: GoogleFonts.outfit(
              fontSize: 12, 
              color: AppTheme.textSecondary.withValues(alpha: 0.7), 
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.textSecondary.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
                    hint: Text('Select', style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textSecondary.withValues(alpha: 0.4))),
                    items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)))).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, TextInputType type, IconData icon, Color iconColor, {String? hint, bool showLabel = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label, 
              style: GoogleFonts.outfit(
                fontSize: 12, 
                color: AppTheme.textSecondary.withValues(alpha: 0.7), 
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        TextField(
          controller: controller,
          keyboardType: type,
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            isDense: false,
            hintText: hint ?? (showLabel ? 'Enter $label' : ''),
            hintStyle: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
            fillColor: Theme.of(context).scaffoldBackgroundColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 40),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.textSecondary.withValues(alpha: 0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }




}

class PieChartPainter extends CustomPainter {
  final double perfect;
  final double partial;
  final double struggling;
  final List<Color> colors;
  final Color backgroundColor;

  PieChartPainter({
    required this.perfect,
    required this.partial,
    required this.struggling,
    required this.colors,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10; // Padding for the stroke width
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    // Draw background track
    paint.color = backgroundColor.withValues(alpha: 0.1);
    // Draw a full circle if needed, or just the track
    canvas.drawCircle(center, radius, paint);
    
    // Better track color (subtle shadow/inner look)
    paint.color = Colors.grey.withValues(alpha: 0.05);
    canvas.drawCircle(center, radius, paint);

    double startAngle = -3.14159 / 2; // Start from top
    const double gap = 0.08; // Small gap between segments

    // Perfect
    if (perfect > 0.001) {
      paint.color = colors[0];
      double sweepAngle = 2 * 3.14159 * perfect;
      // Subtract small gap if multiple segments
      if (perfect < 0.99) sweepAngle -= gap;
      
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle + (perfect < 0.99 ? gap : 0);
    }

    // Partial
    if (partial > 0.001) {
      paint.color = colors[1];
      double sweepAngle = 2 * 3.14159 * partial;
      if (partial < 0.99) sweepAngle -= gap;
      
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle + (partial < 0.99 ? gap : 0);
    }

    // Struggling
    if (struggling > 0.001) {
      paint.color = colors[2];
      double sweepAngle = 2 * 3.14159 * struggling;
      if (struggling < 0.99) sweepAngle -= gap;
      
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
