import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? leftBorderColor;
  final double leftBorderWidth;
  final List<BoxShadow>? shadow;

  const CustomCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.leftBorderColor,
    this.leftBorderWidth = 4,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    Border? border;
    if (leftBorderColor != null) {
      border = Border(
        left: BorderSide(color: leftBorderColor!, width: leftBorderWidth),
      );
    } else if (borderColor != null) {
      border = Border.all(color: borderColor!);
    }

    final card = Container(
      padding: padding ?? EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius ?? 16.r),
        border: border,
        boxShadow: shadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12.r,
                offset: Offset(0, 4.h),
              ),
            ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}
