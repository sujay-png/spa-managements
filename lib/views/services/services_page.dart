import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/components/service_card.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';

class ServicePage extends StatelessWidget {
  const ServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Exact colors matching your Figma design for each service
    final List<Map<String, dynamic>> services = [
      {
        "title": "Swedish Massage",
        "category": "Massage Therapy",
        "categoryBgColor": const Color(0xFFF3ECE5),
        "categoryTextColor": const Color(0xFF796D64),
        "duration": "60 min",
        "price": "\$120",
        "bookings": "45",
        "revenue": "\$5,400",
        "badge": "active",
        "badgeColor": const Color(0xFFE2F3EC),
        "badgeTextColor": const Color(0xFF108A00),
        "priceTextColor": const Color(0xFF9D785A),
      },
      {
        "title": "Deep Tissue Massage",
        "category": "Massage Therapy",
        "categoryBgColor": const Color(0xFFF3ECE5),
        "categoryTextColor": const Color(0xFF796D64),
        "duration": "90 min",
        "price": "\$140",
        "bookings": "32",
        "revenue": "\$4,480",
        "badge": "active",
        "badgeColor": const Color(0xFFE2F3EC),
        "badgeTextColor": const Color(0xFF108A00),
        "priceTextColor": const Color(0xFF9D785A),
      },
      {
        "title": "Facial Treatment",
        "category": "Skin Care",
        "categoryBgColor": const Color(0xFFFBF0EA),
        "categoryTextColor": const Color(0xFFC0826D),
        "duration": "60 min",
        "price": "\$95",
        "bookings": "38",
        "revenue": "\$3,610",
        "badge": "active",
        "badgeColor": const Color(0xFFE2F3EC),
        "badgeTextColor": const Color(0xFF108A00),
        "priceTextColor": const Color(0xFF9D785A),
      },
      {
        "title": "Hot Stone Therapy",
        "category": "Massage Therapy",
        "categoryBgColor": const Color(0xFFF3ECE5),
        "categoryTextColor": const Color(0xFF796D64),
        "duration": "90 min",
        "price": "\$150",
        "bookings": "28",
        "revenue": "\$4,200",
        "badge": "active",
        "badgeColor": const Color(0xFFE2F3EC),
        "badgeTextColor": const Color(0xFF108A00),
        "priceTextColor": const Color(0xFF9D785A),
      },
      {
        "title": "Aromatherapy",
        "category": "Wellness",
        "categoryBgColor": const Color(0xFFE2F3EC),
        "categoryTextColor": const Color(0xFF108A00),
        "duration": "60 min",
        "price": "\$110",
        "bookings": "35",
        "revenue": "\$3,850",
        "badge": "active",
        "badgeColor": const Color(0xFFE2F3EC),
        "badgeTextColor": const Color(0xFF108A00),
        "priceTextColor": const Color(0xFF9D785A),
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
                        "Services",
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Manage your spa services and treatments",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
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
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: services.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.45,
              ),
              itemBuilder: (context, index) {
                final service = services[index];
                return ServiceCard(
                  title: service["title"],
                  category: service["category"],
                  categoryBgColor: service["categoryBgColor"],
                  categoryTextColor: service["categoryTextColor"],
                  duration: service["duration"],
                  price: service["price"],
                  bookings: service["bookings"],
                  revenue: service["revenue"],
                  badge: service["badge"],
                  badgeColor: service["badgeColor"],
                  badgeTextColor: service["badgeTextColor"],
                  priceTextColor: service["priceTextColor"],
                  onOptionsPressed: () {},
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
