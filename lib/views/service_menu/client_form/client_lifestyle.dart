import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';

class LifestyleData {
  final String? lifestyleType;
  final String? sessionFrequency;

  const LifestyleData({this.lifestyleType, this.sessionFrequency});
}

class ClientLifestyle extends StatefulWidget {
  final ValueChanged<LifestyleData> onChanged;

  const ClientLifestyle({super.key, required this.onChanged});

  @override
  State<ClientLifestyle> createState() => _ClientLifestyleState();
}

class _ClientLifestyleState extends State<ClientLifestyle> {
  String? _lifestyleType;
  String? _sessionFrequency;

  void _notify() {
    widget.onChanged(LifestyleData(
      lifestyleType: _lifestyleType,
      sessionFrequency: _sessionFrequency,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            'Lifestyle',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color:AppColors.textPrimary
                ),
          ),
        ),
        _buildQuestionSection(
          context,
          'Which of the following most reflects your own life style?',
          ['Lots of free time and enjoy spa services', 'Busy, but makes time for spa'],
          _lifestyleType,
          (v) => setState(() { _lifestyleType = v; _notify(); }),
        ),
        const SizedBox(height: 20),
        _buildQuestionSection(
          context,
          'How often do you want your spa session?',
          ['Every week', 'Every 2 weeks', 'Once/Month'],
          _sessionFrequency,
          (v) => setState(() { _sessionFrequency = v; _notify(); }),
        ),
      ],
    );
  }

  Widget _buildQuestionSection(
    BuildContext context,
    String question,
    List<String> options,
    String? selected,
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
                      isChecked: selected == option,
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
      width: 180,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
              child: Text(label,
                  style: Theme.of(context).textTheme.labelLarge)),
          Checkbox(
            value: isChecked,
            onChanged: (_) => onTap(),
            side: const BorderSide(color: Colors.black54),
            activeColor: Colors.purple,
          ),
        ],
      ),
    );
  }
}