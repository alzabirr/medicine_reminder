
  Widget _buildFrequencyChip(String label) {
    final isSelected = _selectedTimeSlots.contains(label);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedTimeSlots.add(label);
          } else {
            _selectedTimeSlots.remove(label);
          }
        });
      },
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildInstructionChip(String label) {
    final isSelected = _selectedInstruction == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedInstruction = label;
          });
        }
      },
    );
  }
