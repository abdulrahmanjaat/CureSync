import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'glass_card.dart';

class WellnessStrip extends StatelessWidget {
  const WellnessStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _WellnessTile(
          icon: Icons.nightlight_round,
          label: 'Sleep',
          value: '7h 15m',
          color: const Color(0xFF7C3AED),
        ),
        SizedBox(width: 10.w),
        _WellnessTile(
          icon: Icons.directions_walk_rounded,
          label: 'Steps',
          value: '8,432',
          color: const Color(0xFF0D9488),
        ),
        SizedBox(width: 10.w),
        _WellnessTile(
          icon: Icons.water_drop_outlined,
          label: 'Water',
          value: '6 cups',
          color: const Color(0xFF0891B2),
        ),
      ],
    );
  }
}

class _WellnessTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _WellnessTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
        borderRadius: 18,
        child: Column(
          children: [
            Icon(icon, size: 22.w, color: color),
            SizedBox(height: 6.h),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
