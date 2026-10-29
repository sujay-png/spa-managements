import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/controllers/auth_controller.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';
import 'package:ira_spa_webapp/theme/responsive.dart';
import 'package:ira_spa_webapp/views/bookings/booking_page.dart';
import 'package:ira_spa_webapp/views/customer/customer_page.dart';
import 'package:ira_spa_webapp/views/dashboard/dashboard.dart';
import 'package:ira_spa_webapp/views/service_menu/screen.dart';
import 'package:ira_spa_webapp/views/services/services_page.dart';
import 'package:ira_spa_webapp/views/staff/staff_page.dart';
import 'package:provider/provider.dart';

class Shellroute extends StatefulWidget {
  const Shellroute({super.key});

  @override
  State<Shellroute> createState() => _ShellrouteState();
}

class _ShellrouteState extends State<Shellroute> {
  int _index = 0;

  static const _pages = [
    Dashboard(),
    BookingPage(),
    CustomerPage(),
    ServicePage(),
    StaffPage(),
    ServiceMenuView(),
  ];

  static const _navItems = [
    (icon: Icons.dashboard_outlined, label: 'Dashboard'),
    (icon: Icons.calendar_today_outlined, label: 'Bookings'),
    (icon: Icons.people_outline, label: 'Customers'),
    (icon: Icons.content_cut, label: 'Services'),
    (icon: Icons.person_outline, label: 'Staff'),
    (icon: Icons.menu_book_outlined, label: 'Service Menu'),
  ];

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final displayName = authController.userName ?? '';
    final businessname = authController.Bussiness ?? '';

    return Scaffold(
      body: ResponsiveLayout(
        mobile: _pages[_index],
        tablet: Row(
          children: [
            _CollapsedSidebar(
              selectedIndex: _index,
              onTap: (i) => setState(() => _index = i),
              navItems: _navItems,
              displayName: displayName,
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _pages[_index]),
          ],
        ),
        desktop: Row(
          children: [
            _FullSidebar(
              selectedIndex: _index,
              onTap: (i) => setState(() => _index = i),
              navItems: _navItems,
              displayName: displayName,
              businessname: businessname,
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _pages[_index]),
          ],
        ),
      ),
      bottomNavigationBar: context.isMobile
          ? NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              height: 64,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.secondary.withValues(alpha: 0.2),
              destinations: _navItems
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      label: item.label,
                      tooltip: item.label,
                    ),
                  )
                  .toList(),
            )
          : null,
    );
  }
}

// ─── Full Sidebar (Desktop) ──────────────────────────────────────────────────
class _FullSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<({IconData icon, String label})> navItems;
  final String displayName;
  final String businessname;

  const _FullSidebar({
    required this.selectedIndex,
    required this.onTap,
    required this.navItems,
    required this.displayName,
    required this.businessname,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF66564A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.content_cut, color: Colors.white, size: 20),
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
                        'MANAGEMENT',
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
          const SizedBox(height: 28),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MAIN MENU',
                style: TextStyle(fontSize: 10, letterSpacing: 2, color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...navItems.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final selected = selectedIndex == i;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onTap(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF66564A) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        size: 20,
                        color: selected ? Colors.white : AppColors.textPrimary,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          const Divider(color: AppColors.border),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF66564A),
                radius: 18,
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              trailing: Tooltip(
                message: 'Logout',
                child: IconButton(
                  onPressed: () => context.read<AuthController>().signOut(),
                  icon: const Icon(Icons.logout, size: 20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Collapsed Sidebar (Tablet) ──────────────────────────────────────────────
class _CollapsedSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<({IconData icon, String label})> navItems;
  final String displayName;

  const _CollapsedSidebar({
    required this.selectedIndex,
    required this.onTap,
    required this.navItems,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Logo icon only
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF66564A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.content_cut, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 24),
          ...navItems.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final selected = selectedIndex == i;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Tooltip(
                message: item.label,
                preferBelow: false,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onTap(i),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF66564A) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.icon,
                      size: 22,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          Tooltip(
            message: 'Logout',
            child: IconButton(
              onPressed: () => context.read<AuthController>().signOut(),
              icon: const Icon(Icons.logout, size: 20),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
