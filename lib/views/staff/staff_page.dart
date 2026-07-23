import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/components/staff_card.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';

class StaffPage extends StatelessWidget {
  const StaffPage({super.key});

  @override
  Widget build(BuildContext context) {
    /// Exactly 3 staff entries matching the design in image
    final List<Map<String, dynamic>> staffList = [
      {
        "initials": "DSJ",
        "name": "Dr. Sarah Johnson",
        "designation": "Senior Therapist",
        "specialization": "Massage Therapy",
        "email": "sarah.j@serenity.spa",
        "phone": "+1 234 567 8910",
        "rating": "4.9",
        "appointments": "245",
        "status": "Available",
        "statusBgColor": const Color(0xFFE2F3EC),
        "statusTextColor": const Color(0xFF108A00),
      },
      {
        "initials": "LC",
        "name": "Lisa Chen",
        "designation": "Esthetician",
        "specialization": "Skin Care",
        "email": "lisa.c@serenity.spa",
        "phone": "+1 234 567 8911",
        "rating": "4.8",
        "appointments": "189",
        "status": "Available",
        "statusBgColor": const Color(0xFFE2F3EC),
        "statusTextColor": const Color(0xFF108A00),
      },
      {
        "initials": "AP",
        "name": "Amy Parker",
        "designation": "Wellness Coach",
        "specialization": "Aromatherapy",
        "email": "amy.p@serenity.spa",
        "phone": "+1 234 567 8912",
        "rating": "4.7",
        "appointments": "156",
        "status": "Busy",
        "statusBgColor": const Color(0xFFFFF0E0),
        "statusTextColor": const Color(0xFFD4A24C),
      },
    ];

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
                    onPressed: () {},
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

            /// Grid View Layout for 3 cards
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: staffList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.99,
              ),
              itemBuilder: (context, index) {
                final staff = staffList[index];
                return StaffCard(
                  initials: staff["initials"],
                  name: staff["name"],
                  designation: staff["designation"],
                  specialization: staff["specialization"],
                  email: staff["email"],
                  phone: staff["phone"],
                  rating: staff["rating"],
                  appointments: staff["appointments"],
                  status: staff["status"],
                  statusBgColor: staff["statusBgColor"],
                  statusTextColor: staff["statusTextColor"],
                  onSchedulePressed: () {},
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}