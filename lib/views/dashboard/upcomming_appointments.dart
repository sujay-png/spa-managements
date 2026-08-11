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

  @override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final auth=context.read<AuthController>();
    context.read<BookingController>().loadBookings(auth.businessRef!);
  });
}

  @override
  Widget build(BuildContext context) {
    // Watch the Booking Controller
    final bookingController = context.watch<BookingController>();
    final List<BookingsModel> bookings = bookingController.bookings;

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
            SingleChildScrollView(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  final String time = booking.timeslot?.toString() ?? 'N/A';
                  final String customerName = booking.customer?.toString() ?? 'Unknown Customer';
                  final String serviceName = booking.servicename?.toString() ?? 'Service';
                  final String staffName = booking.therapistname?.toString() ?? 'Unassigned';
                  final String status = booking.statusrequired?.toString() ?? 'pending';
              
                  final bool isConfirmed = status.toLowerCase() == 'confirmed' ||
                      status.toLowerCase() == 'completed';
              
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.border,
                          width: index == bookings.length - 1 ? 0 : 1,
                        ),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
              
                      // 1. Time
                      leading: SizedBox(
                        width: 100,
                        child: Center(
                          child: Text(
                            time,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
              
                      // 2. Client Name
                      title: Text(
                        customerName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
              
                      // 3. Service Name
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          serviceName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
              
                      // 4. Staff Name + Booking Status
                      trailing: SizedBox(
                        width: 170,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: Text(
                                staffName,
                                textAlign: TextAlign.end,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isConfirmed
                                    ? Colors.green.withOpacity(0.12)
                                    : Colors.orange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isConfirmed ? Colors.green : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}