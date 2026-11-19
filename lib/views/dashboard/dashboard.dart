import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/components/dashboard_stats.dart';
import 'package:ira_spa_webapp/controllers/auth_controller.dart';
import 'package:ira_spa_webapp/controllers/booking_controller.dart';
import 'package:ira_spa_webapp/controllers/customer_controller.dart';
import 'package:ira_spa_webapp/controllers/payment_controller.dart';
import 'package:ira_spa_webapp/controllers/service_controller.dart';
import 'package:ira_spa_webapp/controllers/staff_controller.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';
import 'package:ira_spa_webapp/utils/payment_utils.dart';
import 'package:ira_spa_webapp/views/dashboard/payments_overview.dart';
import 'package:ira_spa_webapp/views/dashboard/services_list.dart';
import 'package:ira_spa_webapp/views/dashboard/upcomming_appointments.dart';
import 'package:provider/provider.dart';

class Dashboard extends StatefulWidget {
  /// Switches the shell to the Payments tab ("View all").
  final VoidCallback? onOpenPayments;
  const Dashboard({super.key, this.onOpenPayments});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int? _loadedBusinessRef;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthController>();
    if (auth.businessRef != null && auth.businessRef != _loadedBusinessRef) {
      _loadedBusinessRef = auth.businessRef;
      final ref = auth.businessRef!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<ServiceController>().loadServices(ref);
        context.read<BookingController>().loadBookings(ref);
        context.read<CustomerController>().loadcustomer(ref);
        context.read<StaffController>().loadStaff(ref);
        context
            .read<PaymentController>()
            .load(ref, businessName: auth.Bussiness);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final bookingcontroller = context.watch<BookingController>();
    final customercontroller = context.watch<CustomerController>();
    final servicecontroller = context.watch<ServiceController>();
    final paycontroller = context.watch<PaymentController>();
    // Prefer real collections from invoices; fall back to the old
    // booking-based estimate until the payments tables exist.
    final revenueLabel = paycontroller.setupMissing
        ? "₹${bookingcontroller.calculateRevenue(servicecontroller.services).toStringAsFixed(0)}"
        : inr(paycontroller.todayCollection, decimals: false);
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
                      title: paycontroller.setupMissing
                          ? "Total Revenue"
                          : "Collected Today",
                      value: revenueLabel,
                      icon: Icons.currency_rupee,
                    ),
                  ),

                  if (!paycontroller.setupMissing) ...[
                    const SizedBox(width: 20),
                    Expanded(
                      child: DashboardStats(
                        title: "This Month",
                        value: inr(paycontroller.monthCollection,
                            decimals: false),
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ),
                  ],

                  const SizedBox(width: 20),

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

              //=========================Payments: pending + issues==========================
              PaymentsOverview(onViewAll: widget.onOpenPayments),
            ],
          ),
        ),
      ),
    );
  }
}
