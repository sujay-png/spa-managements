import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/components/service_card.dart';
import 'package:ira_spa_webapp/controllers/auth_controller.dart';
import 'package:ira_spa_webapp/controllers/service_controller.dart';
import 'package:ira_spa_webapp/models/service_model.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';
import 'package:provider/provider.dart';

class ServicePage extends StatefulWidget {
  const ServicePage({super.key});

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  final _formKey = GlobalKey<FormState>();
  final dialofformkey = GlobalKey<FormState>();

  final _serviceNameController = TextEditingController();
  final _designationController = TextEditingController();
  final _durationController = TextEditingController();
  final _priceController = TextEditingController();
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();

      if (auth.businessRef != null) {
        context.read<ServiceController>().loadServices(auth.businessRef!);
      } else {
        debugPrint("Business Ref is null");
      }
    });
  }

  bool _saving = false;
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ServiceController>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                "Services",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 23,
                  fontWeight: FontWeight.w500,
                ),
              ),

              Row(
                children: [
                  const Text(
                    "Manage your spa services and treatment",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const Spacer(flex: 50),

                  SizedBox(
                    width: 165,

                    child: ElevatedButton.icon(
                      onPressed: () {
                        showserviceform(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8C7A6B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                        'Add Service',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 15,
                          color: AppColors.surface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // GridView builder
              controller.loading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.services.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.45,
                          ),
                      itemBuilder: (context, index) {
                        final service = controller.services[index];
                        return ServiceCard(
                          title: service.serviceName,
                          category: service.designation,
                          duration: service.duration,
                          price: "₹${service.price.toStringAsFixed(0)}",
                          bookings: '${controller.bookingCounts}',
                          revenue: "₹0",
                          badge: "Active",

                          onEdit: () {
                            showserviceform(context, service: service);
                          },
                          onDelete: () {
                            _deleteService(service);
                          },
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  //===================================Save Service===================================
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();

    if (auth.businessRef == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Business reference not found.")),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await context.read<ServiceController>().addService(
        ServiceModel(
          // id: '',
          businessRef: auth.businessRef!,
          serviceName: _serviceNameController.text.trim(),
          designation: _designationController.text.trim(),
          duration: _durationController.text.trim(),
          price: double.tryParse(_priceController.text.trim()) ?? 0,
        ),
      );

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service added successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error adding service: $e');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add service: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  //======================================Add Service form=======================================
  void showserviceform(BuildContext context, {ServiceModel? service}) {
    final isedit = service != null;
 
    if (service != null) {
      _serviceNameController.text = service.serviceName;
      _designationController.text = service.designation;
      _durationController.text = service.duration;
      _priceController.text = service.price.toString();
    }
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            child: Form(
              key: dialofformkey,
              child: Container(
                width: 480,
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isedit ? 'Edit Customer' : 'Add New Service',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Fill in the details below',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 20,
                              color: Colors.grey,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(height: 32, thickness: 1),
                      label(Icons.person_outline, 'Service Name'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _serviceNameController,
                        decoration: dec('Enter Service Name'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please Service Name";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                label(Icons.email_outlined, 'Duration'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _durationController,
                                  decoration: dec('Enter duration'),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "Please Enter duration";
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                label(Icons.phone_outlined, 'Price'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _priceController,
                                  decoration: dec('Enter the amount'),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "Please Enter amount";
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      label(null, 'Designation'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _designationController,
                        decoration: dec('Enter Designation.'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please Enter Designation";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      const SizedBox(height: 24),
                      const Divider(height: 1, thickness: 1),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (isedit) {
                                  final updateservice = ServiceModel(
                                    id: service.id,
                                    businessRef: service.businessRef,
                                    serviceName: _serviceNameController.text
                                        .trim(),
                                    designation: _designationController.text
                                        .trim(),
                                    duration: _durationController.text.trim(),
                                    price:
                                        double.tryParse(
                                          _priceController.text.trim(),
                                        ) ??
                                        0.0,
                                  );
                                  await context
                                      .read<ServiceController>()
                                      .updatedservice(updateservice);
                                  if (!mounted) return;

                                  Navigator.pop(context);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "service updated successfully",
                                      ),
                                    ),
                                  );
                                } else {
                                  _save();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B7D76),
                                disabledBackgroundColor: Colors.grey.shade400,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      isedit
                                          ? 'Update service'
                                          : 'Create service',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteService(ServiceModel service) async {
    if (service.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Service"),
        content: const Text("Are you sure you want to delete this service?"),
        actions: [
         
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    try {
      await context.read<ServiceController>().deleteservice(service.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Service deleted successfully")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to delete: $e")));
    }
  }

  //=====================Helper function================================
  InputDecoration dec(String hint, [IconData? suffix]) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
    filled: true,
    fillColor: const Color(0xFFF7F5F0),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    suffixIcon: suffix != null
        ? Icon(suffix, size: 18, color: Colors.grey.shade600)
        : null,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF8B7D76)),
    ),
  );

  Widget label(IconData? icon, String text) => Row(
    children: [
      if (icon != null) ...[
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 6),
      ],
      Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: Colors.grey.shade700,
        ),
      ),
    ],
  );
}
