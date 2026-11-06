import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/models/spa_service.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';


class HoverableServiceCard extends StatefulWidget {
  final SpaService service;
  final bool isSelected;
  final ServiceOption? selectedOption;
  final Function(ServiceOption) onOptionToggled;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const HoverableServiceCard({
    super.key,
    required this.service,
    required this.isSelected,
    this.selectedOption,
    required this.onOptionToggled,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<HoverableServiceCard> createState() => _HoverableServiceCardState();
}

class _HoverableServiceCardState extends State<HoverableServiceCard> {
  bool _isHovering = false;

  void _setHovering(bool hovering) {
    if (_isHovering == hovering) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isHovering != hovering) {
        setState(() => _isHovering = hovering);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHovering(true),
      onExit: (_) => _setHovering(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 140),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isSelected
                ? AppColors.primary
                : (_isHovering
                    ? AppColors.primary.withOpacity(0.4)
                    : const Color(0xFFE8E8EE)),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(
                _isHovering || widget.isSelected ? 0.08 : 0.02,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.service.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E202B),
                    ),
                  ),
                ),
                if (widget.onEdit != null || widget.onDelete != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF6B6E82)),
                          tooltip: 'Edit Service',
                          splashRadius: 18,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          onPressed: widget.onEdit,
                        ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF6B6E82)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onSelected: (value) {
                          if (value == 'edit' && widget.onEdit != null) {
                            widget.onEdit!();
                          } else if (value == 'delete' && widget.onDelete != null) {
                            widget.onDelete!();
                          }
                        },
                        itemBuilder: (context) => [
                          if (widget.onEdit != null)
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 16, color: Color(0xFF6B6E82)),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                          if (widget.onDelete != null)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
            if (widget.service.description.isNotEmpty) ...[
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
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: widget.service.options.map((option) {
                final bool isOptionSelected = widget.selectedOption == option;
                final durationStr = option.label.isNotEmpty &&
                        option.label.toLowerCase().contains('min')
                    ? option.label
                    : '${option.duration} min';

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
                              ? AppColors.primary
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
                              durationStr,
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
