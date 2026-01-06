import 'dart:io';
import 'dart:ui';
import 'dart:async';
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
  final List<String> _types = ['Tablet', 'Pill', 'Liquid', 'Injection', 'Drop', 'Topical', 'Inhaler'];

  final Map<String, TimeOfDay> _selectedTimeSlots = {}; // {'Morning': TimeOfDay...}
  String _selectedInstruction = 'After Meal'; // 'Before Meal', 'After Meal', 'Any Time'

  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
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
      _selectedType = m.type; 
      if (!_types.contains(m.type)) {
         if (_types.isNotEmpty) _selectedType = _types.first; 
      }
      _selectedInstruction = m.instruction ?? 'After Meal';
      _startDate = DateTime(m.startTime.year, m.startTime.month, m.startTime.day);
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
           _customEndDate = DateTime(m.endDate!.year, m.endDate!.month, m.endDate!.day);
         }
      }
      
      // Parse time slots
      for (final slot in m.timeSlots) {
         final pivot = slot.indexOf(':');
         if (pivot != -1) {
            final label = slot.substring(0, pivot).trim();
            final timeStr = slot.substring(pivot + 1).trim();
            
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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  DateTime get _calculatedEndDate {
    if (_selectedDuration == 'Pick Date') {
      return _customEndDate ?? _startDate;
    }
    switch (_selectedDuration) {
      case '1 Week':
        return _startDate.add(const Duration(days: 6));
      case '2 Weeks':
        return _startDate.add(const Duration(days: 13));
      case '1 Month':
        // Inclusive month: if starts 20th, ends 19th of next month
        final nextMonth = DateTime(_startDate.year, _startDate.month + 1, _startDate.day);
        return nextMonth.subtract(const Duration(days: 1));
      default:
        // Default to 1 month inclusive
        final nextMonth = DateTime(_startDate.year, _startDate.month + 1, _startDate.day);
        return nextMonth.subtract(const Duration(days: 1));
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate.isBefore(today) ? today : _startDate,
      firstDate: today,
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  bool _showValidationErrors = false;

  void _saveMedicine() {
    setState(() => _showValidationErrors = true);
    
    if (_formKey.currentState!.validate()) {
      if (_selectedTimeSlots.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one time slot (Morning/Noon/Night)'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      final List<String> formattedTimeSlots = _selectedTimeSlots.entries.map((e) {
        final time = e.value;
        final timeString = time.format(context);
        return '${e.key}: $timeString';
      }).toList();

      if (widget.medicine != null) {
         Provider.of<MedicineProvider>(context, listen: false).updateMedicine(
            widget.medicine!,
            name: _nameController.text,
            type: _selectedType,
            timeSlots: formattedTimeSlots,
            instruction: _selectedInstruction,
            startDate: _startDate,
            endDate: _calculatedEndDate,
            imagePath: _image?.path,
            frequency: 1, // Default back to daily
         );
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicine Updated Successfully! 💊')),
         );
      } else {
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
          interval: 1, // Default back to daily
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
      case 'topical':
        return Icons.healing;
      case 'inhaler':
        return Icons.air_rounded;
      default:
        return Icons.medication_liquid;
    }
  }

  Widget _buildTypeSelector() {
    return SizedBox(
      height: 110, // Increased slightly to match new Frequency height
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        itemCount: _types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final type = _types[index];
          final isSelected = _selectedType == type;
          return GestureDetector(
            onTap: () => setState(() => _selectedType = type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 72,
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).primaryColor : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected 
                    ? [] // Remove shadow when selected
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                        const BoxShadow(
                          color: Colors.white,
                          blurRadius: 8,
                          offset: Offset(-2, -2),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   AnimatedContainer(
                     duration: const Duration(milliseconds: 300),
                     padding: const EdgeInsets.all(10),
                     decoration: BoxDecoration(
                       color: isSelected ? Colors.white.withValues(alpha: 0.2) : Theme.of(context).scaffoldBackgroundColor,
                       shape: BoxShape.circle,
                     ),
                     child: Icon(
                      _getIconForType(type),
                      size: 24,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                   ),
                  const SizedBox(height: 8),
                  Text(
                    type,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFrequencyChip(String label, IconData icon, List<Color> gradientColors) {
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 112, // Increased fixed height to prevent overflow
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10), // Reduced vertical padding
        decoration: BoxDecoration(
          gradient: isSelected 
             ? LinearGradient(
                 colors: gradientColors,
                 begin: Alignment.topLeft,
                 end: Alignment.bottomRight,
               )
             : LinearGradient(
                 colors: [AppTheme.surfaceColor, AppTheme.surfaceColor],
               ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: isSelected 
              ? [] // Remove shadow when selected
              : AppTheme.neumorphicShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.2) : Theme.of(context).scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon, 
                color: isSelected ? Colors.white : gradientColors.first.withValues(alpha: 0.7), 
                size: 22,
              ),
            ),
            const SizedBox(height: 6), // Reduced spacing
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                fontSize: 13,
              ),
            ),
            if (isSelected && selectedTime != null) ...[
              const SizedBox(height: 4), // Reduced spacing
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  selectedTime.format(context),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionChip(String label, IconData icon) {
    final isSelected = _selectedInstruction == label;
    final primaryColor = Theme.of(context).primaryColor;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedInstruction = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 60, // Match Start Date height
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected 
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ] 
              : AppTheme.neumorphicShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.2) : primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isDataRetrieved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataRetrieved) {
      _isDataRetrieved = true;
      _retrieveLostData();
    }
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).textTheme.titleLarge?.color, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.medicine != null ? 'Edit Medicine' : 'Add Medicine',
          style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 140),
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
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.getNeumorphicShadow(context),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 105,
                          height: 105,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).cardColor,
                            boxShadow: AppTheme.getNeumorphicShadowInset(context),
                          ),
                        ),
                        Container(
                          width: 95,
                          height: 95,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).cardColor,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _image != null
                              ? Image.file(_image!, fit: BoxFit.cover)
                              : Icon(
                                  _getIconForType(_selectedType),
                                  size: 40,
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                                ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: AppTheme.neumorphicShadow,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title Section - Name
              _buildSectionLabel('Medicine Name'),
              const SizedBox(height: 12),
              _MedicineNameInput(
                controller: _nameController,
                showError: _showValidationErrors,
              ),
              const SizedBox(height: 24),

              // Horizontal Type Selector
              _buildSectionLabel('Medicine Type'),
              const SizedBox(height: 12),
              _buildTypeSelector(),
              const SizedBox(height: 24),

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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: AppTheme.neumorphicShadow,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.calendar_month_rounded, color: Theme.of(context).primaryColor, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    "${_startDate.day}/${_startDate.month}",
                                    style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('Duration'),
                        const SizedBox(height: 12),
                        Container(
                          height: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppTheme.neumorphicShadow,
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedDuration,
                            icon: Icon(Icons.keyboard_arrow_down_rounded, color: Theme.of(context).primaryColor),
                            decoration: const InputDecoration(
                              border: InputBorder.none, 
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 18),
                            ),
                            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 13, fontWeight: FontWeight.bold),
                            dropdownColor: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            selectedItemBuilder: (ctx) => _durations.map((item) {
                               if (item == 'Pick Date' && _customEndDate != null) {
                                 final days = _customEndDate!.difference(_startDate).inDays + 1;
                                 return Text("$days Days");
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
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Ends: ${_calculatedEndDate.day}/${_calculatedEndDate.month}/${_calculatedEndDate.year}',
                  style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500, fontSize: 11),
                ),
              ),
              const SizedBox(height: 24),

              // Frequency
              _buildSectionLabel('Reminder Frequency'),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Expanded(
                     child: _buildFrequencyChip(
                       'Morning', 
                       Icons.wb_sunny_rounded, 
                       [const Color(0xFFFF9800), const Color(0xFFFFC107)] // Bold Sunrise
                     )
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: _buildFrequencyChip(
                       'Noon', 
                       Icons.wb_cloudy_rounded, 
                       [const Color(0xFF2196F3), const Color(0xFF03A9F4)] // Bold Day
                     )
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: _buildFrequencyChip(
                       'Night', 
                       Icons.nights_stay_rounded, 
                       [const Color(0xFF3F51B5), const Color(0xFF673AB7)] // Bold Evening
                     )
                   ),
                ],
              ),
              
              if (_showValidationErrors && _selectedTimeSlots.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text('Please select at least one time', style: TextStyle(color: AppTheme.errorColor, fontSize: 12)),
                ),

              const SizedBox(height: 24),

              // Instruction
              _buildSectionLabel('When to take?'),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildInstructionChip('Before Meal', Icons.restaurant),
                  ),
                  const SizedBox(width: 16), // Match Date picker gap
                  Expanded(
                    child: _buildInstructionChip('After Meal', Icons.dinner_dining),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withValues(alpha: 0.8)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _saveMedicine,
              borderRadius: BorderRadius.circular(20),
              child: const Center(
                child: Text(
                  'Save Medicine',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
        label,
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }
}

// Optimized widget to handle hint animation without re-rendering entire screen
class _MedicineNameInput extends StatefulWidget {
  final TextEditingController controller;
  final bool showError;
  const _MedicineNameInput({required this.controller, this.showError = false});

  @override
  State<_MedicineNameInput> createState() => _MedicineNameInputState();
}

class _MedicineNameInputState extends State<_MedicineNameInput> {
  @override
  Widget build(BuildContext context) {
    final hasError = widget.showError && widget.controller.text.isEmpty;
    
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasError ? AppTheme.errorColor.withValues(alpha: 0.5) : Colors.transparent,
          width: 2,
        ),
        boxShadow: hasError 
          ? [BoxShadow(color: AppTheme.errorColor.withValues(alpha: 0.1), blurRadius: 8, spreadRadius: 1)]
          : AppTheme.getNeumorphicShadowInset(context),
      ),
      child: TextFormField(
        controller: widget.controller,
        decoration: InputDecoration(
          hintText: 'Type your medicine name...',
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 10),
            child: Icon(
              Icons.medication, 
              color: hasError ? AppTheme.errorColor : AppTheme.textSecondary.withValues(alpha: 0.5), 
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          filled: false,
          isDense: true,
          border: InputBorder.none,
          errorStyle: const TextStyle(height: 0, fontSize: 0), // Hide default error text
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          hintStyle: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.4)),
        ),
        style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
        validator: (value) => (value == null || value.isEmpty) ? '' : null,
      ),
    );
  }
}
