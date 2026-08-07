import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/models/client_model.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';
import 'package:ira_spa_webapp/views/service_menu/client_form/client_goal_concern.dart';
import 'package:ira_spa_webapp/views/service_menu/client_form/client_health_history.dart';
import 'package:ira_spa_webapp/views/service_menu/client_form/client_lifestyle.dart';
import 'package:ira_spa_webapp/views/service/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientDetails extends StatefulWidget {
  const ClientDetails({super.key});

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
  bool _loadingCustomers = true;
  List<ClientModel> _customersList = [];
  ClientModel? _selectedCustomer;

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
        _loadingCustomers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCustomers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load customers: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ─── Autofill fields when a customer is selected ──────────────────────────

  void _onCustomerSelected(ClientModel? customer) {
    setState(() {
      _selectedCustomer = customer;
      if (customer != null) {
        _nameController.text = customer.name;
        _phoneController.text = customer.phone;
        _emailController.text = customer.email;
        _locationController.text = customer.location;
        _ageController.text = customer.age;
        _loyaltyCardController.text = customer.loyaltyCardNo;
      } else {
        _nameController.clear();
        _phoneController.clear();
        _emailController.clear();
        _locationController.clear();
        _ageController.clear();
        _loyaltyCardController.clear();
      }
    });
  }

  // ─── Save everything to Supabase ─────────────────────────────────────────

  Future<void> _saveClient() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      final client = ClientModel(
        // Basic details
        date: _dobController.text.trim(),
        time: _timeController.text.trim(),
        name: _nameController.text.trim(),
        age: _ageController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        loyaltyCardNo: _loyaltyCardController.text.trim(),
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
      );

      final saved = await _service.insertClient(client);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Client saved successfully (ID: ${saved.id})'),
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
                    // Date & Time
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: 'Date',
                            icon: Icons.calendar_today_outlined,
                            hint: 'dd/mm/yyyy',
                            controller: _dobController,
                            readOnly: true,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Select a date'
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
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Select a time'
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

                    // Select Customer & Age
                    Row(
                      children: [
                        Expanded(
                          child: _loadingCustomers
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  child: Center(
                                    child: SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                )
                              : DropdownButtonFormField<ClientModel>(
                                  value: _selectedCustomer,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Select Customer',
                                    prefixIcon: const Icon(
                                      Icons.person_search_outlined,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: _customersList.map((customer) {
                                    return DropdownMenuItem<ClientModel>(
                                      value: customer,
                                      child: Text(
                                        '${customer.name}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: _onCustomerSelected,
                                  validator: (value) => value == null
                                      ? 'Please select a customer'
                                      : null,
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
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter age'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Email & Phone
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: 'Email',
                            icon: Icons.mail_outline,
                            hint: 'customer@email.com',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Enter email';
                              }
                              if (!v.contains('@')) return 'Invalid email';
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
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter phone'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // Location
                    _buildInputField(
                      label: 'Location',
                      icon: Icons.location_on_outlined,
                      hint: 'Enter location address',
                      controller: _locationController,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter location'
                          : null,
                    ),
                    const SizedBox(height: 25),

                    // Loyalty Card
                    _buildInputField(
                      label: 'Loyalty Card No',
                      icon: Icons.badge_outlined,
                      hint: 'Enter card number',
                      controller: _loyaltyCardController,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter card number'
                          : null,
                    ),
                    const SizedBox(height: 28),

                    const Divider(),
                    const SizedBox(height: 12),

                    // ── Goals & Concerns ─────────────────────────────────
                    ClientgoalConcern(
                      onChanged: (data) => setState(() => _goalData = data),
                    ),
                    const SizedBox(height: 20),

                    const Divider(),
                    const SizedBox(height: 12),

                    // ── Health History ───────────────────────────────────
                    ClientHealthHistory(
                      onChanged: (data) => setState(() => _healthData = data),
                    ),
                    const SizedBox(height: 20),

                    const Divider(),
                    const SizedBox(height: 12),

                    // ── Lifestyle ────────────────────────────────────────
                    ClientLifestyle(
                      onChanged: (data) =>
                          setState(() => _lifestyleData = data),
                    ),

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
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
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
