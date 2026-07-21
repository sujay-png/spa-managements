import 'package:flutter/material.dart';
import 'package:ira_spa_webapp/theme/app_theme.dart';

class DashboardStats extends StatelessWidget {
  final String title;
  final String value;
  final String badge;
  final Color badgeColor;
  final IconData icon;

  const DashboardStats({
    super.key,
    required this.title,
    required this.value,
    required this.badge,
    required this.badgeColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 165,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Top Row
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ),

              const Spacer(),

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

          const Spacer(),

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
              fontSize: 38,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}