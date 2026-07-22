import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';

class BookingTabel extends StatefulWidget {
  const BookingTabel({super.key});

  @override
  State<BookingTabel> createState() => _BookingTabelState();
}

class _BookingTabelState extends State<BookingTabel> {
  int _currentPage = 0;
  final int _rowsPerPage = 2; 
  final List<Map<String, dynamic>> bookings = [
    {
      'id': 'BK001',
      'clientName': 'Emma Wilson',
      'phone': '+1 234 567 8900',
      'service': 'Swedish Massage',
      'duration': '60 min',
      'therapist': 'Dr. Sarah Johnson',
      'date': 'Dec 5, 2025',
      'time': '10:00 AM - 11:00 AM',
      'price': '\$120',
      'status': 'Confirmed',
    },
    {
      'id': 'BK002',
      'clientName': 'Michael Brown',
      'phone': '+1 234 567 8901',
      'service': 'Facial Treatment',
      'duration': '60 min',
      'therapist': 'Lisa Chen',
      'date': 'Dec 5, 2025',
      'time': '11:30 AM - 12:30 PM',
      'price': '\$95',
      'status': 'Confirmed',
    },
    {
      'id': 'BK003',
      'clientName': 'Sophie Martinez',
      'phone': '+1 234 567 8902',
      'service': 'Hot Stone Therapy',
      'duration': '90 min',
      'therapist': 'Dr. Sarah Johnson',
      'date': 'Dec 5, 2025',
      'time': '02:00 PM - 03:30 PM',
      'price': '\$150',
      'status': 'Pending',
    },
    {
      'id': 'BK004',
      'clientName': 'James Anderson',
      'phone': '+1 234 567 8903',
      'service': 'Aromatherapy',
      'duration': '60 min',
      'therapist': 'Amy Parker',
      'date': 'Dec 6, 2025',
      'time': '09:00 AM - 10:00 AM',
      'price': '\$110',
      'status': 'Confirmed',
    },
    {
      'id': 'BK005',
      'clientName': 'Olivia Davis',
      'phone': '+1 234 567 8904',
      'service': 'Deep Tissue Massage',
      'duration': '90 min',
      'therapist': 'Dr. Sarah Johnson',
      'date': 'Dec 6, 2025',
      'time': '02:30 PM - 04:00 PM',
      'price': '\$140',
      'status': 'Completed',
    },
    {
      'id': 'BK006',
      'clientName': 'Emma Wilson',
      'phone': '+1 234 567 8900',
      'service': 'Swedish Massage',
      'duration': '60 min',
      'therapist': 'Dr. Sarah Johnson',
      'date': 'Dec 5, 2025',
      'time': '10:00 AM - 11:00 AM',
      'price': '\$120',
      'status': 'Confirmed',
    },
    {
      'id': 'BK007',
      'clientName': 'Michael Brown',
      'phone': '+1 234 567 8901',
      'service': 'Facial Treatment',
      'duration': '60 min',
      'therapist': 'Lisa Chen',
      'date': 'Dec 5, 2025',
      'time': '11:30 AM - 12:30 PM',
      'price': '\$95',
      'status': 'Confirmed',
    },
    {
      'id': 'BK008',
      'clientName': 'Sophie Martinez',
      'phone': '+1 234 567 8902',
      'service': 'Hot Stone Therapy',
      'duration': '90 min',
      'therapist': 'Dr. Sarah Johnson',
      'date': 'Dec 5, 2025',
      'time': '02:00 PM - 03:30 PM',
      'price': '\$150',
      'status': 'Pending',
    },
    {
      'id': 'BK009',
      'clientName': 'James Anderson',
      'phone': '+1 234 567 8903',
      'service': 'Aromatherapy',
      'duration': '60 min',
      'therapist': 'Amy Parker',
      'date': 'Dec 6, 2025',
      'time': '09:00 AM - 10:00 AM',
      'price': '\$110',
      'status': 'Confirmed',
    },
    {
      'id': 'BK0010',
      'clientName': 'Olivia Davis',
      'phone': '+1 234 567 8904',
      'service': 'Deep Tissue Massage',
      'duration': '90 min',
      'therapist': 'Dr. Sarah Johnson',
      'date': 'Dec 6, 2025',
      'time': '02:30 PM - 04:00 PM',
      'price': '\$140',
      'status': 'Completed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final int totalPages = (bookings.length / _rowsPerPage).ceil();
    final int startIndex = _currentPage * _rowsPerPage;
    final int endIndex = (startIndex + _rowsPerPage) > bookings.length
        ? bookings.length
        : (startIndex + _rowsPerPage);

    final List<Map<String, dynamic>> paginatedAppointments = bookings.isEmpty
        ? []
        : bookings.sublist(startIndex, endIndex);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Table Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 1, child: Text('BOOKING ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.8))),
                Expanded(flex: 2, child: Text('CUSTOMER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.8))),
                Expanded(flex: 2, child: Text('SERVICE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.8))),
                Expanded(flex: 2, child: Text('THERAPIST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.8))),
                Expanded(flex: 2, child: Text('DATE & TIME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.8))),
                Expanded(flex: 1, child: Text('PRICE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.8))),
                Expanded(flex: 1, child: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 0.8))),
                SizedBox(width: 30), // Action Column space
              ],
            ),
          ),

         
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: paginatedAppointments.length,
            itemBuilder: (context, index) {
              final item = paginatedAppointments[index];
              final isConfirmed = item['status'] == 'Confirmed';
              final isPending = item['status'] == 'Pending';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.border,
                      width: index == paginatedAppointments.length - 1 ? 0 : 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    /// Booking ID
                    Expanded(
                      flex: 1,
                      child: Text(
                        item['id'],
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 13),
                      ),
                    ),

                    /// Customer
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['clientName'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(item['phone'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),

                    /// Service
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['service'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(item['duration'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),

                    /// Therapist
                    Expanded(
                      flex: 2,
                      child: Text(
                        item['therapist'],
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),

                    /// Date & Time
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(item['date'], style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 12, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(item['time'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    /// Price
                    Expanded(
                      flex: 1,
                      child: Text(
                        item['price'],
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 13),
                      ),
                    ),

                    /// Status
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isConfirmed
                                ? Colors.green.withOpacity(0.12)
                                : isPending
                                    ? Colors.orange.withOpacity(0.12)
                                    : Colors.blue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            item['status'],
                            style: TextStyle(
                              color: isConfirmed
                                  ? Colors.green
                                  : isPending
                                      ? Colors.orange
                                      : Colors.blue,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// Actions Menu
                    SizedBox(
                      width: 30,
                      child: IconButton(
                        icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
                        onPressed: () {
                          // Handle menu option click
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${startIndex + 1}-$endIndex of ${bookings.length} entries',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _currentPage > 0
                          ? () => setState(() => _currentPage--)
                          : null,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text('Previous', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'Page ${_currentPage + 1} of $totalPages',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _currentPage < totalPages - 1
                          ? () => setState(() => _currentPage++)
                          : null,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text('Next', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}