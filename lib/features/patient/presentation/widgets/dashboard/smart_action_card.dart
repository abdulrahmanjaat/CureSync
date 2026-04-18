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

  /// True when the current clock time has reached the scheduled dose time.
  /// Controls whether the Done button is interactive.
  final bool isDue;

  /// Human-readable countdown until the dose is due, e.g. "2h 15m".
  /// Null when [isDue] is true or [medName] is null.
  final String? countdownLabel;

  const SmartActionCard({
    super.key,
    this.medName,
    this.time,
    this.onDone,
    this.isDue = false,
    this.countdownLabel,
  });

  @override
  Widget build(BuildContext context) {
    const teal   = Color(0xFF0D9488);
    const locked = Color(0xFF94A3B8);

    // Resolved button colour: teal when due, slate-grey when locked
    final btnColor = isDue ? teal : locked;

    return BentoCard(
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row: bell icon + status tag ──────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                isDue
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_outlined,
                size: 18.w,
                color: isDue ? teal : locked,
              ),
              StatusTag(
                type: medName == null
                    ? TagType.active
                    : isDue
                        ? TagType.ongoing   // "Due now"
                        : TagType.upcoming, // "Upcoming"
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // ── Medication message ────────────────────────────────────────────
          Text(
            medName != null
                ? isDue
                    ? 'Time to take\n$medName'
                    : 'Upcoming dose\nof $medName'
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
              isDue ? 'Scheduled at $time' : '($time)',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: const Color(0xFF94A3B8),
              ),
            ),

            // ── Countdown bar (only when not yet due) ─────────────────────
            if (!isDue && countdownLabel != null) ...[
              SizedBox(height: 6.h),
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 11.w, color: locked),
                  SizedBox(width: 3.w),
                  Text(
                    'Due in $countdownLabel',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: locked,
                    ),
                  ),
                ],
              ),
            ],

            SizedBox(height: 10.h),

            // ── Done / Locked button ─────────────────────────────────────
            GestureDetector(
              onTap: isDue
                  ? () {
                      HapticFeedback.lightImpact();
                      onDone?.call();
                    }
                  : () => HapticFeedback.selectionClick(), // no-op tap feedback
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: btnColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: btnColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDue ? Icons.check_rounded : Icons.lock_rounded,
                      size: 14.w,
                      color: btnColor,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      isDue ? 'Done' : 'Locked',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: btnColor,
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
