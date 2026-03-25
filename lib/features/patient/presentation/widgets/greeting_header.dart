import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';

class GreetingHeader extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final VoidCallback onLogout;

  const GreetingHeader({
    super.key,
    required this.name,
    this.photoUrl,
    required this.onLogout,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = name.split(' ').first;

    return Row(
      children: [
        /// Avatar
        Container(
          height: 50.w,
          width: 50.w,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: photoUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: Image.network(
                    photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _initialsWidget(firstName),
                  ),
                )
              : _initialsWidget(firstName),
        ),
        SizedBox(width: 14.w),

        /// Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting 👋',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                firstName,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        /// Notification + Logout
        _IconBtn(
          icon: Icons.notifications_none_rounded,
          onTap: () {},
        ),
        SizedBox(width: 8.w),
        _IconBtn(
          icon: Icons.logout_rounded,
          onTap: onLogout,
        ),
      ],
    );
  }

  Widget _initialsWidget(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42.w,
        width: 42.w,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
        ),
        child: Icon(icon, size: 20.w, color: AppColors.textSecondary),
      ),
    );
  }
}
