import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/components/dashboard_stats.dart';
import 'package:ira_spa_webapp/controllers/auth_controller.dart';
import 'package:ira_spa_webapp/controllers/booking_controller.dart';
import 'package:ira_spa_webapp/controllers/customer_controller.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';
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
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 15,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $displayName',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 28,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Heres whats happening with your spa today',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              //=========================Dashboard stats======================================
              Row(
                children: [
                 

                  Expanded(
                    child: DashboardStats(
                      title: "Today's Bookings",
                      value: "${bookingcontroller.totalBookings}",
                    
                      icon: Icons.calendar_today_outlined,
                    ),
                  ),

                  const SizedBox(width: 20),

                  Expanded(
                    child: DashboardStats(
                      title: "Total Customers",
                      value: "${customercontroller.totalcustomer}",
                    
                      icon: Icons.groups_outlined,
                    ),
                  ),

                  const SizedBox(width: 20),

                  Expanded(
                    child: DashboardStats(
                      title: "Avg. Wait Time",
                      value: "${bookingcontroller.waitingBookings}",
                    
                      icon: Icons.schedule_outlined,
                    ),
                  ),
                ],
              ),

              //========================================List Tille==============================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 15,
                children: [
                  Expanded(child: UpcommingAppointments()),
                  Expanded(child: ServicesList()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
