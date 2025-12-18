import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medi/models/medicine.dart';
import 'package:medi/providers/medicine_provider.dart';
import 'package:medi/core/theme.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AddMedicineScreen extends StatefulWidget {
  final Medicine? medicine;
  const AddMedicineScreen({super.key, this.medicine});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _selectedType = 'Tablet';
  final List<String> _types = ['Tablet','Pill', 'Liquid', 'Injection', 'Drop'];

  final Map<String, TimeOfDay> _selectedTimeSlots = {}; // {'Morning': TimeOfDay...}
  String _selectedInstruction = 'After Meal'; // 'Before Meal', 'After Meal', 'Any Time'

  DateTime _startDate = DateTime.now();
  String _selectedDuration = '1 Month';
  // Removed intermediate options as requested, but kept 2 Weeks
  final List<String> _durations = ['1 Week', '2 Weeks', '1 Month', 'Pick Date'];
  DateTime? _customEndDate; // Store custom end date

  File? _image;

  @override
  void initState() {
    super.initState();
    if (widget.medicine != null) {
      final m = widget.medicine!;
      _nameController.text = m.name;
      _selectedType = m.type; // Ensure value exists in _types or handle custom
      if (!_types.contains(m.type)) {
         if (_types.isNotEmpty) _selectedType = _types.first; 
         // ideally adds it or handles it, but robust enough for now
      }
      _selectedInstruction = m.instruction ?? 'After Meal';
      _startDate = m.startTime;
      if (m.imagePath != null) _image = File(m.imagePath!);
      
      // Check if custom duration
      if (m.endDate != null) {
         // Try to match standard durations
         bool foundStandard = false;
         for (final d in _durations) {
            String tempSelected = _selectedDuration; // preserve
            _selectedDuration = d;
            if (d != 'Pick Date' && _calculatedEndDate.year == m.endDate!.year && 
                _calculatedEndDate.month == m.endDate!.month && 
                _calculatedEndDate.day == m.endDate!.day) {
                  _selectedDuration = d;
                  foundStandard = true;
                  break;
            }
            _selectedDuration = tempSelected; // restore
         }
         
         if (!foundStandard) {
           _selectedDuration = 'Pick Date';
           _customEndDate = m.endDate;
         }
      }
      
      // Parse time slots
      for (final slot in m.timeSlots) {
         final pivot = slot.indexOf(':');
         if (pivot != -1) {
            final label = slot.substring(0, pivot).trim();
            final timeStr = slot.substring(pivot + 1).trim();
            
            // Parse timeStr to TimeOfDay
            // We can try strict format or our robust logic.
            // Since TimeOfDay is just hour/minute, let's use the robust logic 
            // from provider but simpler here for TimeOfDay
            try {
               final timeRegex = RegExp(r'(\d{1,2})[:\s\u00A0\u2007\u202F]+(\d{2})\s*(AM|PM|am|pm)?');
               final match = timeRegex.firstMatch(timeStr);
               if (match != null) {
                  int h = int.parse(match.group(1)!);
                  int m = int.parse(match.group(2)!);
                  final period = match.group(3)?.toLowerCase();

                  if (period == 'pm' && h != 12) h += 12;
                  if (period == 'am' && h == 12) h = 0;
                  
                  _selectedTimeSlots[label] = TimeOfDay(hour: h, minute: m);
               }
            } catch (e) {
               debugPrint('Error parsing time for edit: $timeStr');
            }
         }
      }
    }
  }

  DateTime get _calculatedEndDate {
    if (_selectedDuration == 'Pick Date') {
      return _customEndDate ?? _startDate;
    }
    switch (_selectedDuration) {
      case '1 Week':
        return _startDate.add(const Duration(days: 7));
      case '2 Weeks':
        return _startDate.add(const Duration(days: 14));
      case '1 Month':
        return DateTime(_startDate.year, _startDate.month + 1, _startDate.day);
      default:
        // Default to 1 month if something goes wrong
        return DateTime(_startDate.year, _startDate.month + 1, _startDate.day);
    }
  }


  Future<void> _selectCustomEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate.add(const Duration(days: 1)),
      firstDate: _startDate,
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _customEndDate = picked;
      });
    } else {
       // Revert if cancelled and invalid
       if (_customEndDate == null) {
          setState(() {
             _selectedDuration = '1 Month';
          });
       }
    }
  }

  Future<void> _pickImage() async {
    _getImage(ImageSource.gallery);
  }

  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  void _saveMedicine() {
    if (_formKey.currentState!.validate()) {
      if (_selectedTimeSlots.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one time (Morning/Noon/Night)')),
        );
        return;
      }

      final List<String> formattedTimeSlots = _selectedTimeSlots.entries.map((e) {
        final time = e.value;
        final timeString = time.format(context);
        return '${e.key}: $timeString';
      }).toList();

      if (widget.medicine != null) {
        // Edit Mode
         Provider.of<MedicineProvider>(context, listen: false).updateMedicine(
            widget.medicine!,
            name: _nameController.text,
            type: _selectedType,
            timeSlots: formattedTimeSlots,
            instruction: _selectedInstruction,
            startDate: _startDate,
            endDate: _calculatedEndDate,
            imagePath: _image?.path,
         );
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicine Updated Successfully! 💊')),
         );
      } else {
        // Add Mode
        final medicine = Medicine(
          id: const Uuid().v4(),
          name: _nameController.text,
          dosage: '',
          type: _selectedType,
          startTime: _startDate,
          timeSlots: formattedTimeSlots,
          instruction: _selectedInstruction,
          endDate: _calculatedEndDate,
          imagePath: _image?.path,
        );

        Provider.of<MedicineProvider>(context, listen: false).addMedicine(medicine);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine Added Successfully! 💊')),
        );
      }

      Navigator.pop(context);
    }
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'pills':
      case 'pill':
      case 'tablet':
        return Icons.medication;
      case 'liquid':
      case 'syrup':
        return Icons.local_drink;
      case 'injection':
        return Icons.vaccines;
      case 'drop':
        return Icons.water_drop;
      default:
        return Icons.medication_liquid;
    }
  }

  Widget _buildFrequencyChip(String label) {
    final isSelected = _selectedTimeSlots.containsKey(label);
    final selectedTime = _selectedTimeSlots[label];

    return GestureDetector(
      onTap: () async {
        if (isSelected) {
          setState(() {
            _selectedTimeSlots.remove(label);
          });
        } else {
          TimeOfDay initialTime;
          if (label == 'Morning') {
            initialTime = const TimeOfDay(hour: 8, minute: 0);
          } else if (label == 'Noon') {
            initialTime = const TimeOfDay(hour: 13, minute: 0);
          } else {
            initialTime = const TimeOfDay(hour: 21, minute: 0);
          }

          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: initialTime,
            builder: (BuildContext context, Widget? child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
                child: child!,
              );
            },
          );

          if (picked != null) {
            setState(() {
              _selectedTimeSlots[label] = picked;
            });
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? AppTheme.neumorphicShadowInset : AppTheme.neumorphicShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(Icons.check_circle, size: 16, color: AppTheme.successColor),
              ),
            Text(
              isSelected && selectedTime != null 
                  ? '$label (${selectedTime.format(context)})' 
                  : label,
              style: TextStyle(
                color: isSelected ? AppTheme.textPrimary : AppTheme.textPrimary.withOpacity(0.5),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionChip(String label) {
    final isSelected = _selectedInstruction == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedInstruction = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? AppTheme.neumorphicShadowInset : AppTheme.neumorphicShadow,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.textPrimary : AppTheme.textPrimary.withOpacity(0.5),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _retrieveLostData();
  }

  Future<void> _retrieveLostData() async {
    final ImagePicker picker = ImagePicker();
    try {
      final LostDataResponse response = await picker.retrieveLostData();
      if (response.isEmpty) return;
      if (response.file != null) {
        if (mounted) {
          setState(() {
            _image = File(response.file!.path);
          });
        }
      }
    } catch (e) {
      debugPrint('Error retrieving lost data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.medicine != null ? 'Edit Medicine' : 'Add Medicine',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 140), // More padding to see content behind the bar
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Premium Header Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.neumorphicShadow,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.surfaceColor,
                            boxShadow: AppTheme.neumorphicShadowInset,
                          ),
                        ),
                        Container(
                          width: 115,
                          height: 115,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.surfaceColor,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _image != null
                              ? Image.file(_image!, fit: BoxFit.cover)
                              : Icon(
                                  _getIconForType(_selectedType),
                                  size: 48,
                                  color: Theme.of(context).primaryColor.withOpacity(0.6),
                                ),
                        ),
                        // Small Camera Action Overlay
                        Positioned(
                          bottom: 0,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: AppTheme.neumorphicShadow,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title Section - Name
              _buildSectionLabel('Medicine Name'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.neumorphicShadowInset,
                ),
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Paracetamol',
                    prefixIcon: Icon(Icons.medication, color: AppTheme.textSecondary.withOpacity(0.5)),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.4)),
                  ),
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                  validator: (value) => (value == null || value.isEmpty) ? 'Please enter name' : null,
                ),
              ),
              const SizedBox(height: 20),

              // Type Selector
              _buildSectionLabel('TypeOf Medicine'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.neumorphicShadowInset,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DropdownButtonFormField<String>(
                  value: _selectedType,
                  icon: Icon(Icons.expand_more_rounded, color: AppTheme.textSecondary.withOpacity(0.5)),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.category_rounded, color: AppTheme.textSecondary.withOpacity(0.5), size: 18),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14), // Balanced vertical padding
                  ),
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                  dropdownColor: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
              ),
              const SizedBox(height: 20),

              // Calendar & Duration
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('Start Date'),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Container(
                            height: 60,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: AppTheme.neumorphicShadowInset,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_month, color: AppTheme.textSecondary.withOpacity(0.5), size: 18),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    "${_startDate.day}/${_startDate.month}/${_startDate.year}",
                                    style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('Duration'),
                        const SizedBox(height: 12),
                        Container(
                          height: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppTheme.neumorphicShadowInset,
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedDuration,
                            icon: Icon(Icons.expand_more_rounded, color: AppTheme.textSecondary.withOpacity(0.5)),
                            decoration: const InputDecoration(
                              border: InputBorder.none, 
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 18), // Centers text in 60h container
                            ),
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                            dropdownColor: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            selectedItemBuilder: (ctx) => _durations.map((item) {
                              if (item == 'Pick Date' && _customEndDate != null) {
                                final days = _customEndDate!.difference(_startDate).inDays + 1;
                                return Text("$days ${days == 1 ? 'Day' : 'Days'}");
                              }
                              return Text(item);
                            }).toList(),
                            items: _durations.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                            onChanged: (val) {
                              if (val == 'Pick Date') {
                                setState(() => _selectedDuration = 'Pick Date');
                                _selectCustomEndDate(context);
                              } else {
                                setState(() {
                                  _selectedDuration = val!;
                                  _customEndDate = null;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'ENDS: ${_calculatedEndDate.day}/${_calculatedEndDate.month}/${_calculatedEndDate.year}',
                    style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7), fontWeight: FontWeight.w700, fontSize: 10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Frequency
              _buildSectionLabel('Reminder Frequency'),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildFrequencyChip('Morning'),
                  _buildFrequencyChip('Noon'),
                  _buildFrequencyChip('Night'),
                ],
              ),
              const SizedBox(height: 24),

              // Instruction
              _buildSectionLabel('Special Instructions'),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildInstructionChip('Before Meal'),
                  _buildInstructionChip('After Meal'),
                  _buildInstructionChip('Any Time'),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.of(context).padding.bottom + 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2), // More transparent white-tinted glass
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.4), width: 0.5), // Subtle glass highlight
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  offset: const Offset(0, -1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: GestureDetector(
              onTap: _saveMedicine,
              child: Container(
                height: 55, // Slightly slimmer button
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.medicine != null ? 'Update Reminder' : 'Save Reminder',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: AppTheme.textPrimary.withOpacity(0.8),
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
