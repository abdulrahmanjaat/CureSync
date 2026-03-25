import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItem> items;
  final VoidCallback? onFabPressed;
  final IconData fabIcon;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.onFabPressed,
    this.fabIcon = Icons.add,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      margin: EdgeInsets.only(bottom: 20.w, left: 20.w, right: 20.w),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ...List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = index == currentIndex;

            return GestureDetector(
              onTap: () => onTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 10.h,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 20.w,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                    if (isSelected && item.label != null) ...[
                      SizedBox(width: 6.w),
                      Text(
                        item.label!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          if (onFabPressed != null)
            GestureDetector(
              onTap: onFabPressed,
              child: Container(
                height: 44.h,
                width: 44.w,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(fabIcon, size: 22.w, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final String? label;

  const BottomNavItem({required this.icon, this.label});
}
