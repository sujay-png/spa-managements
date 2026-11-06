import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/controllers/auth_controller.dart';
import 'package:ira_spa_webapp/controllers/booking_controller.dart';
import 'package:ira_spa_webapp/controllers/service_controller.dart';
import 'package:ira_spa_webapp/models/service_model.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';
import 'package:provider/provider.dart';

class _ServiceSummary {
  final GroupedServiceModel group;
  final int count;
  final double revenue;

  const _ServiceSummary({
    required this.group,
    required this.count,
    required this.revenue,
  });
}

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
    final groups = servicelist.groupedServices;
    final bookingcontroller = context.watch<BookingController>();
    final bookings = bookingcontroller.bookings;

    String cleanName(String name) {
      return name
          .replaceAll(
              RegExp(r'(\s*[-–—]?\s*\(?\s*\d+\s*min(ute)?s?\s*\)?.*$)',
                  caseSensitive: false),
              '')
          .trim()
          .toLowerCase();
    }

    int getGroupCount(GroupedServiceModel group) {
      final optionIds = group.ids;
      final cleanBase = cleanName(group.serviceName);

      // 1. Sum ServiceController's precalculated counts for all options in this group
      int sumCtrl = 0;
      for (final opt in group.options) {
        if (opt.id != null) {
          sumCtrl += servicelist.getBookingCount(opt.id);
        }
      }
      if (sumCtrl > 0) return sumCtrl;

      // 2. Count from BookingController bookings
      return bookings.where((b) {
        if (b.serviceRef != null && optionIds.contains(b.serviceRef)) return true;
        if (b.serviceOptionId != null && optionIds.contains(b.serviceOptionId)) return true;
        final bName = cleanName(b.servicename);
        if (cleanBase.isEmpty || bName.isEmpty) return false;
        return bName == cleanBase || bName.contains(cleanBase) || cleanBase.contains(bName);
      }).length;
    }

    double getGroupRevenue(GroupedServiceModel group, int count) {
      // 1. Sum ServiceController's precalculated revenue for all options in this group
      double sumCtrlRev = 0;
      for (final opt in group.options) {
        sumCtrlRev += servicelist.getRevenue(opt);
      }
      if (sumCtrlRev > 0) return sumCtrlRev;

      // 2. Scan BookingController bookings
      final optionIds = group.ids;
      final cleanBase = cleanName(group.serviceName);
      double total = 0;
      for (final b in bookings) {
        bool matches = false;
        if (b.serviceRef != null && optionIds.contains(b.serviceRef)) {
          matches = true;
        } else if (b.serviceOptionId != null && optionIds.contains(b.serviceOptionId)) {
          matches = true;
        } else {
          final bName = cleanName(b.servicename);
          if (cleanBase.isNotEmpty &&
              bName.isNotEmpty &&
              (cleanBase == bName || cleanBase.contains(bName) || bName.contains(cleanBase))) {
            matches = true;
          }
        }

        if (matches) {
          final rawPrice = b.servicePrice ?? '';
          final sanitized = rawPrice.replaceAll(RegExp(r'[^0-9.]'), '');
          final price = double.tryParse(sanitized);
          if (price != null && price > 0) {
            total += price;
          } else if (group.options.isNotEmpty) {
            total += group.options.first.price;
          }
        }
      }

      if (total > 0) return total;
      final fallbackPrice = group.options.isNotEmpty ? group.options.first.price : 0.0;
      return fallbackPrice * count;
    }

    final summaryList = groups
        .map((g) {
          final count = getGroupCount(g);
          final revenue = getGroupRevenue(g, count);
          return _ServiceSummary(group: g, count: count, revenue: revenue);
        })
        .where((s) => s.count > 0)
        .toList();

    // Sort by bookings count descending, then by revenue descending
    summaryList.sort((a, b) {
      final cmp = b.count.compareTo(a.count);
      if (cmp != 0) return cmp;
      return b.revenue.compareTo(a.revenue);
    });

    final maxCount = summaryList.isEmpty
        ? 1
        : summaryList.map((e) => e.count).reduce((a, b) => a > b ? a : b).clamp(1, 999999);

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
              : summaryList.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No booked services yet',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: summaryList.length,
                      itemBuilder: (context, index) {
                        final item = summaryList[index];
                        final progress = maxCount > 0 ? (item.count / maxCount) : 0.0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Service Name & Revenue Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.group.serviceName,
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
                                    '₹${item.revenue.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF66564A),
                                      fontSize: 14,
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

                              /// Bookings Count Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item.count} ${item.count == 1 ? "booking" : "bookings"}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Revenue: ₹${item.revenue.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
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
