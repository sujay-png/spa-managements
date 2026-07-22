import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';
import 'package:ira_spa_webapp/views/bookings/booking_tabel.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bookings',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 25,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Manage all your spa appointments',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      SizedBox(
                        width: 200,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF8C7B68,
                            ), 
                            foregroundColor: AppColors.surface,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                30,
                              ), 
                            ),
                          ),
                          icon: const Icon(Icons.add, size: 20),
                          label: Text(
                            'New Booking',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontSize: 15,
                                  color: AppColors.surface,
                                ),
                          ),
                        ),
                      ),
                      
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 1200,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            // onChanged: controller.search,
                            decoration: const InputDecoration(
                              hintText: 'Search by customer, phone or bookingId…',
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: 'Cancelled',
                              icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.textPrimary),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              items: <String>['Cancelled', 'Confirmed', 'Pending']
                                  .map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                              
                              },
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      /// Filter Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                        
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            backgroundColor: AppColors.surface,
                            minimumSize: const Size(0, 40),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          icon: const Icon(Icons.filter_alt_outlined, size: 18, color: AppColors.textSecondary),
                          label: const Text(
                            'Filter',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      /// Export Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                        
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            backgroundColor: AppColors.surface,
                            minimumSize: const Size(0, 40),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          icon: const Icon(Icons.download_outlined, size: 18, color: AppColors.textSecondary),
                          label: const Text(
                            'Export',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      )
                    ],
                  ),
//==============================Bookings Tabel============================================================
BookingTabel()
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
