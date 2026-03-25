import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'glass_card.dart';

class VitalsBento extends StatelessWidget {
  const VitalsBento({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Heart Rate:',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    Icon(Icons.monitor_heart_rounded,
                        size: 18.w, color: const Color(0xFFFF6B6B)),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  '72 bpm',
                  style: GoogleFonts.poppins(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                // Mini ECG line
                CustomPaint(
                  size: Size(double.infinity, 20.h),
                  painter: _EcgPainter(),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: GlassCard(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Blood Pressure:',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    Icon(Icons.bloodtype_rounded,
                        size: 18.w, color: const Color(0xFF0D9488)),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  '120/80',
                  style: GoogleFonts.poppins(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'mmHg',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
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
      ..color = const Color(0xFFFF6B6B).withValues(alpha: 0.6)
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
    path.lineTo(w * 0.40, mid - size.height * 0.7);
    path.lineTo(w * 0.46, mid + size.height * 0.3);
    path.lineTo(w * 0.52, mid);
    path.lineTo(w, mid);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
