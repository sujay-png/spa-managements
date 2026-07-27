import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StaffCard extends StatelessWidget {
  final String initials;
  final String name;
  final String designation;
  final String specialization;
  final String email;
  final String phone;
  final String rating;
  final String appointments;
  final String status;
  final Color statusBgColor;
  final Color statusTextColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StaffCard({
    super.key,
    required this.initials,
    required this.name,
    required this.designation,
    required this.specialization,
    required this.email,
    required this.phone,
    required this.rating,
    required this.appointments,
    required this.status,
    required this.statusBgColor,
    required this.statusTextColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DDD2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // ClipRRect ensures the top accent bar perfectly conforms to the 16px corner radius
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            /// Top Border Accent Line (Matches card's top corners perfectly)
            Container(
              height: 4,
              width: double.infinity,
              color: const Color(0xFF8C7A6B),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    /// Avatar Circle with Initials
                    Stack(
                      children: [
                        Center(
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: const Color(0xFFF2ECE4),
                            child: Text(
                              initials,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF6B6259),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: SizedBox(
                            width: 30,
                            child: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 18),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  onEdit.call();
                                } else if (value == 'delete') {
                                  onDelete.call();
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 16),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    /// Name, Designation & Specialization
                    Column(
                      children: [
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3B3028),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          designation,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B6259),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          specialization,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9E9188),
                          ),
                        ),
                      ],
                    ),

                    /// Contact Info (Email & Phone Containers)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F3EE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.email_outlined,
                                size: 14,
                                color: Color(0xFF9E9188),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF57473C),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F3EE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.phone_outlined,
                                size: 14,
                                color: Color(0xFF9E9188),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  phone,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF58483D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    /// Divider
                    const Divider(color: Color(0xFFF0E7DE), height: 1),

                    /// Rating & Appointments Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "RATING",
                              style: TextStyle(
                                fontSize: 9,
                                letterSpacing: 0.8,
                                color: Color(0xFF9E9188),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 15,
                                  color: Color(0xFFFFC107),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  rating,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF332A24),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "APPOINTMENTS",
                              style: TextStyle(
                                fontSize: 9,
                                letterSpacing: 0.8,
                                color: Color(0xFF9E9188),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              appointments,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF332A24),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    /// Status Badge & Schedule Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusTextColor,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {},
                          child: Row(
                            children: const [
                              Text(
                                "View Schedule",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B6259),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: Color(0xFF6B6259),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
