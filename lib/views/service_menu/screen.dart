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
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 40,
            right: 430,
            top: 40,
            bottom: 40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Column(
                  children: [
                    Text(
                      'Service Menu',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF1E202B),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Choose the treatments that will make your day perfect',
                      style: TextStyle(fontSize: 16, color: Color(0xFF6B6E82)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ...spaMenuData.entries.map((entry) {
                return _buildCategorySection(entry.key, entry.value);
              }).toList(),
            ],
          ),
        ),

        Positioned(
          top: 40,
          right: 40,
          width: 350,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height - 80,
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

