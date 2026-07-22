import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/components/dashboard_stats.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';
import 'package:ira_spa_webapp/views/dashboard/services_list.dart';
import 'package:ira_spa_webapp/views/dashboard/upcomming_appointments.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
 

  @override
  Widget build(BuildContext context) {
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
                    'Welcome back, Sarah',
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
                      title: "Total Revenue",
                      value: "\$24,580",
                      badge: "+12.5%",
                      badgeColor: Colors.green,
                      icon: Icons.attach_money,
                    ),
                  ),

                  const SizedBox(width: 20),

                  Expanded(
                    child: DashboardStats(
                      title: "Today's Bookings",
                      value: "18",
                      badge: "+3 from yesterday",
                      badgeColor: Colors.green,
                      icon: Icons.calendar_today_outlined,
                    ),
                  ),

                  const SizedBox(width: 20),

                  Expanded(
                    child: DashboardStats(
                      title: "Total Customers",
                      value: "1,247",
                      badge: "+8.2%",
                      badgeColor: Colors.green,
                      icon: Icons.groups_outlined,
                    ),
                  ),

                  const SizedBox(width: 20),

                  Expanded(
                    child: DashboardStats(
                      title: "Avg. Wait Time",
                      value: "12 min",
                      badge: "-2 min",
                      badgeColor: Colors.blue,
                      icon: Icons.schedule_outlined,
                    ),
                  ),
                ],
              ),

              //========================================List Tille==============================================================
              Row(
                spacing: 15,
                children: [
                  
                   Expanded(child: UpcommingAppointments(),),
                   Expanded(child: ServicesList(),)
                ],
                
              ),
           
            ],
          ),
        ),
      ),
    );
  }
}
