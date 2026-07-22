import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/components/customerstats.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body:SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
             mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                 mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                      'Customers',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 28,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Manage your customer relationships',
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
                            onPressed: () {
                            
                            },
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
                              'Add Customer',
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
                  const SizedBox(height: 15,),
                    Padding(
                      padding: const EdgeInsets.all(23),
                      child: Row(
                        spacing: 15,
                        children: [
                          Expanded(child: Customerstats(
                            title: 'Total Customers', 
                            value: '1247', 
                            badge: '+12.5%', 
                            badgeColor: Colors.green,)
                            ),
                             Expanded(child: Customerstats(
                            title: 'Active Members', 
                            value: '892', 
                            badge: '+5.4%', 
                            badgeColor: Colors.green,)
                            ),
                             Expanded(child: Customerstats(
                            title: 'New This Month', 
                            value: '43', 
                            badge: '+12% from last month', 
                            badgeColor: Colors.green,)
                            )
                        ],
                      ),
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
                     
                      
                      const SizedBox(width: 12),
                      
                      /// Filter Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                        
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            backgroundColor: AppColors.surface,
                            minimumSize: const Size(0, 50),
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
                            minimumSize: const Size(10, 50),
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
                ],
              ),
             
            ],
          ),
        ),

      ) ,
    );
  }
}