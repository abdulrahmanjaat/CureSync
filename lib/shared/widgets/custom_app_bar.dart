import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';

class CustomAppBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBackTap;
  final bool showBackButton;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.onBackTap,
    this.showBackButton = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 20.h),
      child: Row(
        children: [
          if (showBackButton) ...[
            GestureDetector(
              onTap: onBackTap ??
                  () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
              child: Container(
                height: 44.h,
                width: 44.w,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.textPrimary,
                  size: 18.sp,
                ),
              ),
            ),
            SizedBox(width: 16.w),
          ] else
            SizedBox(width: 4.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
