import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/controllers/auth_controller.dart';
import 'package:ira_spa_webapp/controllers/booking_controller.dart';
import 'package:ira_spa_webapp/controllers/service_controller.dart';
import 'package:ira_spa_webapp/models/service_model.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';
import 'package:provider/provider.dart';

class ServicesList extends StatefulWidget {
  const ServicesList({super.key});

  @override
  State<ServicesList> createState() => _ServicesListState();
}

class _ServicesListState extends State<ServicesList> {

   @override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final auth=context.read<AuthController>();
    context.read<ServiceController>().loadServices(auth.businessRef!);
  });
}


  @override
  Widget build(BuildContext context) {
    final servicelist = context.watch<ServiceController>();
    final services = servicelist.services;
    final bookingCounts = servicelist.bookingCounts;
    final bookingcontroller = context.watch<BookingController>();
    final bookings = bookingcontroller.bookings;

    int getCount(ServiceModel service) {
      final dbCount = bookingCounts[service.id];
      if (dbCount != null && dbCount > 0) return dbCount;

      return bookings.where((b) {
        if (b.serviceOptionId != null && b.serviceOptionId == service.id) {
          return true;
        }
        return b.servicename.trim().toLowerCase() ==
            service.serviceName.trim().toLowerCase();
      }).length;
    }

    final counts = services.map((s) => getCount(s)).toList();
    final maxCount = counts.isEmpty
        ? 1
        : counts.reduce((a, b) => a > b ? a : b).clamp(1, 999999);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Card Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Top Services',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          /// Services List
          servicelist.loading
          ? const  Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              : services.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('No service found')),
                    )
          :ListView.builder(
         shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final service = services[index];
                        final count = getCount(service);
                        final progress = maxCount > 0 ? (count / maxCount) : 0.0;


              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Service Name & Amount Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          service.serviceName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                        '\$${service.price.toStringAsFixed(2)}'
                          ,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    /// Custom Progress Bar & Count Row
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              backgroundColor: AppColors.surfaceAlt,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF8C7B68), // Brownish accent matching image
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 24,
                          child: Text(
                            '$count',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}