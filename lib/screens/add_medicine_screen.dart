import 'dart:io';
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
  final List<String> _types = ['Pill', 'Tablet','Liquid', 'Injection', 'Drop'];

  final Map<String, TimeOfDay> _selectedTimeSlots = {}; // {'Morning': TimeOfDay...}
  String _selectedInstruction = 'After Meal'; // 'Before Meal', 'After Meal', 'Any Time'

  DateTime _startDate = DateTime.now();
  String _selectedDuration = '1 Month';
  final List<String> _durations = ['1 Week', '2 Weeks', '1 Month', '2 Months', '3 Months', '6 Months'];

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
    switch (_selectedDuration) {
      case '1 Week':
        return _startDate.add(const Duration(days: 7));
      case '2 Weeks':
        return _startDate.add(const Duration(days: 14));
      case '1 Month':
        return DateTime(_startDate.year, _startDate.month + 1, _startDate.day);
      case '2 Months':
        return DateTime(_startDate.year, _startDate.month + 2, _startDate.day);
      case '3 Months':
        return DateTime(_startDate.year, _startDate.month + 3, _startDate.day);
      case '6 Months':
        return DateTime(_startDate.year, _startDate.month + 6, _startDate.day);
      default:
        return _startDate.add(const Duration(days: 30));
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
          // Default time logic
          TimeOfDay initialTime;
          if (label == 'Morning') {
            initialTime = const TimeOfDay(hour: 8, minute: 0); // 8:00 AM
          } else if (label == 'Noon') {
            initialTime = const TimeOfDay(hour: 13, minute: 0); // 1:00 PM
          } else {
            initialTime = const TimeOfDay(hour: 21, minute: 0); // 9:00 PM
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                child: Icon(Icons.check_circle, size: 18, color: Theme.of(context).primaryColor),
              ),
            Text(
              isSelected && selectedTime != null 
                  ? '$label (${selectedTime.format(context)})' 
                  : label,
              style: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
            color: isSelected ? Theme.of(context).primaryColor : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
      if (response.isEmpty) {
        return;
      }
      if (response.file != null) {
        if (mounted) {
          setState(() {
            _image = File(response.file!.path);
          });
        }
      } else {
        debugPrint('Lost data error: ${response.exception}');
      }
    } catch (e) {
      debugPrint('Error retrieving lost data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.medicine != null ? 'Edit Medicine' : 'Add Medicine')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.neumorphicShadowInset,
                    ),
                    child: _image == null
                        ? Icon(Icons.add_a_photo, size: 40, color: AppTheme.textSecondary)
                        : ClipOval(
                            child: Image.file(_image!, fit: BoxFit.cover),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Name
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.neumorphicShadowInset,
                ),
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Medicine Name',
                    prefixIcon: Icon(Icons.medication, color: AppTheme.textSecondary),
                    filled: false,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    labelStyle: TextStyle(color: AppTheme.textSecondary),
                  ),
                  style: TextStyle(color: AppTheme.textPrimary),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter medicine name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 30),

              // Type Dropdown
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.neumorphicShadowInset,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type of Medicine',
                    prefixIcon: Icon(Icons.category, color: AppTheme.textSecondary),
                    filled: false,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    labelStyle: TextStyle(color: AppTheme.textSecondary),
                  ),
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                  dropdownColor: AppTheme.surfaceColor,
                  items: _types.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedType = newValue!;
                    });
                  },
                ),
              ),
              const SizedBox(height: 30),

              // Duration & Start Date Row (same height)
              Row(
                children: [
                  // Start Date Picker
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppTheme.neumorphicShadowInset,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: AppTheme.textSecondary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Start Date',
                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                  ),
                                  Text(
                                    "${_startDate.day}/${_startDate.month}/${_startDate.year}",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Duration Dropdown
                  Expanded(
                    child: Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppTheme.neumorphicShadowInset,
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedDuration,
                        decoration: const InputDecoration(
                          filled: false,
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                        ),
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                        dropdownColor: AppTheme.surfaceColor,
                        items: _durations.map((String duration) {
                          return DropdownMenuItem<String>(
                            value: duration,
                            child: Text(duration),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedDuration = newValue!;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Ends: ${_calculatedEndDate.day}/${_calculatedEndDate.month}/${_calculatedEndDate.year}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 32),

              // Frequency Chips
              Text('Frequency', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _buildFrequencyChip('Morning'),
                  _buildFrequencyChip('Noon'),
                  _buildFrequencyChip('Night'),
                ],
              ),
              const SizedBox(height: 32),

              // Instruction Chips
              Text('When to Take', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: [
                  _buildInstructionChip('Before Meal'),
                  _buildInstructionChip('After Meal'),
                  _buildInstructionChip('Any Time'),
                ],
              ),
              const SizedBox(height: 48),

              // Save Button
              GestureDetector(
                onTap: _saveMedicine,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      // Light Shadow (Top Left)
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        offset: const Offset(-6, -6),
                        blurRadius: 12,
                      ),
                      // Dark Shadow (Bottom Right)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(6, 6),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text(
                        'Save Reminder',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
