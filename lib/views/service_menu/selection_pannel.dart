import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';
import 'package:ira_spa_webapp/views/service_menu/client_form/clientdetails.dart';
import '../../models/spa_service.dart';

class SelectionPanel extends StatelessWidget {
  final Map<SpaService, ServiceOption> selectedServices;
  final Function(SpaService) onRemove;
  final VoidCallback onClear;

  const SelectionPanel({
    super.key,
    required this.selectedServices,
    required this.onRemove,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    int totalPrice = selectedServices.values.fold(
      0,
      (sum, option) => sum + option.price,
    );
    int totalMinutes = selectedServices.values.fold(
      0,
      (sum, option) => sum + option.duration,
    );

    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    String durationString = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.border,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.shopping_bag_outlined, color: Color(0xFF9C27B0)),
              SizedBox(width: 10),
              Text(
                'Your Selection',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1E202B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          selectedServices.isEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(width: double.infinity),
                    Text(
                      'No services selected yet',
                      style: TextStyle(
                        color: Color(0xFF6B6E82),
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Click on services to add them',
                      style: TextStyle(
                        color: Color(0xFFA0A3B1),
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: selectedServices.entries.map((entry) {
                        final service = entry.key;
                        final option = entry.value;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      service.title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1E202B),
                                      ),
                                    ),
                                  ),
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () => onRemove(service),
                                      child: const Icon(
                                        Icons.close,
                                        size: 18,
                                        color: Color(0xFFA0A3B1),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${option.duration} min',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B6E82),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '₹${option.price}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Divider(
                                color: Color(0xFFF3F3F5),
                                height: 1,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

          if (selectedServices.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Duration',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B6E82)),
                ),
                Text(
                  durationString,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E202B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Price',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E202B),
                  ),
                ),
                Text(
                  '₹$totalPrice',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext context) {
                      return Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 850),
                          child: ClientDetails(
                            selectedServices: selectedServices,
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.textPrimary,
                  ),
                  child: const Center(
                    child: Text(
                      'Book Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Center(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onClear,
                  child: const Text(
                    'Clear Selection',
                    style: TextStyle(color: Color(0xFF6B6E82), fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
