import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'glass_card.dart';

class PillTimelineEntry {
  final String time;
  final String status; // 'taken', 'missed', 'upcoming'

  const PillTimelineEntry({required this.time, required this.status});
}

class PillTimeline extends StatelessWidget {
  final List<PillTimelineEntry> entries;

  const PillTimeline({
    super.key,
    this.entries = const [
      PillTimelineEntry(time: '8:00 AM', status: 'taken'),
      PillTimelineEntry(time: '12:00 PM', status: 'taken'),
      PillTimelineEntry(time: '4:00 PM', status: 'upcoming'),
      PillTimelineEntry(time: '9:00 PM', status: 'upcoming'),
    ],
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pill Timeline',
            style: GoogleFonts.poppins(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            height: 70.h,
            child: Row(
              children: List.generate(entries.length, (i) {
                final e = entries[i];
                final isTaken = e.status == 'taken';
                final color =
                    isTaken ? const Color(0xFF0D9488) : const Color(0xFFFF6B6B);

                return Expanded(
                  child: Column(
                    children: [
                      /// Time label
                      Text(
                        e.time,
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      SizedBox(height: 6.h),

                      /// Track line + dot
                      Expanded(
                        child: Row(
                          children: [
                            if (i > 0)
                              Expanded(
                                child: Container(
                                  height: 3,
                                  color: isTaken
                                      ? color.withValues(alpha: 0.6)
                                      : Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                            Container(
                              height: 24.w,
                              width: 24.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isTaken
                                    ? color
                                    : Colors.white.withValues(alpha: 0.1),
                                border: isTaken
                                    ? null
                                    : Border.all(
                                        color: color.withValues(alpha: 0.5),
                                        width: 2,
                                      ),
                              ),
                              child: isTaken
                                  ? Icon(Icons.check_rounded,
                                      size: 14.w, color: Colors.white)
                                  : null,
                            ),
                            if (i < entries.length - 1)
                              Expanded(
                                child: Container(
                                  height: 3,
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 4.h),

                      /// Status label
                      Text(
                        isTaken ? 'Taken' : 'Upcoming',
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
          ),
        ],
      ),
    );
  }
}
