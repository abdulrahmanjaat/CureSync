import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

enum TagType { active, ongoing, taken, hold, upcoming }

class StatusTag extends StatelessWidget {
  final TagType type;
  final String? customLabel;

  const StatusTag({super.key, required this.type, this.customLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Text(
        customLabel ?? _label,
        style: GoogleFonts.inter(
          fontSize: 9.sp,
          fontWeight: FontWeight.w700,
          color: _textColor,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  String get _label => switch (type) {
        TagType.active => 'Active',
        TagType.ongoing => 'Ongoing',
        TagType.taken => 'Taken',
        TagType.hold => 'Hold for 3s',
        TagType.upcoming => 'Upcoming',
      };

  Color get _bgColor => switch (type) {
        TagType.active => const Color(0xFF0D9488).withValues(alpha: 0.1),
        TagType.ongoing => const Color(0xFFF59E0B).withValues(alpha: 0.12),
        TagType.taken => const Color(0xFF22C55E).withValues(alpha: 0.1),
        TagType.hold => const Color(0xFFEF4444).withValues(alpha: 0.1),
        TagType.upcoming => const Color(0xFF0EA5E9).withValues(alpha: 0.1),
      };

  Color get _textColor => switch (type) {
        TagType.active => const Color(0xFF0D9488),
        TagType.ongoing => const Color(0xFFF59E0B),
        TagType.taken => const Color(0xFF22C55E),
        TagType.hold => const Color(0xFFEF4444),
        TagType.upcoming => const Color(0xFF0EA5E9),
      };
}
