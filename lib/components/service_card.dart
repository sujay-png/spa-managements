import 'package:flutter/material.dart';

class ServiceCard extends StatelessWidget {
  final String title;
  final String category;
  final String duration;
  final String price;

  final String bookings;
  final String revenue;
  final String badge;

  final VoidCallback? onOptionsPressed;

  const ServiceCard({
    super.key,
    required this.title,
    required this.category,
    required this.duration,
    required this.price,
   
    required this.bookings,
    required this.revenue,
    required this.badge,
  
    this.onOptionsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          /// Top Section: Title & Category
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C221E),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3ECE5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF796D64),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

       Spacer(flex:3),

          /// Duration & Price Boxes
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F3EE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "DURATION",
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 0.8,
                          color: Color(0xFF9E9188),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Color(0xFF544436),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            duration,
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
                ),
              ),
             const SizedBox(width:16),
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F3EE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "PRICE",
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 0.8,
                          color: Color(0xFF9E9188),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF9D785A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
            
             Spacer(
              flex:2
             ),
          /// Divider with Spacing
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(
              color: Color(0xFFF0E7DE),
              height: 1,
              thickness: 1,
            ),
          ),
               
              Spacer(flex:1),
          /// Bookings & Revenue
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "BOOKINGS",
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 0.8,
                        color: Color(0xFF9E9188),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bookings,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF332A24),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "REVENUE",
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 0.8,
                        color: Color(0xFF9E9188),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      revenue,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF332A24),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Spacer(flex:9),

          /// Bottom Status Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color:  const Color(0xFFE2F3EC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: const Color(0xFF108A00),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}