import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';

class Customerstats extends StatelessWidget {
  final String title;
  final String value;
  final String badge;
  final Color badgeColor;

  const Customerstats({
    super.key,
    required this.title,
    required this.value,
    required this.badge,
    required this.badgeColor,

  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        spacing: 15,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            value,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(.12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
