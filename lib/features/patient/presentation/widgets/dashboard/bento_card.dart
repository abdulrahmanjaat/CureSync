import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Clean white bento card with soft shadows and rounded corners.
class BentoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final Color? accentBorderColor;

  const BentoCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.backgroundColor,
    this.onTap,
    this.accentBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius.r),
        border: accentBorderColor != null
            ? Border.all(color: accentBorderColor!.withValues(alpha: 0.15))
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap!();
        },
        child: card,
      );
    }
    return card;
  }
}
