import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';

class CureSyncLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isWhite;

  const CureSyncLogo({
    super.key,
    this.size = 64,
    this.showText = true,
    this.isWhite = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(size.w, size.w),
          painter: _CureSyncLogoPainter(isWhite: isWhite),
        ),
        if (showText) ...[
          SizedBox(height: (size * 0.15).h),
          _buildLogoText(),
        ],
      ],
    );
  }

  Widget _buildLogoText() {
    final baseColor = isWhite ? Colors.white : AppColors.textPrimary;
    final accentColor = isWhite
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.primary;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Cure',
            style: TextStyle(
              fontSize: (size * 0.38).sp,
              fontWeight: FontWeight.w800,
              color: baseColor,
              letterSpacing: -0.5,
            ),
          ),
          TextSpan(
            text: 'Sync',
            style: TextStyle(
              fontSize: (size * 0.38).sp,
              fontWeight: FontWeight.w400,
              color: accentColor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CureSyncLogoPainter extends CustomPainter {
  final bool isWhite;

  _CureSyncLogoPainter({required this.isWhite});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final cx = s / 2;
    final cy = s / 2;

    // ─── Colors ─────────────────────────────────────
    final teal = isWhite ? Colors.white : const Color(0xFF0D9488);
    final tealLight = isWhite
        ? Colors.white.withValues(alpha: 0.6)
        : const Color(0xFF14B8A6);
    final coral = isWhite
        ? Colors.white.withValues(alpha: 0.85)
        : const Color(0xFFFF6B6B);
    final bgFill = isWhite
        ? Colors.white.withValues(alpha: 0.15)
        : const Color(0xFF0D9488).withValues(alpha: 0.08);

    // ─── 1. Rounded square background ───────────────
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, s, s),
      Radius.circular(s * 0.26),
    );
    canvas.drawRRect(bgRect, Paint()..color = bgFill);

    // ─── 2. Shield / Heart-shield shape ─────────────
    final shieldPath = Path();
    final shieldTop = cy - s * 0.30;
    final shieldBottom = cy + s * 0.32;
    final shieldLeft = cx - s * 0.28;
    final shieldRight = cx + s * 0.28;

    // Top center dip (heart shape top)
    shieldPath.moveTo(cx, shieldTop + s * 0.08);
    // Left curve up
    shieldPath.cubicTo(
      cx - s * 0.05, shieldTop,
      shieldLeft + s * 0.05, shieldTop - s * 0.02,
      shieldLeft, shieldTop + s * 0.12,
    );
    // Left side down
    shieldPath.cubicTo(
      shieldLeft - s * 0.02, cy + s * 0.05,
      cx - s * 0.08, shieldBottom - s * 0.08,
      cx, shieldBottom,
    );
    // Right side up (mirror)
    shieldPath.cubicTo(
      cx + s * 0.08, shieldBottom - s * 0.08,
      shieldRight + s * 0.02, cy + s * 0.05,
      shieldRight, shieldTop + s * 0.12,
    );
    // Right curve to top
    shieldPath.cubicTo(
      shieldRight - s * 0.05, shieldTop - s * 0.02,
      cx + s * 0.05, shieldTop,
      cx, shieldTop + s * 0.08,
    );
    shieldPath.close();

    // Shield gradient fill
    final shieldPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [teal, tealLight],
      ).createShader(Rect.fromLTWH(0, 0, s, s));

    canvas.drawPath(shieldPath, shieldPaint);

    // ─── 3. White cross (negative space) ────────────
    final crossColor = isWhite ? const Color(0xFF0D9488) : Colors.white;
    final crossPaint = Paint()..color = crossColor;
    final crossW = s * 0.075;
    final crossH = s * 0.22;
    final crossR = Radius.circular(crossW);

    // Vertical
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: crossW, height: crossH),
        crossR,
      ),
      crossPaint,
    );
    // Horizontal
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: crossH, height: crossW),
        crossR,
      ),
      crossPaint,
    );

    // ─── 4. Sync orbit ring ─────────────────────────
    final orbitPaint = Paint()
      ..color = coral
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.025
      ..strokeCap = StrokeCap.round;

    final orbitRadius = s * 0.38;

    // Tilted ellipse — draw a partial arc
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-pi / 7); // tilt

    final orbitRect = Rect.fromCircle(
      center: Offset.zero,
      radius: orbitRadius,
    );

    // Main arc (roughly 240 degrees)
    canvas.drawArc(orbitRect, -pi * 0.15, pi * 1.35, false, orbitPaint);

    // ─── 5. Orbit dot (electron-style) ──────────────
    final dotAngle = -pi * 0.15 + pi * 1.35; // end of the arc
    final dotX = orbitRadius * cos(dotAngle);
    final dotY = orbitRadius * sin(dotAngle);

    canvas.drawCircle(
      Offset(dotX, dotY),
      s * 0.04,
      Paint()..color = coral,
    );

    // Small dot at arc start
    final startAngle = -pi * 0.15;
    final startX = orbitRadius * cos(startAngle);
    final startY = orbitRadius * sin(startAngle);
    canvas.drawCircle(
      Offset(startX, startY),
      s * 0.025,
      Paint()..color = coral.withValues(alpha: 0.5),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
