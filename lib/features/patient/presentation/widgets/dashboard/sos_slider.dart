import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bento_card.dart';
import 'status_tag.dart';

class SosSlider extends StatefulWidget {
  final VoidCallback? onTriggered;

  const SosSlider({super.key, this.onTriggered});

  @override
  State<SosSlider> createState() => _SosSliderState();
}

class _SosSliderState extends State<SosSlider> {
  double _dragExtent = 0;
  bool _triggered = false;

  double get _maxDrag => 220.w;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.06),
      accentBorderColor: const Color(0xFFEF4444),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          /// Track
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chevron_right_rounded,
                    size: 18.w,
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                Icon(Icons.chevron_right_rounded,
                    size: 18.w,
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
                SizedBox(width: 8.w),
                Text(
                  'Slide for SOS Emergency',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEF4444).withValues(alpha: 0.6),
                  ),
                ),
                SizedBox(width: 8.w),
                const StatusTag(type: TagType.hold),
              ],
            ),
          ),

          /// Draggable thumb
          GestureDetector(
            onHorizontalDragUpdate: (d) {
              setState(() {
                _dragExtent = (_dragExtent + d.delta.dx).clamp(0.0, _maxDrag);
              });
              if (_dragExtent > _maxDrag * 0.85 && !_triggered) {
                _triggered = true;
                HapticFeedback.heavyImpact();
                widget.onTriggered?.call();
              }
            },
            onHorizontalDragEnd: (_) {
              setState(() {
                _dragExtent = 0;
                _triggered = false;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: Matrix4.translationValues(_dragExtent, 0, 0),
              height: 48.h,
              width: 48.w,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.emergency_rounded,
                  size: 24.w, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
