import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/controllers/auth_controller.dart';
import 'package:ira_spa_webapp/controllers/service_controller.dart';
import 'package:ira_spa_webapp/models/spa_service.dart';
import 'package:ira_spa_webapp/views/services/selection_pannel.dart';
import 'package:ira_spa_webapp/components/service_card.dart';
import 'package:ira_spa_webapp/views/services/add_service_dialog.dart';
import 'package:provider/provider.dart';

class ServiceMenuView extends StatefulWidget {
  const ServiceMenuView({super.key});

  @override
  State<ServiceMenuView> createState() => _ServiceMenuViewState();
}

class _ServiceMenuViewState extends State<ServiceMenuView> {
  Map<SpaService, ServiceOption> selectedServices = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      if (auth.businessRef != null) {
        context.read<ServiceController>().loadServices(auth.businessRef!);
      }
    });
  }

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

  void _showAddServiceDialog(BuildContext context, [SpaService? serviceToEdit]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddServiceDialog(
        serviceToEdit: serviceToEdit,
        onSaved: () {
          final auth = context.read<AuthController>();
          if (auth.businessRef != null) {
            context.read<ServiceController>().loadServices(auth.businessRef!);
          }
          if (serviceToEdit != null) {
            setState(() {
              selectedServices.remove(serviceToEdit);
            });
          }
        },
      ),
    );
  }

  Future<void> _deleteService(SpaService service) async {
    final optionIds = service.options
        .map((o) => o.id)
        .whereType<int>()
        .toList();
    if (optionIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Service"),
        content: Text("Are you sure you want to delete '${service.title}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await context.read<ServiceController>().deleteServiceGroup(optionIds);
    setState(() {
      selectedServices.remove(service);
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Service "${service.title}" deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ServiceController>();
    final Map<String, List<SpaService>> menuData = controller.groupedSpaServices;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Scrollable Services
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Title and Add Service button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 165,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddServiceDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8C7A6B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text(
                          'Add Service',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                if (controller.loading && menuData.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (menuData.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.spa_outlined,
                            size: 56,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No services found in menu',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E202B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Click "Add Service" above to add your treatments.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B6E82),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...menuData.entries.map((entry) {
                    return _buildCategorySection(entry.key, entry.value);
                  }),
              ],
            ),
          ),
        ),

        // Right Column: Selection Panel
        Container(
          width: 350,
          margin: const EdgeInsets.fromLTRB(0, 40, 40, 40),
          child: SelectionPanel(
            selectedServices: selectedServices,
            onRemove: removeService,
            onClear: clearAllServices,
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
          final hasBackendId = service.options.any((o) => o.id != null);

          return HoverableServiceCard(
            service: service,
            isSelected: isServiceSelected,
            selectedOption: selectedServices[service],
            onOptionToggled: (option) => toggleServiceOption(service, option),
            onEdit: () => _showAddServiceDialog(context, service),
            onDelete: hasBackendId ? () => _deleteService(service) : null,
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }
}
