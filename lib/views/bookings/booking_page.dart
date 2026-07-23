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
                          onPressed: () {
                            showBookingDialog(context);
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
                              borderRadius: BorderRadius.circular(10),
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
                  Padding(
                    padding: const EdgeInsets.all(16),

                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: TextField(
                              // onChanged: controller.search,
                              decoration: const InputDecoration(
                                hintText:
                                    'Search by customer, phone or bookingId…',
                                prefixIcon: Icon(Icons.search),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        SizedBox(
                          height: 46,
                          width: 160,
                          child: DropdownButtonFormField<String>(
                            value: 'Cancelled',
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Cancelled',
                                child: Text('Cancelled'),
                              ),
                              DropdownMenuItem(
                                value: 'Confirmed',
                                child: Text('Confirmed'),
                              ),
                              DropdownMenuItem(
                                value: 'Pending',
                                child: Text('Pending'),
                              ),
                            ],
                            onChanged: (value) {},
                          ),
                        ),


                        const SizedBox(width: 12),

                        /// Filter Button
                        SizedBox(
                          height: 46,
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              backgroundColor: AppColors.surface,
                              minimumSize: const Size(20, 50),
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            icon: const Icon(
                              Icons.filter_alt_outlined,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            label: const Text(
                              'Filter',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
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
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              backgroundColor: AppColors.surface,
                              minimumSize: const Size(15, 50),
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            icon: const Icon(
                              Icons.download_outlined,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            label: const Text(
                              'Export',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  //==============================Bookings Tabel============================================================
                  BookingTabel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //================================Booking Form===========================================================
  void showBookingDialog(BuildContext context) {
    String? customer, service, therapist;
    final dateCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

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
                              'New Booking',
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
                    label(Icons.person_outline, 'CUSTOMER'),
                    const SizedBox(height: 8),
                    dropdown('Select Customer', customer, [
                      'Sarah Jenkins',
                      'Michael Brown',
                      'Jessica Taylor',
                    ], (v) => setState(() => customer = v)),
                    const SizedBox(height: 16),
                    label(Icons.content_cut, 'SERVICE'),
                    const SizedBox(height: 8),
                    dropdown('Select Service', service, [
                      'Deep Tissue Massage',
                      'Aromatherapy',
                      'Swedish Massage',
                      'Facial Glow',
                    ], (v) => setState(() => service = v)),
                    const SizedBox(height: 16),
                    label(Icons.person_outline, 'THERAPIST'),
                    const SizedBox(height: 8),
                    dropdown(
                      'Select Therapist',
                      therapist,
                      ['Emily Watson', 'John Doe', 'Sophia Smith'],
                      (v) => setState(() => therapist = v),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              label(Icons.calendar_today_outlined, 'DATE'),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              label(Icons.access_time, 'TIME'),
                              SizedBox(height: 8),
                              TextField(
                                controller: timeCtrl,
                                readOnly: true,
                                decoration: dec('--:--', Icons.schedule),
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (picked != null)
                                    setState(
                                      () => timeCtrl.text = picked.format(
                                        context,
                                      ),
                                    );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
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
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Create Booking',
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

  Widget dropdown(
    String hint,
    String? val,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) => DropdownButtonFormField<String>(
    value: val,
    hint: Text(
      hint,
      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
    ),
    isExpanded: true,
    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87),
    decoration: dec(hint),
    dropdownColor: Colors.white,
    items: items
        .map(
          (i) => DropdownMenuItem(
            value: i,
            child: Text(
              i,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        )
        .toList(),
    onChanged: onChanged,
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
