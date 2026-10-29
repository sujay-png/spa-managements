import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/components/dashboard_stats.dart';
import 'package:ira_spa_webapp/controllers/auth_controller.dart';
import 'package:ira_spa_webapp/controllers/booking_controller.dart';
import 'package:ira_spa_webapp/controllers/customer_controller.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';
import 'package:ira_spa_webapp/theme/responsive.dart';
import 'package:ira_spa_webapp/views/dashboard/services_list.dart';
import 'package:ira_spa_webapp/views/dashboard/upcomming_appointments.dart';
import 'package:provider/provider.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final bookingcontroller = context.watch<BookingController>();
    final customercontroller = context.watch<CustomerController>();
    final displayName = authController.userName ?? '';
    final isTabletOrMobile = !context.isDesktop;

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.responsive(mobile: 12.0, tablet: 16.0, desktop: 20.0)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Welcome back, $displayName',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: context.responsive(mobile: 20.0, tablet: 24.0, desktop: 28.0),
                letterSpacing: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Here\'s what\'s happening with your spa today',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Stats Row — stacks on mobile, row on tablet+
            context.isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DashboardStats(
                        title: "Today's Bookings",
                        value: '${bookingcontroller.totalBookings}',
                        icon: Icons.calendar_today_outlined,
                      ),
                      const SizedBox(height: 12),
                      DashboardStats(
                        title: 'Total Customers',
                        value: '${customercontroller.totalcustomer}',
                        icon: Icons.groups_outlined,
                      ),
                      const SizedBox(height: 12),
                      DashboardStats(
                        title: 'Avg. Wait Time',
                        value: '${bookingcontroller.waitingBookings}',
                        icon: Icons.schedule_outlined,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: DashboardStats(
                          title: "Today's Bookings",
                          value: '${bookingcontroller.totalBookings}',
                          icon: Icons.calendar_today_outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardStats(
                          title: 'Total Customers',
                          value: '${customercontroller.totalcustomer}',
                          icon: Icons.groups_outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardStats(
                          title: 'Avg. Wait Time',
                          value: '${bookingcontroller.waitingBookings}',
                          icon: Icons.schedule_outlined,
                        ),
                      ),
                    ],
                  ),

            const SizedBox(height: 16),

            // Bottom row — stacks on tablet/mobile
            isTabletOrMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      UpcommingAppointments(),
                      const SizedBox(height: 16),
                      ServicesList(),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(child: UpcommingAppointments()),
                      const SizedBox(width: 16),
                      const Expanded(child: ServicesList()),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
