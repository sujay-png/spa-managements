import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/controllers/auth_controller.dart';
import 'package:ira_spa_webapp/controllers/booking_controller.dart'; // Ensure correct path
import 'package:ira_spa_webapp/models/bookings_model.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';
import 'package:provider/provider.dart';

class UpcommingAppointments extends StatefulWidget {
  const UpcommingAppointments({super.key});

  @override
  State<UpcommingAppointments> createState() => _UpcommingAppointmentsState();
}

class _UpcommingAppointmentsState extends State<UpcommingAppointments> {

  int? _loadedBusinessRef;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      if (auth.businessRef != null) {
        _loadedBusinessRef = auth.businessRef;
        context.read<BookingController>().loadBookings(auth.businessRef!);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthController>();
    if (auth.businessRef != null && auth.businessRef != _loadedBusinessRef) {
      _loadedBusinessRef = auth.businessRef;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<BookingController>().loadBookings(auth.businessRef!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the Booking Controller
    final bookingController = context.watch<BookingController>();
    // Dashboard shows only the next few open appointments.
    final open = bookingController.bookings.where((b) {
      final st = b.statusrequired.toLowerCase();
      return !st.startsWith('complete') && st != 'cancelled';
    }).toList();
    final List<BookingsModel> bookings =
        (open.isNotEmpty ? open : bookingController.bookings).take(5).toList();

    if (bookingController.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Upcoming Appointments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigate or handle View All
                  },
                  child: const Text(
                    'VIEW ALL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Empty state standard check
          if (bookings.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'No upcoming appointments found',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                final booking = bookings[index];
                final String time = booking.timeslot.isNotEmpty ? booking.timeslot : 'N/A';
                final String customerName = booking.customer.trim().isNotEmpty
                    ? booking.customer
                    : (booking.customerRef != null ? 'Customer #${booking.customerRef}' : 'Unknown Customer');
                final String serviceName = booking.servicename.trim().isNotEmpty
                    ? booking.servicename
                    : (booking.serviceRef != null ? 'Service #${booking.serviceRef}' : 'Service');
                final String staffName = booking.therapistname.trim().isNotEmpty
                    ? booking.therapistname
                    : (booking.therapistRef != null ? 'Staff #${booking.therapistRef}' : 'Unassigned');
                final String status = booking.statusrequired.isNotEmpty ? booking.statusrequired : 'pending';

                final bool isConfirmed = status.toLowerCase() == 'confirmed' ||
                    status.toLowerCase() == 'completed';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: LayoutBuilder(
                    builder: (context, rowC) {
                      final isNarrow = rowC.maxWidth < 450;
                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      time,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                _buildStatusBadge(status, isConfirmed),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              customerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    serviceName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  staffName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          // 1. Time
                          SizedBox(
                            width: 130,
                            child: Row(
                              children: [
                                const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    time,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // 2. Client & Service
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  customerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  serviceName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // 3. Staff Name
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 90),
                            child: Text(
                              staffName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // 4. Status Badge
                          _buildStatusBadge(status, isConfirmed),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isConfirmed) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isConfirmed
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isConfirmed ? Colors.green.shade800 : Colors.orange.shade800,
        ),
      ),
    );
  }
}
