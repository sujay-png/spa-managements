import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';

// Model to carry all 4 health answers up to the parent
class HealthHistoryData {
  final String? skinAllergy;
  final String? isPregnant;
  final String? cardiacProblems;
  final String? recentSurgery;

  const HealthHistoryData({
    this.skinAllergy,
    this.isPregnant,
    this.cardiacProblems,
    this.recentSurgery,
  });
}

class ClientHealthHistory extends StatefulWidget {
  final ValueChanged<HealthHistoryData> onChanged;

  const ClientHealthHistory({super.key, required this.onChanged});

  @override
  State<ClientHealthHistory> createState() => _ClientHealthHistoryState();
}

class _ClientHealthHistoryState extends State<ClientHealthHistory> {
  String? _skinAllergy;
  String? _isPregnant;
  String? _cardiacProblems;
  String? _recentSurgery;

  void _notify() {
    widget.onChanged(HealthHistoryData(
      skinAllergy: _skinAllergy,
      isPregnant: _isPregnant,
      cardiacProblems: _cardiacProblems,
      recentSurgery: _recentSurgery,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final questions = [
      ('Are you allergic to any skin care products or oils?', _skinAllergy,
          (v) => setState(() { _skinAllergy = v; _notify(); })),
      ('Are you pregnant?', _isPregnant,
          (v) => setState(() { _isPregnant = v; _notify(); })),
      ('Do you have any cardiac / respiratory problems?', _cardiacProblems,
          (v) => setState(() { _cardiacProblems = v; _notify(); })),
      ('Have you undergone surgery or recent accident?', _recentSurgery,
          (v) => setState(() { _recentSurgery = v; _notify(); })),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Health History',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary
                ),
          ),
        ),
        ...questions.map((q) => _buildRow(context, q.$1, q.$2, q.$3)),
      ],
    );
  }

  Widget _buildRow(
    BuildContext context,
    String question,
    String? selected,
    void Function(String?) onSelect,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(question,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: ['Yes', 'No'].map((label) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label),
                  Checkbox(
                    visualDensity: VisualDensity.compact,
                    value: selected == label,
                    checkColor: Colors.white,
                    activeColor: Colors.purple,
                    side: const BorderSide(color: Colors.black54),
                    onChanged: (checked) =>
                        onSelect(checked == true ? label : null),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}