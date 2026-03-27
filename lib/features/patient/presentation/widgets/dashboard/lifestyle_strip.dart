import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bento_card.dart';
import 'status_tag.dart';

class LifestyleStrip extends StatelessWidget {
  const LifestyleStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LifestyleTile(
            emoji: '💧',
            label: 'Water',
            value: '5/8',
            unit: 'glasses',
            streak: '5 day streak',
            points: '12 pts',
            color: const Color(0xFF0EA5E9),
            tagType: TagType.ongoing,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _LifestyleTile(
            emoji: '🌙',
            label: 'Sleep',
            value: '7h 15m',
            unit: '',
            streak: '3 day streak',
            points: '8 pts',
            color: const Color(0xFF7C3AED),
            tagType: TagType.active,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _LifestyleTile(
            emoji: '🥗',
            label: 'Diet',
            value: '1,840',
            unit: 'cal',
            streak: '',
            points: '5 pts',
            color: const Color(0xFF22C55E),
            tagType: TagType.taken,
          ),
        ),
      ],
    );
  }
}

class _LifestyleTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final String unit;
  final String streak;
  final String points;
  final Color color;
  final TagType tagType;

  const _LifestyleTile({
    required this.emoji,
    required this.label,
    required this.value,
    required this.unit,
    required this.streak,
    required this.points,
    required this.color,
    required this.tagType,
  });

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: EdgeInsets.all(12.w),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(emoji, style: TextStyle(fontSize: 20.sp)),
              StatusTag(type: tagType),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: const Color(0xFF94A3B8),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              if (unit.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(left: 2.w, bottom: 1.h),
                  child: Text(
                    unit,
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ),
            ],
          ),
          if (streak.isNotEmpty || points.isNotEmpty) ...[
            SizedBox(height: 8.h),
            if (streak.isNotEmpty)
              Text(
                streak,
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            if (points.isNotEmpty)
              Text(
                points,
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  color: const Color(0xFF94A3B8),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
