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
                              borderRadius: BorderRadius.circular(30),
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
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
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
                      Spacer(),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          height: 50,
                          width: 20,

                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: 'Cancelled',
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                size: 20,
                                color: AppColors.textPrimary,
                              ),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              items:
                                  <String>[
                                    'Cancelled',
                                    'Confirmed',
                                    'Pending',
                                  ].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {},
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      /// Filter Button
                      Expanded(
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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      Expanded(
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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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

  void showBookingDialog(BuildContext context) {
    final customers = ['Amelia Rao', 'Priya Shetty', 'Neha Kamath'];
    final services = ['Haircut', 'Facial', 'Massage'];
    final therapists = ['Anjali', 'Rohan', 'Fatima'];

    const brown = Color(0xFF8A6D4E);

    String? customer, service, therapist;
    DateTime? date;
    TimeOfDay? time;
    final notes = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "New Booking",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Text(
                      "Fill in the details below",
                      style: TextStyle(color: Color(0xFF9A9187), fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    dropdown(
                      "Customer",
                      Icons.person_outline,
                      customers,
                      customer,
                      (v) => setState(() => customer = v),
                    ),
                    const SizedBox(height: 16),
                    dropdown(
                      "Service",
                      Icons.content_cut,
                      services,
                      service,
                      (v) => setState(() => service = v),
                    ),
                    const SizedBox(height: 16),
                    dropdown(
                      "Therapist",
                      Icons.person_outline,
                      therapists,
                      therapist,
                      (v) => setState(() => therapist = v),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              label(Icons.calendar_today_outlined, "Date"),
                              TextField(
                                readOnly: true,
                                decoration: decoration.copyWith(
                                  hintText: date == null
                                      ? "dd-mm-yyyy"
                                      : "${date!.day}-${date!.month}-${date!.year}",
                                  suffixIcon: const Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                  ),
                                ),
                                onTap: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2024),
                                    lastDate: DateTime(2100),
                                  );
                                  if (d != null) setState(() => date = d);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              label(Icons.access_time, "Time"),
                              TextField(
                                readOnly: true,
                                decoration: decoration.copyWith(
                                  hintText: time?.format(context) ?? "--:--",
                                  suffixIcon: const Icon(
                                    Icons.access_time,
                                    size: 18,
                                  ),
                                ),
                                onTap: () async {
                                  final t = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (t != null) setState(() => time = t);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    label(Icons.edit_note, "Notes"),
                    TextField(
                      controller: notes,
                      maxLines: 3,
                      decoration: decoration.copyWith(
                        hintText: "Any special requests or notes...",
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.black87),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brown,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Create Booking"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const fill = Color(0xFFF1ECE3);
const labelColor = Color(0xFF6B6259);
Widget label(IconData icon, String text) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Row(
    children: [
      Icon(icon, size: 16, color: labelColor),
      const SizedBox(width: 6),
      Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: labelColor,
        ),
      ),
    ],
  ),
);

Widget dropdown(
  String hint,
  IconData icon,
  List<String> items,
  String? value,
  void Function(String?) onChanged,
) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    label(icon, hint),
    DropdownButtonFormField<String>(
      value: value,
      decoration: decoration.copyWith(hintText: "Select $hint"),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) => onChanged(v),
    ),
  ],
);
final decoration = InputDecoration(
  filled: true,
  fillColor: fill,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,
  ),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
);
