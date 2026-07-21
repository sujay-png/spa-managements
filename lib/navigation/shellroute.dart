import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';
import 'package:ira_spa_webapp/views/dashboard/dashboard.dart';

class Shellroute extends StatefulWidget {
  const Shellroute({super.key});

  @override
  State<Shellroute> createState() => _ShellrouteState();
}

class _ShellrouteState extends State<Shellroute> {
  int _index = 0;
  final double _mobileBreakpoint = 600;
  bool _isexpanded = false;
  static const _pages = [
    Dashboard(),
    // TenantsView(),
    // FeeCollectionView(),
    // MaintenanceView(),
    // NoticeBoardView(),
  ];
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            
           
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: (){

            }
          ),
          // context.read<AuthController>().signOut(),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobileLayout = constraints.maxWidth < _mobileBreakpoint;

          if (isMobileLayout) {
            return _pages[_index];
          }

          return Row(
            children: [
            Container(
  width: 280,
  decoration: BoxDecoration(
    color: AppColors.surface,
    border: Border(
      right: BorderSide(color: AppColors.border),
    ),
  ),
  child: Column(
    children: [
      const SizedBox(height: 30),

      /// Logo
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.content_cut, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Serenity Spa",
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  "MANAGEMENT",
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      const SizedBox(height: 30),

      /// Search
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: TextField(
          decoration: InputDecoration(
            hintText: "Search...",
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: AppColors.surfaceAlt,
          ),
        ),
      ),

      const SizedBox(height: 30),

      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 25),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "MAIN MENU",
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
        ),
      ),

      const SizedBox(height: 15),

      _menu(Icons.dashboard_outlined, "Dashboard", 0),
      _menu(Icons.calendar_today_outlined, "Bookings", 1),
      _menu(Icons.people_outline, "Customers", 2),
      _menu(Icons.content_cut, "Services", 3),
      _menu(Icons.person_outline, "Staff", 4),
      _menu(Icons.menu, "Service Menu", 5),

      const Spacer(),

      Divider(color: AppColors.border),

      _menu(Icons.settings_outlined, "Settings", 6),

      const SizedBox(height: 20),

      ListTile(
        leading: const CircleAvatar(
          child: Text("SJ"),
        ),
        title: const Text("Sarah Johnson"),
        subtitle: const Text("Manager"),
        trailing: const Icon(Icons.notifications_none),
      ),

      const SizedBox(height: 20),
    ],
  ),
),
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
                  icon: Icon(Icons.people_outline),
                  label: 'Booking',
                ),
                NavigationDestination(
                  icon: Icon(Icons.payments_outlined),
                  label: 'Customer',
                ),
                NavigationDestination(
                  icon: Icon(Icons.build_outlined),
                  label: 'Services',
                ),
                NavigationDestination(
                  icon: Icon(Icons.campaign_outlined),
                  label: 'Staff',
                ),
                NavigationDestination(
                  icon: Icon(Icons.campaign_outlined),
                  label: 'Service Menu',
                ),
              ],
            )
          : null,
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
              ? AppColors.primary
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
}
