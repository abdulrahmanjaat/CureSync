import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';

enum PatientStatus { critical, stable, monitoring }

class StatusBadge extends StatelessWidget {
  final PatientStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }

  Color get _color => switch (status) {
        PatientStatus.critical => AppColors.critical,
        PatientStatus.stable => AppColors.stable,
        PatientStatus.monitoring => AppColors.monitoring,
      };

  String get _label => switch (status) {
        PatientStatus.critical => 'Critical',
        PatientStatus.stable => 'Stable',
        PatientStatus.monitoring => 'Monitoring',
      };
}
