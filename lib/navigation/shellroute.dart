import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/controllers/auth_controller.dart';
import 'package:ira_spa_webapp/controllers/booking_controller.dart';
import 'package:ira_spa_webapp/controllers/customer_controller.dart';
import 'package:ira_spa_webapp/controllers/payment_controller.dart';
import 'package:ira_spa_webapp/controllers/service_controller.dart';
import 'package:ira_spa_webapp/controllers/staff_controller.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';
import 'package:ira_spa_webapp/views/bookings/booking_page.dart';
import 'package:ira_spa_webapp/views/customer/customer_page.dart';
import 'package:ira_spa_webapp/views/dashboard/dashboard.dart';
import 'package:ira_spa_webapp/views/payments/payments_page.dart';
import 'package:ira_spa_webapp/views/services/screen.dart';
import 'package:ira_spa_webapp/views/services/selection_pannel.dart';

import 'package:ira_spa_webapp/views/staff/staff_page.dart';
import 'package:provider/provider.dart';

class Shellroute extends StatefulWidget {
  const Shellroute({super.key});

  @override
  State<Shellroute> createState() => _ShellrouteState();
}

class _ShellrouteState extends State<Shellroute> {
  int _index = 0;
  final double _mobileBreakpoint = 700;
  final double _desktopBreakpoint = 1050;
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

  // Index order must match the sidebar + bottom navigation below.
  List<Widget> get _pages => [
        Dashboard(onOpenPayments: () => setState(() => _index = 2)),
        const BookingPage(),
        const PaymentsPage(),
        const CustomerPage(),
        const ServiceMenuView(),
        const StaffPage(),
      ];

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final displayName = authController.userName ?? '';
    final businessname = authController.Bussiness ?? '';
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobileLayout = constraints.maxWidth < _mobileBreakpoint;

          if (isMobileLayout) {
            return _pages[_index];
          }

          final isTabletLayout = constraints.maxWidth < _desktopBreakpoint;

          return Row(
            children: [
              if (isTabletLayout)
                _buildSlimRail(displayName)
              else
                _buildFullSidebar(context, businessname, displayName),
              const VerticalDivider(width: 1),
              Expanded(child: _pages[_index]),
            ],
          );
        },
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < _mobileBreakpoint
          ? NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.secondary.withValues(alpha: 0.2),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_today_outlined),
                  label: 'Bookings',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  label: 'Payments',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  label: 'Customers',
                ),
                NavigationDestination(
                  icon: Icon(Icons.content_cut),
                  label: 'Services',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  label: 'Staff',
                ),
              ],
            )
          : null,
    );
  }

  /// Compact icon-only rail for tablets (700px - 1050px)
  Widget _buildSlimRail(String displayName) {
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 102, 86, 70),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.content_cut,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 8),

          _railItem(Icons.dashboard_outlined, "Dashboard", 0),
          _railItem(Icons.calendar_today_outlined, "Bookings", 1),
          _railItem(Icons.account_balance_wallet_outlined, "Payments", 2),
          _railItem(Icons.people_outline, "Customers", 3),
          _railItem(Icons.content_cut, "Services", 4),
          _railItem(Icons.person_outline, "Staff", 5),

          const Spacer(),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          Tooltip(
            message: displayName,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color.fromARGB(255, 102, 86, 70),
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : "U",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: 'Logout',
            child: IconButton(
              iconSize: 20,
              onPressed: () => context.read<AuthController>().signOut(),
              icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _railItem(IconData icon, String title, int index) {
    final selected = _index == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: title,
        preferBelow: false,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _index = index),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: selected
                  ? const Color.fromARGB(255, 102, 86, 70)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  /// Full-width sidebar for desktop (>= 1050px)
  Widget _buildFullSidebar(
    BuildContext context,
    String businessname,
    String displayName,
  ) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),

          /// Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 102, 86, 70),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.content_cut,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        businessname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        "MANAGEMENT",
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "MAIN MENU",
                style: TextStyle(fontSize: 11, letterSpacing: 2),
              ),
            ),
          ),

          const SizedBox(height: 12),

          _menu(Icons.dashboard_outlined, "Dashboard", 0),
          _menu(Icons.calendar_today_outlined, "Bookings", 1),
          _menu(Icons.account_balance_wallet_outlined, "Payments", 2),
          _menu(Icons.people_outline, "Customers", 3),
          _menu(Icons.content_cut, "Services", 4),
          _menu(Icons.person_outline, "Staff", 5),

          const Spacer(),

          const Divider(color: AppColors.border),

          const SizedBox(height: 10),

          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: CircleAvatar(
              backgroundColor: const Color.fromARGB(255, 102, 86, 70),
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : "U",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Tooltip(
              message: 'Logout',
              child: IconButton(
                onPressed: () => context.read<AuthController>().signOut(),
                icon: const Icon(Icons.logout),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _menu(IconData icon, String title, int index) {
    final selected = _index == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            _index = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? const Color.fromARGB(255, 102, 86, 70)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
              const SizedBox(width: 15),
              Text(
                title,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //
}
