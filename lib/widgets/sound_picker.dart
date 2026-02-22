import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:medi/providers/medicine_provider.dart';
import 'package:medi/core/theme.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class SoundPickerSheet extends StatefulWidget {
  const SoundPickerSheet({super.key});

  @override
  State<SoundPickerSheet> createState() => _SoundPickerSheetState();
}

class _SoundPickerSheetState extends State<SoundPickerSheet> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingSound;

  Future<void> _playSound(String soundPath) async {
    try {
      if (_playingSound == soundPath) {
        await _audioPlayer.stop();
        setState(() => _playingSound = null);
      } else {
        await _audioPlayer.stop();
        
        if (soundPath == 'default') {
          // Can't preview system default, just show feedback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('System default will play notification sound'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        } else if (soundPath.startsWith('assets/')) {
          await _audioPlayer.play(AssetSource(soundPath.replaceFirst('assets/', '')));
          setState(() => _playingSound = soundPath);
        }
      }
    } catch (e) {
      debugPrint('Error playing sound: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot play this sound: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicineProvider>(
      builder: (context, provider, _) {
        final defaultSounds = provider.getDefaultSounds();
        final selectedSound = provider.notificationSound;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 40,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Notification Sound',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Choose a sound for your medicine reminders',
                  style: GoogleFonts.outfit(
                    color: AppTheme.textSecondary.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Default sounds list
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    ...defaultSounds.map((sound) => _buildSoundItem(
                      sound['name']!,
                      sound['path']!,
                      selectedSound == sound['path']!,
                      () async {
                        await provider.setNotificationSound(sound['path']!);
                        if (mounted) Navigator.pop(context);
                      },
                    )),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSoundItem(String name, String path, bool isSelected, VoidCallback onSelect) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected 
              ? Theme.of(context).primaryColor 
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: AppTheme.getNeumorphicShadow(context),
      ),
      child: ListTile(
        leading: Icon(
          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: isSelected ? Theme.of(context).primaryColor : AppTheme.textSecondary,
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 15,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            _playingSound == path ? Icons.stop_circle : Icons.play_circle,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () => _playSound(path),
        ),
        onTap: onSelect,
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
