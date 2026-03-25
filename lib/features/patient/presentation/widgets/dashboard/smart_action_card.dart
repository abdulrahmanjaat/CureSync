import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'glass_card.dart';

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
    final name = medName ?? 'No meds yet';
    final displayTime = time ?? '--:--';

    return GlassCard(
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  medName != null
                      ? 'Time for your Morning\nDosage of $name'
                      : 'No upcoming\nmedications',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.3,
                  ),
                ),
              ),
              Icon(Icons.notifications_active_rounded,
                  size: 18.w, color: const Color(0xFF5EEAD4)),
            ],
          ),
          if (medName != null) ...[
            SizedBox(height: 4.h),
            Text(
              '($displayTime)',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
            SizedBox(height: 10.h),
            GestureDetector(
              onTap: onDone,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded,
                        size: 14.w, color: const Color(0xFF5EEAD4)),
                    SizedBox(width: 4.w),
                    Text(
                      'Done',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
