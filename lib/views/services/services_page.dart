import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ira_spa_webapp/controllers/booking_controller.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      if (auth.businessRef != null) {
        context.read<ServiceController>().loadServices(auth.businessRef!);
        context.read<BookingController>().loadBookings(auth.businessRef!);
      }
    });
  }

  int? _loadedBusinessRef;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthController>();
    if (auth.businessRef != null && auth.businessRef != _loadedBusinessRef) {
      _loadedBusinessRef = auth.businessRef;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<ServiceController>().loadServices(auth.businessRef!);
        context.read<BookingController>().loadBookings(auth.businessRef!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ServiceController>();
    final bookingCtrl = context.watch<BookingController>();
    final auth = context.watch<AuthController>();

    int getServiceCount(ServiceModel service) {
      final ctrlCount = controller.getBookingCount(service.id);
      if (ctrlCount > 0) return ctrlCount;
      final sName = service.serviceName.trim().toLowerCase();
      return bookingCtrl.bookings.where((b) {
        if (service.id != null &&
            (b.serviceRef == service.id || b.serviceOptionId == service.id)) {
          return true;
        }
        final bName = b.servicename.trim().toLowerCase();
        if (sName.isEmpty || bName.isEmpty) return false;
        return bName == sName || bName.contains(sName) || sName.contains(bName);
      }).length;
    }

    double getServiceRevenue(ServiceModel service, int count) {
      final ctrlRev = controller.getRevenue(service);
      if (ctrlRev > 0) return ctrlRev;
      return service.price * count;
    }

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
                  IconButton(
                    tooltip: 'Refresh Data',
                    icon: const Icon(
                      Icons.refresh,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () async {
                      final ref = auth.businessRef;
                      if (ref != null) {
                        await controller.loadServices(ref);
                        await bookingCtrl.loadBookings(ref);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Refreshed: ${controller.services.length} services, ${bookingCtrl.bookings.length} bookings found',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),

                  SizedBox(
                    width: 165,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showAddServiceDialog(context);
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
                        final bookingCount = getServiceCount(service);
                        final revenue =
                            getServiceRevenue(service, bookingCount);
                        return ServiceCard(
                          title: service.serviceName,
                          category: service.designation,
                          duration: service.duration,
                          price: "₹${service.price.toStringAsFixed(0)}",
                          bookings: '$bookingCount',
                          revenue: "₹${revenue.toStringAsFixed(0)}",
                          badge: "Active",
                          onEdit: () {
                            _showEditServiceDialog(context, service: service);
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

  // ─── New rich "Add Service" dialog ───────────────────────────────────────────

  void _showAddServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AddServiceDialog(
        onSaved: () {
          final auth = context.read<AuthController>();
          if (auth.businessRef != null) {
            context.read<ServiceController>().loadServices(auth.businessRef!);
          }
        },
      ),
    );
  }

  // ─── Edit service dialog (single row edit, existing behaviour) ────────────

  void _showEditServiceDialog(BuildContext context, {required ServiceModel service}) {
    final nameCtrl = TextEditingController(text: service.serviceName);
    final catCtrl = TextEditingController(text: service.designation);
    final durCtrl = TextEditingController(text: service.duration);
    final priceCtrl = TextEditingController(text: service.price.toStringAsFixed(0));
    final descCtrl = TextEditingController(text: service.description ?? '');
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit Service',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _dialogLabel(Icons.spa_outlined, 'Service Name'),
                    const SizedBox(height: 8),
                    _dialogField(nameCtrl, 'e.g. Classic Swedish Therapy',
                        required: true),
                    const SizedBox(height: 14),
                    _dialogLabel(null, 'Category'),
                    const SizedBox(height: 8),
                    _dialogField(catCtrl, 'e.g. Body Massage',
                        required: true),
                    const SizedBox(height: 14),
                    _dialogLabel(Icons.description_outlined, 'Description'),
                    const SizedBox(height: 8),
                    _dialogField(descCtrl, 'Short description of the service',
                        maxLines: 3),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _dialogLabel(
                                  Icons.access_time_outlined, 'Duration'),
                              const SizedBox(height: 8),
                              _dialogField(durCtrl, 'e.g. 60 min',
                                  required: true),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _dialogLabel(
                                  Icons.currency_rupee, 'Price (₹)'),
                              const SizedBox(height: 8),
                              _dialogField(priceCtrl, 'e.g. 2200',
                                  required: true,
                                  keyboardType: TextInputType.number),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              side:
                                  BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: saving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate())
                                      return;
                                    setS(() => saving = true);
                                    try {
                                      final updated = ServiceModel(
                                        id: service.id,
                                        businessRef: service.businessRef,
                                        serviceName: nameCtrl.text.trim(),
                                        designation: catCtrl.text.trim(),
                                        duration: durCtrl.text.trim(),
                                        price:
                                            double.tryParse(priceCtrl.text.trim()) ??
                                                0,
                                        description: descCtrl.text.trim(),
                                      );
                                      if (!context.mounted) return;
                                      await context
                                          .read<ServiceController>()
                                          .updatedservice(updated);
                                      if (!context.mounted) return;
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Service updated successfully')),
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content:
                                                Text('Update failed: $e')),
                                      );
                                    } finally {
                                      setS(() => saving = false);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B7D76),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: saving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : const Text('Update',
                                    style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete",
                style: TextStyle(color: Colors.white)),
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
        const SnackBar(content: Text('Service deleted successfully')),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      if (e.code == '23503') {
        final unlink = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Service Linked to Bookings'),
            content: const Text(
              'This service is linked to existing bookings. Unlink and delete?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Unlink & Delete',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (unlink == true && mounted) {
          try {
            await Supabase.instance.client
                .from('Booking')
                .update({'service_id': null})
                .eq('service_id', service.id!);
            await context.read<ServiceController>().deleteservice(service.id!);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Service unlinked and deleted successfully')),
            );
          } catch (err) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete: $err')),
            );
          }
        }
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  // ─── Shared helper widgets ────────────────────────────────────────────────

  Widget _dialogLabel(IconData? icon, String text) => Row(
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

  Widget _dialogField(
    TextEditingController ctrl,
    String hint, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          filled: true,
          fillColor: const Color(0xFFF7F5F0),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        ),
        validator: required
            ? (v) =>
                (v == null || v.trim().isEmpty) ? 'Required field' : null
            : null,
      );
}

// ─── Dedicated Add Service Dialog Widget ─────────────────────────────────────

class _AddServiceDialog extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddServiceDialog({required this.onSaved});

  @override
  State<_AddServiceDialog> createState() => _AddServiceDialogState();
}

class _AddServiceDialogState extends State<_AddServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  // Each option: {duration: TextEditingController, price: TextEditingController}
  final List<Map<String, TextEditingController>> _options = [];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Start with one option row
    _addOptionRow();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _catCtrl.dispose();
    _descCtrl.dispose();
    for (final o in _options) {
      o['duration']!.dispose();
      o['price']!.dispose();
    }
    super.dispose();
  }

  void _addOptionRow() {
    setState(() {
      _options.add({
        'duration': TextEditingController(),
        'price': TextEditingController(),
      });
    });
  }

  void _removeOptionRow(int idx) {
    setState(() {
      _options[idx]['duration']!.dispose();
      _options[idx]['price']!.dispose();
      _options.removeAt(idx);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthController>();
    if (auth.businessRef == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business reference not found')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final serviceName = _nameCtrl.text.trim();
      final category = _catCtrl.text.trim();
      final description = _descCtrl.text.trim();
      final businessRef = auth.businessRef!;

      final List<ServiceModel> rows = _options.map((o) {
        final dur = o['duration']!.text.trim();
        final price = double.tryParse(o['price']!.text.trim()) ?? 0;
        // Normalise duration label: add "min" if pure number
        final durLabel = RegExp(r'^\d+$').hasMatch(dur) ? '$dur min' : dur;
        return ServiceModel(
          serviceName: serviceName,
          designation: category,
          duration: durLabel,
          price: price,
          businessRef: businessRef,
          description: description.isEmpty ? null : description,
        );
      }).toList();

      await context.read<ServiceController>().addServiceWithOptions(rows);

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Service "${_nameCtrl.text.trim()}" added with ${rows.length} option(s)!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                color: Color(0xFFF9F6F3),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4A373).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.spa_outlined,
                        color: Color(0xFFD4A373), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Service',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C2E3E),
                          ),
                        ),
                        Text(
                          'Fill in the service details and pricing options',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF6B6E82)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Form ────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service Name
                      _sectionLabel('SERVICE DETAILS'),
                      const SizedBox(height: 14),
                      _fieldLabel(Icons.spa_outlined, 'Service Name *'),
                      const SizedBox(height: 6),
                      _field(_nameCtrl, 'e.g. Classic Swedish Therapy',
                          required: true),

                      const SizedBox(height: 16),
                      _fieldLabel(null, 'Category *'),
                      const SizedBox(height: 6),
                      _field(_catCtrl, 'e.g. Body Massage, Herbal Therapy',
                          required: true),

                      const SizedBox(height: 16),
                      _fieldLabel(
                          Icons.description_outlined, 'Description'),
                      const SizedBox(height: 6),
                      _field(
                        _descCtrl,
                        'Describe what this service includes…',
                        maxLines: 3,
                      ),

                      const SizedBox(height: 24),

                      // Options section — matches the card design
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _sectionLabel('DURATION & PRICING OPTIONS'),
                          TextButton.icon(
                            onPressed:
                                _options.length < 5 ? _addOptionRow : null,
                            icon: const Icon(Icons.add_circle_outline,
                                size: 16),
                            label: const Text('Add Option'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFD4A373),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // ── Live preview of options (matches card design) ────
                      if (_options.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF8F5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFFE8E8EE), width: 1),
                          ),
                          child: Center(
                            child: Text(
                              'No pricing options yet — tap "Add Option"',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        // Shows a preview card just like HoverableServiceCard
                        _buildPreviewCard(),

                      const SizedBox(height: 20),

                      // Input rows for each option
                      ..._options.asMap().entries.map((e) {
                        final idx = e.key;
                        final o = e.value;
                        return _buildOptionRow(idx, o);
                      }),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),

            // ── Footer buttons ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F6F3),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(
                    top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.black87)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving || _options.isEmpty ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5C3D2E),
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Save Service',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Live preview card ────────────────────────────────────────────────────

  Widget _buildPreviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4A373), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4A373).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category tag
          if (_catCtrl.text.isNotEmpty)
            Text(
              _catCtrl.text.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFD4A373),
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 4),
          // Service name
          Text(
            _nameCtrl.text.isEmpty
                ? 'SERVICE NAME'
                : _nameCtrl.text.toUpperCase(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Color(0xFF2C2E3E),
            ),
          ),
          if (_descCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _descCtrl.text,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
            ),
          ],
          const SizedBox(height: 14),
          // Options row (matches screenshot)
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: _options.map((o) {
              final dur = o['duration']!.text.trim();
              final priceStr = o['price']!.text.trim();
              final durLabel = dur.isEmpty
                  ? '-- min'
                  : RegExp(r'^\d+$').hasMatch(dur)
                      ? '$dur min'
                      : dur;
              final priceLabel =
                  priceStr.isEmpty ? '₹--' : '₹$priceStr';
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                          color: const Color(0xFFCBD0D9), width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.access_time,
                      size: 13, color: Color(0xFF6B7280)),
                  const SizedBox(width: 3),
                  Text(
                    '$durLabel  $priceLabel',
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF2C2E3E)),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Option input row ─────────────────────────────────────────────────────

  Widget _buildOptionRow(
      int idx, Map<String, TextEditingController> option) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(top: 10, right: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFD4A373).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${idx + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD4A373),
                ),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel(
                          Icons.access_time_outlined, 'Duration'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: option['duration'],
                        decoration: _dec('e.g. 60'),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter duration'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel(Icons.currency_rupee, 'Price (₹)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: option['price'],
                        decoration: _dec('e.g. 2200'),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Enter price';
                          if (double.tryParse(v.trim()) == null)
                            return 'Invalid';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_options.length > 1)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  color: Colors.red, size: 20),
              onPressed: () => _removeOptionRow(idx),
            ),
        ],
      ),
    );
  }

  // ── Shared helper widgets ────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.3,
          color: Color(0xFF8B7D76),
        ),
      );

  Widget _fieldLabel(IconData? icon, String text) => Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: Colors.grey.shade600),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      );

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: (_) => setState(() {}), // live preview update
        decoration: _dec(hint),
        validator: required
            ? (v) =>
                (v == null || v.trim().isEmpty) ? 'Required field' : null
            : null,
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF7F5F0),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          borderSide: const BorderSide(color: Color(0xFFD4A373)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
      );
}
