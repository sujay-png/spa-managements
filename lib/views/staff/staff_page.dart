import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/components/staff_card.dart';
import 'package:ira_spa_webapp/controllers/auth_controller.dart';
import 'package:ira_spa_webapp/controllers/staff_controller.dart';
import 'package:ira_spa_webapp/models/staff_model.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'add_staff_dialog.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  void _openAddStaffDialog() {
    showDialog(context: context, builder: (context) => const AddStaffDialog());
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();

      if (auth.businessRef != null) {
        context.read<StaffController>().loadBookingCounts(auth.businessRef!);
      } else {
        debugPrint("Business Ref is null");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<StaffController>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Staff Members",
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Manage your team members, schedules, and performance",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                /// Add Staff Button
                SizedBox(
                  width: 165,
                  child: ElevatedButton.icon(
                    onPressed: _openAddStaffDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8C7A6B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      'Add Staff',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: 15,
                        color: AppColors.surface,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// Grid View Layout
            staff.loading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: staff.staffs.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.2,
                        ),
                    itemBuilder: (context, index) {
                      final staffMember = staff.staffs[index];

                      return StaffCard(
                        initials: _initials(staffMember.name),
                        name: staffMember.name,
                        designation: staffMember.designation,
                        specialization: staffMember.specialization,
                        email: staffMember.email,
                        phone: staffMember.phno,
                        statusBgColor: staffMember.jobStatus == "Busy"
                            ? Colors.red.shade100
                            : Colors.green.shade100,

                        statusTextColor: staffMember.jobStatus == "Busy"
                            ? Colors.red
                            : Colors.green,

                     
                    
                      appointments: staff.getBookingCount(staffMember.name).toString(),
                        status: staffMember.jobStatus,

                        onEdit: () {
                          showDialog(
                            context: context,
                            builder: (context) =>
                                AddStaffDialog(staff: staffMember),
                          );
                        },
                        onDelete: () {
                          _deleteStaff(staffMember);
                        },
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  //=============================Helper function=================================
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  //==========================Delete =============================
  Future<void> _deleteStaff(StaffModel staffMember) async {
    if (staffMember.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Staff"),
        content: const Text(
          "Are you sure you want to delete this staff member?",
        ),
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
      await context.read<StaffController>().deletestaff(staffMember.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Staff deleted successfully")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to delete: $e")));
    }
  }
}
