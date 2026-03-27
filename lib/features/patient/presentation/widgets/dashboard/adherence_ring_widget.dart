import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bento_card.dart';

class AdherenceRingWidget extends StatelessWidget {
  final double percentage;
  final int taken;
  final int remaining;

  const AdherenceRingWidget({
    super.key,
    this.percentage = 0.85,
    this.taken = 6,
    this.remaining = 1,
  });

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: EdgeInsets.all(18.w),
      child: Column(
        children: [
          SizedBox(
            height: 130.w,
            width: 130.w,
            child: CustomPaint(
              painter: _RingPainter(progress: percentage),
              child: Center(
                child: Container(
                  height: 52.w,
                  width: 52.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                  ),
                  child: Icon(Icons.medication_rounded,
                      size: 26.w, color: const Color(0xFF0D9488)),
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'Taken: $taken doses',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: const Color(0xFF94A3B8),
            ),
          ),
          Text(
            'Remaining: $remaining dose',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: const Color(0xFF94A3B8),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '${(percentage * 100).toInt()}%',
            style: GoogleFonts.poppins(
              fontSize: 32.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          Text(
            "Today's Goal",
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;

  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeW = 10.0;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFE2E8F0).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );

    // Teal progress arc
    final progressPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: [Color(0xFF0D9488), Color(0xFF5EEAD4)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );

    // Coral accent dot at end
    if (progress > 0) {
      final endAngle = -pi / 2 + 2 * pi * progress;
      final dotX = center.dx + radius * cos(endAngle);
      final dotY = center.dy + radius * sin(endAngle);
      canvas.drawCircle(
        Offset(dotX, dotY),
        6,
        Paint()..color = const Color(0xFFFF6B6B),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}
