import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';

class UpcommingAppointments extends StatefulWidget {
  const UpcommingAppointments({super.key});

  @override
  State<UpcommingAppointments> createState() => _UpcommingAppointmentsState();
}

class _UpcommingAppointmentsState extends State<UpcommingAppointments> {

   final List<Map<String, dynamic>> appointments = [
    {
      'time': '10:00 AM',
      'clientName': 'Emma Wilson',
      'service': 'Swedish Massage',
      'staffName': 'Dr. Sarah',
      'status': 'confirmed',
    },
    {
      'time': '11:30 AM',
      'clientName': 'Michael Brown',
      'service': 'Facial Treatment',
      'staffName': 'Lisa Chen',
      'status': 'confirmed',
    },
    {
      'time': '02:00 PM',
      'clientName': 'Sophie Martinez',
      'service': 'Hot Stone Therapy',
      'staffName': 'Dr. Sarah',
      'status': 'pending',
    },
    {
      'time': '03:30 PM',
      'clientName': 'James Anderson',
      'service': 'Aromatherapy',
      'staffName': 'Amy Parker',
      'status': 'confirmed',
    },
  ];
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
      ),
    
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(15),
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
                    // Handle View All action
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
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.border,
                      width: index == appointments.length - 1 ? 0 : 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        appointment['time'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment['clientName'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            appointment['service'],
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      appointment['staffName'],
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 24),
    
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: appointment['status'] == 'confirmed'
                            ? Colors.green.withOpacity(0.12)
                            : Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        appointment['status'],
                        style: TextStyle(
                          color: appointment['status'] == 'confirmed'
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}