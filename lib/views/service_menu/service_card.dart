import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/models/spa_service.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';

class HoverableServiceCard extends StatefulWidget {
  final SpaService service;
  final bool isSelected;
  final ServiceOption? selectedOption;
  final Function(ServiceOption) onOptionToggled;

  const HoverableServiceCard({
    super.key,
    required this.service,
    required this.isSelected,
    this.selectedOption,
    required this.onOptionToggled,
  });

  @override
  State<HoverableServiceCard> createState() => _HoverableServiceCardState();
}

class _HoverableServiceCardState extends State<HoverableServiceCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isSelected
                ? AppColors.primary
                : (_isHovering ? AppColors.surfaceAlt : AppColors.warning),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(
                alpha: _isHovering || widget.isSelected ? 0.06 : 0.02,
              ),
              blurRadius: _isHovering ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.service.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E202B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.service.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B6E82),
                height: 1.4,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 20,
              runSpacing: 12,
              children: widget.service.options.map((option) {
                final bool isOptionSelected = widget.selectedOption == option;

                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => widget.onOptionToggled(option),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOptionSelected
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: isOptionSelected
                              ? AppColors.error
                              : const Color(0xFFCBD0D9),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: Color(0xFF6B6E82),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${option.duration} min',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4A4D60),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '₹${option.price}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isOptionSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isOptionSelected
                                    ? AppColors.textPrimary
                                    : const Color(0xFF4A4D60),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
