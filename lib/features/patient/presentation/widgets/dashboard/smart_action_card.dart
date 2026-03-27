import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bento_card.dart';
import 'status_tag.dart';

class SmartActionCard extends StatelessWidget {
  final String? medName;
  final String? time;
  final VoidCallback? onDone;

  const SmartActionCard({
    super.key,
    this.medName,
    this.time,
    this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.notifications_active_rounded,
                  size: 18.w, color: const Color(0xFF0D9488)),
              StatusTag(
                type: medName != null ? TagType.upcoming : TagType.active,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            medName != null
                ? 'Time for your Morning\nDosage of $medName'
                : 'No upcoming\nmedications',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
              height: 1.3,
            ),
          ),
          if (medName != null) ...[
            SizedBox(height: 2.h),
            Text(
              '($time)',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: const Color(0xFF94A3B8),
              ),
            ),
            SizedBox(height: 10.h),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onDone?.call();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded,
                        size: 14.w, color: const Color(0xFF0D9488)),
                    SizedBox(width: 4.w),
                    Text(
                      'Done',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0D9488),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
