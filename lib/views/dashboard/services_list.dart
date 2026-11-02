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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicelist = context.watch<ServiceController>();
    final services = servicelist.services;
    final bookingcontroller = context.watch<BookingController>();
    final bookings = bookingcontroller.bookings;

    // Cross-reference: use ServiceController's counts (from REST) and fall
    // back to scanning BookingController's booking list by service name.
    int getCount(ServiceModel service) {
      final dbCount = servicelist.bookingCounts[service.id];
      if (dbCount != null && dbCount > 0) return dbCount;

      final sName = service.serviceName.trim().toLowerCase();
      return bookings.where((b) {
        if (service.id != null && (b.serviceRef == service.id || b.serviceOptionId == service.id)) {
          return true;
        }
        final bName = b.servicename.trim().toLowerCase();
        if (sName.isEmpty || bName.isEmpty) return false;
        return bName == sName || bName.contains(sName) || sName.contains(bName);
      }).length;
    }

    double getRevenue(ServiceModel service) {
      // First try the ServiceController's pre-calculated revenue
      final rev = servicelist.getRevenue(service);
      if (rev > 0) return rev;

      // Fall back: sum booking prices from BookingController
      double total = 0;
      for (final b in bookings) {
        bool matches = false;
        if (b.serviceOptionId != null && b.serviceOptionId == service.id) {
          matches = true;
        } else {
          final sName = service.serviceName.trim().toLowerCase();
          final bName = b.servicename.trim().toLowerCase();
          if (sName.isNotEmpty && bName.isNotEmpty && (sName == bName || sName.contains(bName) || bName.contains(sName))) {
            matches = true;
          }
        }
        if (matches) {
          final rawPrice = b.servicePrice ?? '';
          final sanitized = rawPrice.replaceAll(RegExp(r'[^0-9.]'), '');
          final price = double.tryParse(sanitized);
          total += price != null && price > 0 ? price : service.price;
        }
      }
      return total;
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
                const Expanded(
                  child: Text(
                    'Top Services',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          /// Services List
          servicelist.loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              : services.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('No service found')),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final service = services[index];
                        final count = getCount(service);
                        final revenue = getRevenue(service);
                        final progress =
                            maxCount > 0 ? (count / maxCount) : 0.0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Service Name & Price Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      service.serviceName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '₹${service.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              /// Progress Bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress.clamp(0.0, 1.0),
                                  backgroundColor: AppColors.surfaceAlt,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF8C7B68),
                                  ),
                                  minHeight: 6,
                                ),
                              ),

                              const SizedBox(height: 6),

                              /// Bookings Count & Revenue Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$count ${count == 1 ? "booking" : "bookings"}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Revenue: ₹${revenue.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF66564A),
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
