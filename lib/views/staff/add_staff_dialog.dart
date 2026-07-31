import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/components/staff_card.dart';
import 'package:ira_spa_webapp/controllers/auth_controller.dart';
import 'package:ira_spa_webapp/controllers/staff_controller.dart';
import 'package:ira_spa_webapp/models/staff_model.dart';
import 'package:provider/provider.dart';

class AddStaffDialog extends StatefulWidget {
    final StaffModel? staff; 
  const AddStaffDialog({super.key, this.staff});

  @override
  State<AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends State<AddStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String status = "Available";
    late final bool isEdit = widget.staff != null;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController designationController = TextEditingController();
  final TextEditingController specializationController =
      TextEditingController();
  @override

  void initState() {
    super.initState();

    // Pre-fill fields when editing
    if (widget.staff != null) {
      nameController.text = widget.staff!.name;
      emailController.text = widget.staff!.email;
      phoneController.text = widget.staff!.phno;
      designationController.text = widget.staff!.designation;
      specializationController.text = widget.staff!.specialization;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();

      if (auth.businessRef != null) {
        context.read<StaffController>().loadStaff(auth.businessRef!);
      } else {
        debugPrint("Business Ref is null");
      }
    });
  }
  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    designationController.dispose();
    specializationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color headerColor = Color(0xFF8C7A6B);
    const Color fieldBgColor = Color(0xFFF8FAFC);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 600,
        height: 620,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ================= HEADER ================= //
            Container(
              height: 60,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const BoxDecoration(
                color: headerColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                 Text(
  isEdit ? "Edit Staff Member" : "Add New Staff Member",
  style: const TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  ),
),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // ================= BODY ================= //
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full Name
                        const Text(
                          "Full Name",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: nameController,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Please enter a full name";
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: "Enter full name...",
                            filled: true,
                            fillColor: fieldBgColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Email & Phone Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Email",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return "Please enter an email";
                                      }
                                      final RegExp emailRegExp = RegExp(
                                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                                      );
                                      if (!emailRegExp.hasMatch(value.trim())) {
                                        return "Enter a valid email address";
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      hintText: "example@spa.com",
                                      filled: true,
                                      fillColor: fieldBgColor,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Phone Number",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: phoneController,
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return "Please enter a phone number";
                                      }
                                      if (value.trim().length < 7) {
                                        return "Enter a valid phone number";
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      hintText: "+1 234 567 890",
                                      filled: true,
                                      fillColor: fieldBgColor,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Designation & Specialization Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Designation",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: designationController,
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return "Please enter designation";
                                      }

                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      hintText: "",
                                      filled: true,
                                      fillColor: fieldBgColor,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Specialization",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: specializationController,
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return "Please enter Specialization";
                                      }

                                      return null;
                                    },
                                    decoration: InputDecoration(
                                      hintText: "",
                                      filled: true,
                                      fillColor: fieldBgColor,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Initial Status Selection
                        const Text(
                          "Initial Status",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: status,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: fieldBgColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: "Available",
                              child: Text("Available"),
                            ),
                            DropdownMenuItem(
                              value: "Busy",
                              child: Text("Busy"),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              status = value!;
                            });
                          },
                        ),

                        const SizedBox(height: 32),

                        // Actions Row
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text("Cancel"),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saving
                                    ? null
                                    : () {
                                        print("Save Staff button clicked");
                                        _save();
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: headerColor,
                                  minimumSize: const Size(double.infinity, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "Save Staff",
                                  style: TextStyle(color: Colors.white),
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
            ),
          ],
        ),
      ),
    );
  }

  //================================Save logic=================================
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
    if (isEdit) {
      final updatedStaff = StaffModel(
        id: widget.staff!.id,
        businessRef: widget.staff!.businessRef,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phno: phoneController.text.trim(),
        designation: designationController.text.trim(),
        specialization: specializationController.text.trim(),
        jobStatus: status
      );

      await context.read<StaffController>().updatestaff(updatedStaff);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff updated successfully')),
        );
      }
    } else {
      await context.read<StaffController>().addStaff(
        StaffModel(
          businessRef: auth.businessRef!,
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          phno: phoneController.text.trim(),
          designation: designationController.text.trim(),
        jobStatus: 'Available',
          specialization: specializationController.text.trim(),
        ),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff added successfully')),
        );
      }
    }
  } catch (e, stack) {
    print(e);
    print(stack);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  } finally {
    if (mounted) {
      setState(() => _saving = false);
    }
  }
}
}
