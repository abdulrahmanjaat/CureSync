import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickActionsRow extends StatelessWidget {
  final VoidCallback? onMessageDoctor;
  final VoidCallback? onSchedule;
  final VoidCallback? onReports;

  const QuickActionsRow({
    super.key,
    this.onMessageDoctor,
    this.onSchedule,
    this.onReports,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionIcon(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Message\nDoctor',
          onTap: onMessageDoctor,
        ),
        _ActionIcon(
          icon: Icons.calendar_month_rounded,
          label: 'Schedule\nAppointment',
          onTap: onSchedule,
        ),
        _ActionIcon(
          icon: Icons.assignment_outlined,
          label: 'View\nReports',
          onTap: onReports,
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionIcon({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 50.w,
            width: 50.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(icon, size: 24.w, color: const Color(0xFF5EEAD4)),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
