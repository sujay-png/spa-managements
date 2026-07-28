import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';

class GoalConcernData {
  // 1. Changed to Lists to hold multiple values
  final List<String> massageGoals;
  final List<String> bodyFocusAreas;

  const GoalConcernData({
    this.massageGoals = const [],
    this.bodyFocusAreas = const [],
  });
}

class ClientgoalConcern extends StatefulWidget {
  final ValueChanged<GoalConcernData> onChanged;

  const ClientgoalConcern({super.key, required this.onChanged});

  @override
  State<ClientgoalConcern> createState() => _ClientgoalConcernState();
}

class _ClientgoalConcernState extends State<ClientgoalConcern> {
  // 2. Initialize as empty lists
  List<String> _selectedGoals = [];
  List<String> _selectedFocusAreas = [];

  void _notify() {
    widget.onChanged(GoalConcernData(
      massageGoals: _selectedGoals,
      bodyFocusAreas: _selectedFocusAreas,
    ));
  }

  // 3. Helper logic to toggle items in a list
  void _toggleSelection(List<String> list, String value, bool isGoals) {
    setState(() {
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
      _notify();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            'Goals & Concerns',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary
                ),
          ),
        ),
        _buildQuestionSection(
          context,
          'What result do you want from massage session(s)?',
          ['Relaxation', 'Aroma relax', 'Stress relief', 'Pain relief'],
          _selectedGoals, // Pass the list
          (v) => _toggleSelection(_selectedGoals, v!, true),
        ),
        const SizedBox(height: 20),
        _buildQuestionSection(
          context,
          'Would you like us to focus more on any specific parts of the body?',
          ['Head', 'Neck', 'Back', 'Legs'],
          _selectedFocusAreas, // Pass the list
          (v) => _toggleSelection(_selectedFocusAreas, v!, false),
        ),
      ],
    );
  }

  Widget _buildQuestionSection(
    BuildContext context,
    String question,
    List<String> options,
    List<String> selectedItems, // Changed type to List
    void Function(String?) onSelect,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 40,
            runSpacing: 10,
            children: options
                .map((option) => _IndividualCheckbox(
                      label: option,
                      // 4. Check if the list contains the option
                      isChecked: selectedItems.contains(option), 
                      onTap: () => onSelect(option),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _IndividualCheckbox extends StatelessWidget {
  final String label;
  final bool isChecked;
  final VoidCallback onTap;

  const _IndividualCheckbox({
    required this.label,
    required this.isChecked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: InkWell( // Added InkWell so clicking the text also toggles
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(label,
                  style: Theme.of(context).textTheme.labelLarge),
            ),
            Checkbox(
              value: isChecked,
              onChanged: (_) => onTap(),
              side: const BorderSide(color: Colors.black54),
              activeColor: AppColors.textPrimary
            ),
          ],
        ),
      ),
    );
  }
}