import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bento_card.dart';

class PillTimelineEntry {
  final String rawTime;    // "HH:mm" for sorting/comparison
  final String time;       // formatted display "8:00 AM"
  final String medId;
  final String medName;
  /// Dosage string (e.g. "500mg"). Needed when re-scheduling alerts after
  /// an unmark-done action in [_toggleDose].
  final String dosage;
  final bool isTaken;
  /// True when the clock is inside [scheduledTime, windowEnd).
  /// Only when [isDue] is true may a dose be confirmed.
  final bool isDue;
  /// True when the grace window has fully elapsed and the dose was never taken.
  /// Computed in [todayPillTimelineProvider] every minute.
  final bool isMissed;
  /// Server timestamp recorded when the dose was taken, sourced from
  /// [DoseLogModel.takenAt]. Null for untaken doses.
  final DateTime? takenAt;

  const PillTimelineEntry({
    required this.rawTime,
    required this.time,
    required this.medId,
    required this.medName,
    required this.dosage,
    required this.isTaken,
    this.isDue = false,
    this.isMissed = false,
    this.takenAt,
  });
}

class PillTimeline extends StatelessWidget {
  final List<PillTimelineEntry> entries;
  final void Function(PillTimelineEntry entry)? onToggle;

  const PillTimeline({
    super.key,
    this.entries = const [],
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pill Timeline',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                '${entries.where((e) => e.isTaken).length}/${entries.length} taken',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          if (entries.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Text(
                  'No medications scheduled today',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
            )
          else
            /// Cap at 6 entries to avoid overflow
            Row(
              children: List.generate(entries.take(6).length, (i) {
                final e = entries[i];
                final displayEntries = entries.take(6).toList();
                const tealColor   = Color(0xFF0D9488);
                const coralColor  = Color(0xFFFF6B6B);
                const redColor    = Color(0xFFEF4444);
                const lockColor   = Color(0xFFCBD5E1);

                // Colour logic:
                //  • taken          → teal
                //  • due (not taken) → coral
                //  • missed         → red
                //  • future (locked) → slate-300
                final Color color;
                if (e.isTaken) {
                  color = tealColor;
                } else if (e.isMissed) {
                  color = redColor;
                } else if (e.isDue) {
                  color = coralColor;
                } else {
                  color = lockColor;
                }

                // Missed and due entries are interactive; future entries are not
                final bool interactive = e.isTaken || e.isDue || e.isMissed;

                return Expanded(
                  child: GestureDetector(
                    onTap: interactive
                        ? () {
                            HapticFeedback.lightImpact();
                            onToggle?.call(e);
                          }
                        : null,
                    child: Column(
                      children: [
                        /// Time
                        Text(
                          e.time,
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8.h),

                        /// Track with pill dot / lock icon
                        Row(
                          children: [
                            if (i > 0)
                              Expanded(
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: e.isTaken
                                        ? tealColor.withValues(alpha: 0.4)
                                        : const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(2.r),
                                  ),
                                ),
                              ),
                            Container(
                              height: 28.w,
                              width: 28.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: interactive
                                    ? (e.isTaken
                                        ? color
                                        : color.withValues(alpha: 0.1))
                                    : lockColor.withValues(alpha: 0.15),
                                border: e.isTaken
                                    ? null
                                    : Border.all(
                                        color: color.withValues(alpha: 0.4),
                                        width: 2),
                              ),
                              child: e.isTaken
                                  // Taken: check mark
                                  ? Icon(Icons.check_rounded,
                                      size: 16.w, color: Colors.white)
                                  : e.isMissed
                                      // Missed: X icon
                                      ? Icon(Icons.close_rounded,
                                          size: 14.w, color: redColor)
                                      : e.isDue
                                          // Due: pulsing dot
                                          ? Center(
                                              child: Container(
                                                height: 8.w,
                                                width: 8.w,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: coralColor,
                                                ),
                                              ),
                                            )
                                          // Future: lock icon
                                          : Icon(Icons.lock_rounded,
                                              size: 12.w, color: lockColor),
                            ),
                            if (i < displayEntries.length - 1)
                              Expanded(
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(2.r),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 6.h),

                        /// Status label
                        Text(
                          e.isTaken
                              ? 'Taken'
                              : e.isMissed
                                  ? 'Missed'
                                  : e.isDue
                                      ? 'Due'
                                      : 'Soon',
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}
