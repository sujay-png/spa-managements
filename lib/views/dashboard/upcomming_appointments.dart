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

              final isConfirmed = appointment['status'] == 'confirmed';

              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.border,
                      width: index == appointments.length - 1 ? 0 : 1,
                    ),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),

                  // Time
                  leading: SizedBox(
                    width: 70,
                    child: Center(
                      child: Text(
                        appointment['time'],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),

                  // Client Name
                  title: Text(
                    appointment['clientName'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  // Service
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      appointment['service'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),

                  // Staff + Status
                  trailing: SizedBox(
                    width: 170,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: Text(
                            appointment['staffName'],
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
                            appointment['status'],
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
        ],
      ),
    );
  }
}
