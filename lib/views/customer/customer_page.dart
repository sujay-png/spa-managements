import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/components/customerstats.dart';
import 'package:ira_spa_webapp/controllers/customer_controller.dart';
import 'package:ira_spa_webapp/models/customer_model.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';
import 'package:ira_spa_webapp/views/customer/customer_tabel.dart';
import 'package:provider/provider.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
    final dateCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final name = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    final Address = TextEditingController();
  final _formKey = GlobalKey<FormState>();

    bool _saving=false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
                              showcustomerdialog(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8C7B68),
                              foregroundColor: AppColors.surface,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
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
                    //===========================customer stats==============================================
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.all(23),
                      child: Row(
                        spacing: 15,
                        children: [
                          Expanded(
                            child: Customerstats(
                              title: 'Total Customers',
                              value: '1247',
                              badge: '+12.5%',
                              badgeColor: Colors.green,
                            ),
                          ),
                          Expanded(
                            child: Customerstats(
                              title: 'Active Members',
                              value: '892',
                              badge: '+5.4%',
                              badgeColor: Colors.green,
                            ),
                          ),
                          Expanded(
                            child: Customerstats(
                              title: 'New This Month',
                              value: '43',
                              badge: '+12% from last month',
                              badgeColor: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    //======================Search bar filter and export button==================================
                   Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
        /// Search Field
        Expanded(
          child: SizedBox(
            height: 46,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, email, phone, or customer ID...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        /// Filter Button
        SizedBox(
          height: 46,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.filter_alt_outlined, size: 18),
            label: const Text("Filter"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        /// Export Button
        SizedBox(
          height: 46,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text("Export"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
            ],
          ),
        ),
        
                    //==================================== customertabel=================================================
                    CustomerTabel(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //===========================================Save Customer=========================
  //===================================Save Service===================================
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await context.read<CustomerController>().addcustomer(
        CustomerModel(
          // id: '',
          name: name.text.trim(),
          email: email.text.trim(),
          phoneno: phone.text.trim(),
          address:Address.text.trim(),
          notes: notesCtrl.text.trim()
        ),
      );

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service added successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error adding service: $e');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add service: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }


  //========================================Showcustomer dialog==========================================================
  void showcustomerdialog(BuildContext context) { 
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            child: Container(
              width: 480,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Customer',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Fill in the details below',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 32, thickness: 1),
                    label(Icons.person_outline, 'Full Name'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: name,
                      decoration: dec('Enter Full Name'),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              label(Icons.email_outlined, 'Email'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: email,
                                decoration: dec('Enter Email'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              label(Icons.phone_outlined, 'Phone Number'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: phone,
                                decoration: dec('Enter Phone Number'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              label(
                                Icons.calendar_today_outlined,
                                'Date Of Birth',
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: dateCtrl,
                                readOnly: true,
                                decoration: dec(
                                  'dd-mm-yyyy',
                                  Icons.calendar_today,
                                ),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2023),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setState(
                                      () => dateCtrl.text =
                                          "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}",
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                    const SizedBox(height: 16),

                     label(null, 'Address'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: Address,
                      maxLines: 3,
                      decoration: dec('Enter Customer Address.'),
                    ),
                    const SizedBox(height: 16),
                    label(null, 'NOTES'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 3,
                      decoration: dec('Any special requests or notes...'),
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B7D76),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: ()=>_saving?null:_save,
                            child: const Text(
                              'Add Customer',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration dec(String hint, [IconData? suffix]) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
    filled: true,
    fillColor: const Color(0xFFF7F5F0),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    suffixIcon: suffix != null
        ? Icon(suffix, size: 18, color: Colors.grey.shade600)
        : null,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF8B7D76)),
    ),
  );

  Widget label(IconData? icon, String text) => Row(
    children: [
      if (icon != null) ...[
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 6),
      ],
      Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: Colors.grey.shade700,
        ),
      ),
    ],
  );
}
