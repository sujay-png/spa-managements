import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/controllers/auth_controller.dart';
import 'package:ira_spa_webapp/controllers/booking_controller.dart';
import 'package:ira_spa_webapp/models/client_model.dart';
import 'package:ira_spa_webapp/models/spa_service.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';
import 'package:ira_spa_webapp/views/service_menu/client_form/client_goal_concern.dart';
import 'package:ira_spa_webapp/views/service_menu/client_form/client_health_history.dart';
import 'package:ira_spa_webapp/views/service_menu/client_form/client_lifestyle.dart';
import 'package:ira_spa_webapp/views/service/database_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientDetails extends StatefulWidget {
  final Map<SpaService, ServiceOption> selectedServices;
  const ClientDetails({super.key,
   required this.selectedServices,
  });

  @override
  State<ClientDetails> createState() => _ClientDetailsState();
}

class _ClientDetailsState extends State<ClientDetails> {
  // ─── Form ─────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  final _dobController = TextEditingController();
  final _timeController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _loyaltyCardController = TextEditingController();
  final _service = DatabaseService();
  DateTime? _selectedDate;
  bool _isSaving = false;
  List<ClientModel> _customersList = [];
  ClientModel? client;
  String _paymentStatus = 'Unpaid'; // 'Unpaid' or 'Paid'
  String _paymentMethod = 'UPI / QR Code'; // 'Cash', 'UPI / QR Code', 'Card'

  // ─── Sub-form data (updated via callbacks) ────────────────────────────────
  GoalConcernData _goalData = const GoalConcernData();
  HealthHistoryData _healthData = const HealthHistoryData();
  LifestyleData _lifestyleData = const LifestyleData();

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String _formatDate(DateTime date) =>
      "${date.day.toString().padLeft(2, '0')}/"
      "${date.month.toString().padLeft(2, '0')}/"
      "${date.year}";

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _dobController.dispose();
    _timeController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _loyaltyCardController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    try {
      final data = await _service.getAllCustomers();
      if (!mounted) return;
      setState(() {
        _customersList = data;
      });
    } catch (_) {
      // Background load for autofill suggestions; ignore if fails
    }
  }

  // ─── Save everything to Supabase ─────────────────────────────────────────

  Future<void> _saveClient() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields (Date, Time, Customer, Phone).'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final auth = context.read<AuthController>();

    if (auth.businessRef == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Business reference not found.")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final totalAmount = widget.selectedServices.values.fold(
        0.0,
        (sum, o) => sum + o.price.toDouble(),
      );
      final totalMinutes = widget.selectedServices.values.fold(
        0,
        (sum, o) => sum + o.duration,
      );
      final isPaid = _paymentStatus.toLowerCase() == 'paid';
      final serviceTitles = widget.selectedServices.keys.map((s) => s.title).join(', ');
      final serviceDurations = widget.selectedServices.values.map((o) => '${o.duration} min').join(', ');

      DateTime? slotDateTime = _selectedDate;
      if (slotDateTime != null && _timeController.text.isNotEmpty) {
        try {
          final timeStr = _timeController.text.trim();
          final parts = timeStr.split(RegExp(r'[:\s]'));
          if (parts.length >= 2) {
            int h = int.parse(parts[0]);
            int m = int.parse(parts[1]);
            final isPm = timeStr.toUpperCase().contains('PM');
            final isAm = timeStr.toUpperCase().contains('AM');
            if (isPm && h < 12) h += 12;
            if (isAm && h == 12) h = 0;
            slotDateTime = DateTime(slotDateTime.year, slotDateTime.month, slotDateTime.day, h, m);
          }
        } catch (_) {}
      }

      final client = ClientModel(
        // Basic details
        businessRef: auth.businessRef!,
        date: _dobController.text.trim(),
        time: _timeController.text.trim(),
        name: _nameController.text.trim(),
        age: _ageController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        loyaltyCardNo: _loyaltyCardController.text.trim(),
        appointmentDatetime: slotDateTime?.toIso8601String(),
        // Goals & Concerns
        massageGoal: _goalData.massageGoals.join(', '),
        bodyFocusArea: _goalData.bodyFocusAreas.join(', '),
        // Health History
        skinAllergy: _healthData.skinAllergy,
        isPregnant: _healthData.isPregnant,
        cardiacProblems: _healthData.cardiacProblems,
        recentSurgery: _healthData.recentSurgery,
        // Lifestyle
        lifestyleType: _lifestyleData.lifestyleType,
        sessionFrequency: _lifestyleData.sessionFrequency,
        serviceName: serviceTitles.isNotEmpty ? serviceTitles : null,
        serviceTime: serviceDurations.isNotEmpty ? serviceDurations : null,
      );

      final saved = await _service.insertClient(
        client,
        rate: totalAmount,
        totalAmount: totalAmount,
        paidAmount: isPaid ? totalAmount : 0.0,
        paymentStatus: isPaid ? 'Paid' : 'unpaid',
        paymentMethod: isPaid ? _paymentMethod : null,
        duration: totalMinutes,
        bookingStatus: 'Confirmed',
        appointmentSlot: slotDateTime?.toIso8601String(),
      );

      if (mounted) {
        try {
          context.read<BookingController>().loadBookings(auth.businessRef!);
        } catch (_) {}
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Client saved successfully! Total: ₹${totalAmount.toStringAsFixed(0)} (${isPaid ? "Paid via $_paymentMethod" : "Unpaid"})',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Database error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Dialog Header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              color: AppColors.textSecondary,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_add_outlined,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Client Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ],
            ),
          ),

          // ── Scrollable Form ──────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date & Time (Both Required)
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: 'Date',
                            icon: Icons.calendar_today_outlined,
                            hint: 'dd/mm/yyyy',
                            controller: _dobController,
                            readOnly: true,
                            isRequired: true,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please select a date'
                                : null,
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate ?? now,
                                firstDate: DateTime(1900),
                                lastDate: now,
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedDate = picked;
                                  _dobController.text = _formatDate(picked);
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildInputField(
                            label: 'Time',
                            icon: Icons.access_time,
                            hint: '00:00 AM/PM',
                            controller: _timeController,
                            readOnly: true,
                            isRequired: true,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please select a time'
                                : null,
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  _timeController.text = picked.format(context);
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Customer Name (Required) & Age (Optional)
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: 'Customer Name',
                            icon: Icons.person_outline,
                            hint: 'Enter customer name',
                            controller: _nameController,
                            isRequired: true,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please enter customer name'
                                : null,
                            onChanged: (val) {
                              if (val.trim().isEmpty) return;
                              final match = _customersList
                                  .cast<ClientModel?>()
                                  .firstWhere(
                                    (c) =>
                                        c != null &&
                                        c.name.trim().toLowerCase() ==
                                            val.trim().toLowerCase(),
                                    orElse: () => null,
                                  );
                              if (match != null) {
                                if (_phoneController.text.isEmpty) {
                                  _phoneController.text = match.phone;
                                }
                                if (_emailController.text.isEmpty) {
                                  _emailController.text = match.email;
                                }
                                if (_ageController.text.isEmpty) {
                                  _ageController.text = match.age;
                                }
                                if (_locationController.text.isEmpty) {
                                  _locationController.text = match.location;
                                }
                                if (_loyaltyCardController.text.isEmpty) {
                                  _loyaltyCardController.text =
                                      match.loyaltyCardNo;
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildInputField(
                            label: 'Age',
                            icon: Icons.cake_outlined,
                            hint: 'Enter age',
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            isRequired: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Email (Optional) & Phone (Required)
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: 'Email',
                            icon: Icons.mail_outline,
                            hint: 'customer@email.com',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            isRequired: false,
                            validator: (v) {
                              if (v != null && v.trim().isNotEmpty) {
                                if (!RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(v.trim())) {
                                  return 'Enter a valid email address';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildInputField(
                            label: 'Phone',
                            icon: Icons.phone_outlined,
                            hint: '+1 234 567 8900',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            isRequired: true,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please enter phone'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Location (Optional)
                    _buildInputField(
                      label: 'Location',
                      icon: Icons.location_on_outlined,
                      hint: 'Enter location address',
                      controller: _locationController,
                      isRequired: false,
                    ),
                    const SizedBox(height: 25),

                    // Loyalty Card (Optional)
                    _buildInputField(
                      label: 'Loyalty Card No',
                      icon: Icons.badge_outlined,
                      hint: 'Enter card number',
                      controller: _loyaltyCardController,
                      isRequired: false,
                    ),
                    const SizedBox(height: 28),

                    const Divider(),
                    const SizedBox(height: 12),

                    // ── Goals & Concerns (Optional) ──────────────────────
                    ClientgoalConcern(
                      initialData: _goalData,
                      onChanged: (data) => setState(() => _goalData = data),
                    ),
                    const SizedBox(height: 20),

                    const Divider(),
                    const SizedBox(height: 12),

                    // ── Health History (Optional) ────────────────────────
                    ClientHealthHistory(
                      initialData: _healthData,
                      onChanged: (data) => setState(() => _healthData = data),
                    ),
                    const SizedBox(height: 20),

                    const Divider(),
                    const SizedBox(height: 12),

                    // ── Lifestyle (Optional) ─────────────────────────────
                    ClientLifestyle(
                      initialData: _lifestyleData,
                      onChanged: (data) =>
                          setState(() => _lifestyleData = data),
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // ── Order Summary & Payment Details ───────────────────
                    _buildPaymentSection(),

                    const SizedBox(height: 35),

                    // ── Save Button ──────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveClient,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.textPrimary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.purple.shade200,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Client',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    final totalPrice = widget.selectedServices.values.fold(
      0.0,
      (sum, o) => sum + o.price.toDouble(),
    );
    final totalMinutes = widget.selectedServices.values.fold(
      0,
      (sum, o) => sum + o.duration,
    );
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    final durationStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

    final paymentModes = ['UPI / QR Code', 'Cash', 'Card'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEADBCE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.receipt_long_outlined, size: 20, color: Color(0xFF8B6B4D)),
              SizedBox(width: 8),
              Text(
                'Order Summary & Payment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2E3E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.selectedServices.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${e.key.title} (${e.value.duration} min)',
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF55596E),
                      ),
                    ),
                  ),
                  Text(
                    '₹${e.value.price}',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2C2E3E),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFEADBCE)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Duration: $durationStr',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B6E82),
                ),
              ),
              Text(
                'Total: ₹${totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B5A2B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Payment Status Radio / Toggle
          const Text(
            'Payment Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2E3E),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildChoiceChip(
                label: 'Unpaid',
                isSelected: _paymentStatus == 'Unpaid',
                activeColor: Colors.red.shade700,
                onSelected: () => setState(() => _paymentStatus = 'Unpaid'),
              ),
              const SizedBox(width: 12),
              _buildChoiceChip(
                label: 'Paid',
                isSelected: _paymentStatus == 'Paid',
                activeColor: Colors.green.shade700,
                onSelected: () => setState(() => _paymentStatus = 'Paid'),
              ),
            ],
          ),

          // Payment Method Selector
          if (_paymentStatus == 'Paid') ...[
            const SizedBox(height: 14),
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C2E3E),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: paymentModes.map((mode) {
                final isSelected = _paymentMethod == mode;
                return ChoiceChip(
                  label: Text(
                    mode,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white : const Color(0xFF333333),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF8B5A2B),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF8B5A2B)
                          : const Color(0xFFCBD0D9),
                    ),
                  ),
                  onSelected: (_) => setState(() => _paymentMethod = mode),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onSelected,
  }) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFCBD0D9),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16,
              color: isSelected ? activeColor : const Color(0xFF8C8F9F),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? activeColor : const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Reusable Input Field ─────────────────────────────────────────────────

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required String hint,
    TextEditingController? controller,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool isRequired = false,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF4A4A4A),
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          keyboardType: keyboardType,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
            filled: true,
            fillColor: const Color(0xFFF5F5F7),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEBEBF0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.purple, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
