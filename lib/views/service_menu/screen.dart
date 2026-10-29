import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/models/spa_service.dart';
import 'package:ira_spa_webapp/models/repository.dart';
import 'package:ira_spa_webapp/views/service_menu/selection_pannel.dart';
import 'package:ira_spa_webapp/views/service_menu/service_card.dart';

class ServiceMenuView extends StatefulWidget {
  const ServiceMenuView({super.key});

  @override
  State<ServiceMenuView> createState() => _ServiceMenuViewState();
}

class _ServiceMenuViewState extends State<ServiceMenuView> {
  Map<SpaService, ServiceOption> selectedServices = {};

  void toggleServiceOption(SpaService service, ServiceOption option) {
    setState(() {
      if (selectedServices[service] == option) {
        selectedServices.remove(service);
      } else {
        selectedServices[service] = option;
      }
    });
  }

  void removeService(SpaService service) {
    setState(() {
      selectedServices.remove(service);
    });
  }

  void clearAllServices() {
    setState(() {
      selectedServices.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 950;

        if (isCompact) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Service Menu',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E202B),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose the treatments that will make your day perfect',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B6E82)),
                ),
                const SizedBox(height: 20),
                SelectionPanel(
                  selectedServices: selectedServices,
                  onRemove: removeService,
                  onClear: clearAllServices,
                ),
                const SizedBox(height: 24),
                ...spaMenuData.entries.map(
                  (entry) => _buildCategorySection(entry.key, entry.value),
                ),
              ],
            ),
          );
        }

        // Tablet Landscape & Desktop: 2-column side-by-side layout
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Service Menu',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF1E202B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose the treatments that will make your day perfect',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B6E82),
                      ),
                    ),
                    const SizedBox(height: 36),
                    ...spaMenuData.entries.map(
                      (entry) => _buildCategorySection(entry.key, entry.value),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 360,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  right: 28,
                  top: 32,
                  bottom: 32,
                ),
                child: SelectionPanel(
                  selectedServices: selectedServices,
                  onRemove: removeService,
                  onClear: clearAllServices,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategorySection(String categoryName, List<SpaService> services) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          categoryName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1E202B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 1,
          width: double.infinity,
          color: const Color(0xFFEADBEE),
        ),
        const SizedBox(height: 20),
        ...services.map((service) {
          final bool isServiceSelected = selectedServices.containsKey(service);

          return HoverableServiceCard(
            service: service,
            isSelected: isServiceSelected,
            selectedOption: selectedServices[service],
            onOptionToggled: (option) => toggleServiceOption(service, option),
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }
}
