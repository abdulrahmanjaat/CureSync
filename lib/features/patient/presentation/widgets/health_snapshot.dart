import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';

class HealthSnapshot extends StatelessWidget {
  const HealthSnapshot({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Health Snapshot',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(100.r),
              ),
              child: Text(
                'Today',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),

        Row(
          children: [
            Expanded(
              child: _VitalCard(
                icon: Icons.monitor_heart_outlined,
                label: 'Heart Rate',
                value: '--',
                unit: 'bpm',
                color: AppColors.accent,
                isEmpty: true,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _VitalCard(
                icon: Icons.bloodtype_outlined,
                label: 'Blood Pressure',
                value: '--/--',
                unit: 'mmHg',
                color: AppColors.info,
                isEmpty: true,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _VitalCard(
                icon: Icons.air_rounded,
                label: 'SpO₂',
                value: '--',
                unit: '%',
                color: AppColors.primary,
                isEmpty: true,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _VitalCard(
                icon: Icons.thermostat_outlined,
                label: 'Temperature',
                value: '--',
                unit: '°F',
                color: AppColors.warning,
                isEmpty: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VitalCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool isEmpty;

  const _VitalCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    this.isEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isEmpty
              ? AppColors.divider.withValues(alpha: 0.5)
              : color.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 32.w,
                width: 32.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isEmpty ? 0.08 : 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon,
                    size: 18.w,
                    color: isEmpty ? color.withValues(alpha: 0.5) : color),
              ),
              const Spacer(),
              if (isEmpty)
                Container(
                  height: 6.w,
                  width: 6.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.divider,
                  ),
                )
              else
                Container(
                  height: 6.w,
                  width: 6.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: isEmpty
                      ? AppColors.textHint
                      : AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 3.w),
              Padding(
                padding: EdgeInsets.only(bottom: 3.h),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
