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
            Container(
              padding: EdgeInsets.all(15),
              
              child: Icon(Icons.spa)),
            SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Serenity Spa',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Management',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
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
              NavigationRail(
               extended: true,
                minWidth: 72,
                minExtendedWidth: 200,
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                labelType: NavigationRailLabelType.none,
                backgroundColor: AppColors.surface,
                indicatorColor: AppColors.secondary.withValues(alpha: 0.2),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: Text('Dashboard'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.people_outline),
                    selectedIcon: Icon(Icons.people),
                    label: Text('Bookings'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.payments_outlined),
                    selectedIcon: Icon(Icons.payments),
                    label: Text('Customers'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.build_outlined),
                    selectedIcon: Icon(Icons.build),
                    label: Text('Services'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.campaign_outlined),
                    selectedIcon: Icon(Icons.campaign),
                    label: Text('Staff'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.campaign_outlined),
                    selectedIcon: Icon(Icons.campaign),
                    label: Text('Service Menu'),
                  ),
                ],
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
}
