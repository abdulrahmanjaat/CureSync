import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bento_card.dart';

class PillTimelineEntry {
  final String time;
  final bool isTaken;
  const PillTimelineEntry({required this.time, required this.isTaken});
}

class PillTimeline extends StatelessWidget {
  final List<PillTimelineEntry> entries;

  const PillTimeline({
    super.key,
    this.entries = const [
      PillTimelineEntry(time: '8:00 AM', isTaken: true),
      PillTimelineEntry(time: '12:00 PM', isTaken: true),
      PillTimelineEntry(time: '4:00 PM', isTaken: false),
      PillTimelineEntry(time: '9:00 PM', isTaken: false),
    ],
  });

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pill Timeline',
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 16.h),

          /// Timeline row
          Row(
            children: List.generate(entries.length, (i) {
              final e = entries[i];
              final tealColor = const Color(0xFF0D9488);
              final coralColor = const Color(0xFFFF6B6B);
              final color = e.isTaken ? tealColor : coralColor;

              return Expanded(
                child: Column(
                  children: [
                    /// Time
                    Text(
                      e.time,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    SizedBox(height: 8.h),

                    /// Track with pill dot
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
                            color: e.isTaken
                                ? color
                                : color.withValues(alpha: 0.1),
                            border: e.isTaken
                                ? null
                                : Border.all(
                                    color: color.withValues(alpha: 0.4),
                                    width: 2),
                          ),
                          child: e.isTaken
                              ? Icon(Icons.check_rounded,
                                  size: 16.w, color: Colors.white)
                              : Center(
                                  child: Container(
                                    height: 8.w,
                                    width: 8.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: coralColor,
                                    ),
                                  ),
                                ),
                        ),
                        if (i < entries.length - 1)
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

                    /// Status
                    Text(
                      e.isTaken ? 'Taken' : 'Upcoming',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
