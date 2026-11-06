import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';

class GoalConcernData {
  final List<String> massageGoals;
  final List<String> bodyFocusAreas;

  const GoalConcernData({
    this.massageGoals = const [],
    this.bodyFocusAreas = const [],
  });

  bool get isValid => true;
}

class ClientgoalConcern extends StatefulWidget {
  final ValueChanged<GoalConcernData> onChanged;
  final GoalConcernData? initialData;

  const ClientgoalConcern({
    super.key,
    required this.onChanged,
    this.initialData,
  });

  @override
  State<ClientgoalConcern> createState() => _ClientgoalConcernState();
}

class _ClientgoalConcernState extends State<ClientgoalConcern> {
  List<String> _selectedGoals = [];
  List<String> _selectedFocusAreas = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _selectedGoals = List.from(widget.initialData!.massageGoals);
      _selectedFocusAreas = List.from(widget.initialData!.bodyFocusAreas);
    }
  }

  void _notify() {
    widget.onChanged(GoalConcernData(
      massageGoals: _selectedGoals,
      bodyFocusAreas: _selectedFocusAreas,
    ));
  }

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
                  color: AppColors.textPrimary,
                ),
          ),
        ),
        _buildQuestionSection(
          context: context,
          question: 'What result do you want from massage session(s)?',
          options: const ['Relaxation', 'Aroma relax', 'Stress relief', 'Pain relief'],
          selectedItems: _selectedGoals,
          onSelect: (v) => _toggleSelection(_selectedGoals, v!, true),
        ),
        const SizedBox(height: 16),
        _buildQuestionSection(
          context: context,
          question: 'Would you like us to focus more on any specific parts of the body?',
          options: const ['Head', 'Neck', 'Back', 'Legs'],
          selectedItems: _selectedFocusAreas,
          onSelect: (v) => _toggleSelection(_selectedFocusAreas, v!, false),
        ),
      ],
    );
  }

  Widget _buildQuestionSection({
    required BuildContext context,
    required String question,
    required List<String> options,
    required List<String> selectedItems,
    required void Function(String?) onSelect,
  }) {
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
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            Checkbox(
              value: isChecked,
              onChanged: (_) => onTap(),
              side: const BorderSide(color: Colors.black54),
              activeColor: AppColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
