import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bento_card.dart';
import 'status_tag.dart';

class VitalsBento extends StatelessWidget {
  const VitalsBento({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        /// Heart Rate
        Expanded(
          child: BentoCard(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 36.w,
                      width: 36.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.monitor_heart_rounded,
                          size: 20.w, color: const Color(0xFFFF6B6B)),
                    ),
                    const StatusTag(type: TagType.active),
                  ],
                ),
                SizedBox(height: 14.h),
                Text(
                  'Heart Rate',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '72',
                      style: GoogleFonts.poppins(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 5.h, left: 3.w),
                      child: Text(
                        'bpm',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                CustomPaint(
                  size: Size(double.infinity, 24.h),
                  painter: _EcgPainter(),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12.w),

        /// Blood Pressure
        Expanded(
          child: BentoCard(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 36.w,
                      width: 36.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.bloodtype_rounded,
                          size: 20.w, color: const Color(0xFF0D9488)),
                    ),
                    const StatusTag(type: TagType.taken),
                  ],
                ),
                SizedBox(height: 14.h),
                Text(
                  'Blood Pressure',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '120/80',
                      style: GoogleFonts.poppins(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 5.h, left: 3.w),
                      child: Text(
                        'mmHg',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EcgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B6B).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final w = size.width;
    final mid = size.height / 2;

    path.moveTo(0, mid);
    path.lineTo(w * 0.2, mid);
    path.lineTo(w * 0.28, mid - size.height * 0.3);
    path.lineTo(w * 0.34, mid + size.height * 0.5);
    path.lineTo(w * 0.40, mid - size.height * 0.6);
    path.lineTo(w * 0.46, mid + size.height * 0.3);
    path.lineTo(w * 0.52, mid);
    path.lineTo(w, mid);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
