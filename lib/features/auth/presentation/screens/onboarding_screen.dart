import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  static final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      illustration: const _HeartMonitorIllustration(),
      tag: '❤️ Health Monitoring',
      title: 'Track Your\nHealth Vitals',
      subtitle:
          'Monitor heart rate, blood pressure, and more — all in one place. Stay informed about your health journey.',
    ),
    _OnboardingPage(
      illustration: const _CaregiverIllustration(),
      tag: '🤝 Caregiver Connect',
      title: 'Stay Connected\nWith Care',
      subtitle:
          'Seamlessly sync with your caregivers and doctors. Share updates, receive reminders, and never miss a beat.',
    ),
    _OnboardingPage(
      illustration: const _MedicationIllustration(),
      tag: '💊 Smart Reminders',
      title: 'Never Miss\nA Medication',
      subtitle:
          'Get timely reminders for medications, appointments, and health check-ups. Your wellness, on schedule.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            /// --- Skip button ---
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(top: 12.h, right: 20.w),
                child: GestureDetector(
                  onTap: () => context.go('/login-option'),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            /// --- Pages ---
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _buildPage(_pages[i]),
              ),
            ),

            /// --- Bottom: Indicator + Button ---
            Padding(
              padding: EdgeInsets.only(
                left: 24.w,
                right: 24.w,
                bottom: 32.h,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      dotHeight: 8.h,
                      dotWidth: 10.w,
                      expansionFactor: 3,
                      spacing: 6.w,
                      dotColor: AppColors.primary.withValues(alpha: 0.2),
                      activeDotColor: AppColors.primary,
                    ),
                  ),
                  CustomButton(
                    text: _currentIndex == _pages.length - 1
                        ? 'Get Started'
                        : 'Next',
                    width: 170.w,
                    onPressed: () {
                      if (_currentIndex < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        context.go('/login-option');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage data) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          SizedBox(height: 16.h),

          /// --- Illustration ---
          SizedBox(
            height: 0.40.sh,
            child: data.illustration,
          ),
          SizedBox(height: 32.h),

          /// --- Tag chip ---
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(100.r),
            ),
            child: Text(
              data.tag,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryLight,
              ),
            ),
          ),
          SizedBox(height: 24.h),

          /// --- Title ---
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 34.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.15,
            ),
          ),
          SizedBox(height: 16.h),

          /// --- Subtitle ---
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              data.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data Model ─────────────────────────────────────────────────
class _OnboardingPage {
  final Widget illustration;
  final String tag;
  final String title;
  final String subtitle;

  const _OnboardingPage({
    required this.illustration,
    required this.tag,
    required this.title,
    required this.subtitle,
  });
}

// ═══════════════════════════════════════════════════════════════════
// PAGE 1: Heart Monitor — pulse line + heart + floating stat cards
// ═══════════════════════════════════════════════════════════════════
class _HeartMonitorIllustration extends StatelessWidget {
  const _HeartMonitorIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        /// Background circle
        Container(
          width: 280.w,
          height: 280.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primaryContainer,
                AppColors.primaryContainer.withValues(alpha: 0.3),
                Colors.transparent,
              ],
              stops: const [0.3, 0.7, 1.0],
            ),
          ),
        ),

        /// Pulse line
        Positioned(
          child: CustomPaint(
            size: Size(260.w, 120.h),
            painter: _PulseLinePainter(),
          ),
        ),

        /// Central heart icon
        Container(
          height: 80.w,
          width: 80.w,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.favorite_rounded,
            color: Colors.white,
            size: 40.w,
          ),
        ),

        /// Floating card: BPM
        Positioned(
          top: 20.h,
          right: 10.w,
          child: _FloatingCard(
            icon: Icons.monitor_heart_outlined,
            label: '72 BPM',
            color: AppColors.primary,
          ),
        ),

        /// Floating card: BP
        Positioned(
          bottom: 30.h,
          left: 5.w,
          child: _FloatingCard(
            icon: Icons.bloodtype_outlined,
            label: '120/80',
            color: AppColors.success,
          ),
        ),

        /// Floating card: SpO2
        Positioned(
          top: 40.h,
          left: 15.w,
          child: _FloatingCard(
            icon: Icons.air_rounded,
            label: '98% SpO₂',
            color: AppColors.info,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PAGE 2: Caregiver Connect — connected people network
// ═══════════════════════════════════════════════════════════════════
class _CaregiverIllustration extends StatelessWidget {
  const _CaregiverIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        /// Dashed connection lines
        CustomPaint(
          size: Size(280.w, 280.w),
          painter: _ConnectionLinesPainter(),
        ),

        /// Center: Patient
        _PersonAvatar(
          icon: Icons.person_rounded,
          color: AppColors.primary,
          size: 72,
          label: 'You',
        ),

        /// Top-right: Doctor
        Positioned(
          top: 15.h,
          right: 20.w,
          child: _PersonAvatar(
            icon: Icons.medical_services_rounded,
            color: AppColors.info,
            size: 56,
            label: 'Doctor',
          ),
        ),

        /// Bottom-left: Family
        Positioned(
          bottom: 25.h,
          left: 15.w,
          child: _PersonAvatar(
            icon: Icons.people_rounded,
            color: AppColors.success,
            size: 56,
            label: 'Family',
          ),
        ),

        /// Top-left: Nurse
        Positioned(
          top: 30.h,
          left: 30.w,
          child: _PersonAvatar(
            icon: Icons.health_and_safety_rounded,
            color: AppColors.warning,
            size: 48,
            label: 'Nurse',
          ),
        ),

        /// Bottom-right: Pharmacy
        Positioned(
          bottom: 20.h,
          right: 25.w,
          child: _PersonAvatar(
            icon: Icons.local_pharmacy_rounded,
            color: AppColors.accent,
            size: 48,
            label: 'Pharmacy',
          ),
        ),

        /// Sync badge
        Positioned(
          bottom: 85.h,
          right: 90.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sync_rounded, color: AppColors.primaryLight, size: 14.w),
                SizedBox(width: 4.w),
                Text(
                  'In Sync',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryLight,
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

// ═══════════════════════════════════════════════════════════════════
// PAGE 3: Medication — pill bottle + schedule cards
// ═══════════════════════════════════════════════════════════════════
class _MedicationIllustration extends StatelessWidget {
  const _MedicationIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        /// Background
        Container(
          width: 260.w,
          height: 260.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primaryContainer,
                AppColors.primaryContainer.withValues(alpha: 0.2),
                Colors.transparent,
              ],
              stops: const [0.3, 0.7, 1.0],
            ),
          ),
        ),

        /// Central pill/capsule icon
        Container(
          height: 88.w,
          width: 88.w,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.medication_rounded,
            color: Colors.white,
            size: 44.w,
          ),
        ),

        /// Schedule card: Morning
        Positioned(
          top: 10.h,
          right: 5.w,
          child: _ScheduleCard(
            time: '8:00 AM',
            label: 'Metformin',
            icon: Icons.wb_sunny_outlined,
            color: AppColors.warning,
          ),
        ),

        /// Schedule card: Afternoon
        Positioned(
          top: 20.h,
          left: 0,
          child: _ScheduleCard(
            time: '2:00 PM',
            label: 'Vitamin D',
            icon: Icons.wb_cloudy_outlined,
            color: AppColors.info,
          ),
        ),

        /// Schedule card: Night
        Positioned(
          bottom: 15.h,
          right: 15.w,
          child: _ScheduleCard(
            time: '9:00 PM',
            label: 'Amlodipine',
            icon: Icons.nightlight_outlined,
            color: AppColors.primaryDark,
          ),
        ),

        /// Check badge
        Positioned(
          bottom: 30.h,
          left: 25.w,
          child: Container(
            height: 44.w,
            width: 44.w,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.check_rounded, color: Colors.white, size: 24.w),
          ),
        ),

        /// Bell icon (reminder)
        Positioned(
          bottom: 80.h,
          left: 10.w,
          child: Container(
            height: 36.w,
            width: 36.w,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              color: AppColors.accent,
              size: 18.w,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Shared Components
// ═══════════════════════════════════════════════════════════════════

class _FloatingCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FloatingCard({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 32.w,
            width: 32.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 18.w),
          ),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonAvatar extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final String label;

  const _PersonAvatar({
    required this.icon,
    required this.color,
    required this.size,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: size.w,
          width: size.w,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Icon(icon, color: color, size: (size * 0.45).w),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final String time;
  final String label;
  final IconData icon;
  final Color color;

  const _ScheduleCard({
    required this.time,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 34.w,
            width: 34.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 18.w),
          ),
          SizedBox(width: 10.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Custom Painters
// ═══════════════════════════════════════════════════════════════════

class _PulseLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final w = size.width;
    final h = size.height;
    final mid = h / 2;

    path.moveTo(0, mid);
    path.lineTo(w * 0.25, mid);
    path.lineTo(w * 0.32, mid - h * 0.15);
    path.lineTo(w * 0.38, mid + h * 0.35);
    path.lineTo(w * 0.42, mid - h * 0.45);
    path.lineTo(w * 0.48, mid + h * 0.25);
    path.lineTo(w * 0.54, mid - h * 0.1);
    path.lineTo(w * 0.60, mid);
    path.lineTo(w, mid);

    canvas.drawPath(path, paint);

    // Brighter overlay for the peak
    final highlightPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final highlightPath = Path();
    highlightPath.moveTo(w * 0.32, mid - h * 0.15);
    highlightPath.lineTo(w * 0.38, mid + h * 0.35);
    highlightPath.lineTo(w * 0.42, mid - h * 0.45);
    highlightPath.lineTo(w * 0.48, mid + h * 0.25);
    highlightPath.lineTo(w * 0.54, mid - h * 0.1);

    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ConnectionLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Lines from center to each person position
    final targets = [
      Offset(size.width - 48, 43), // doctor
      Offset(43, size.height - 53), // family
      Offset(58, 58), // nurse
      Offset(size.width - 53, size.height - 48), // pharmacy
    ];

    for (final target in targets) {
      _drawDashedLine(canvas, Offset(cx, cy), target, paint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final dist = sqrt(dx * dx + dy * dy);
    const dashLen = 6.0;
    const gapLen = 6.0;
    final ux = dx / dist;
    final uy = dy / dist;

    double d = 0;
    while (d < dist) {
      final start = Offset(a.dx + ux * d, a.dy + uy * d);
      final end = Offset(
        a.dx + ux * min(d + dashLen, dist),
        a.dy + uy * min(d + dashLen, dist),
      );
      canvas.drawLine(start, end, paint);
      d += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
