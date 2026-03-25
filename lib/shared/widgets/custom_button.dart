import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final bool isOutlined;
  final bool isLoading;
  final double? width;
  final double? height;
  final double borderRadius;
  final Widget? leadingIcon;
  final double fontSize;
  final FontWeight fontWeight;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor = AppColors.primary,
    this.textColor = Colors.white,
    this.isOutlined = false,
    this.isLoading = false,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.leadingIcon,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          SizedBox(
            width: 20.w,
            height: 20.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isOutlined ? backgroundColor : textColor,
            ),
          )
        else ...[
          if (leadingIcon != null) ...[
            leadingIcon!,
            SizedBox(width: 8.w),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize.sp,
              fontWeight: fontWeight,
              color: isOutlined ? backgroundColor : textColor,
            ),
          ),
        ],
      ],
    );

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 48.h,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: backgroundColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius.r),
                ),
              ),
              child: content,
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                disabledBackgroundColor: AppColors.disabled,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius.r),
                ),
              ),
              child: content,
            ),
    );
  }
}
