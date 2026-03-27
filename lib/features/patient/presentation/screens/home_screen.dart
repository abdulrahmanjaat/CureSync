import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/active_patient_provider.dart';
import '../widgets/dashboard/bento_card.dart';
import '../widgets/dashboard/adherence_ring_widget.dart';
import '../widgets/dashboard/smart_action_card.dart';
import '../widgets/dashboard/pill_timeline.dart';
import '../widgets/dashboard/vitals_bento.dart';
import '../widgets/dashboard/lifestyle_strip.dart';
import '../widgets/dashboard/sos_slider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final activeId = ref.watch(activePatientIdProvider);
    final firstName = (user?.displayName ?? 'User').split(' ').first;

    // Next medication
    String? nextMedName;
    String? nextMedTime;
    if (activeId != null) {
      ref.watch(medicationsStreamProvider(activeId)).whenData((meds) {
        final active = meds.where((m) => m.isActive).toList();
        if (active.isNotEmpty && active.first.reminderTimes.isNotEmpty) {
          nextMedName = active.first.name;
          nextMedTime = active.first.reminderTimes.first;
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFA),
      body: Stack(
        children: [
          /// ─── Faint teal mesh gradient at top-left ───
          Positioned(
            top: -80.h,
            left: -60.w,
            child: Container(
              height: 320.w,
              width: 320.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0D9488).withValues(alpha: 0.06),
                    const Color(0xFF0D9488).withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                  stops: const [0.2, 0.5, 1.0],
                ),
              ),
            ),
          ),

          /// ─── Content ───
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 100.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ═══ GREETING ═══
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          Text(
                            '$firstName 👋',
                            style: GoogleFonts.poppins(
                              fontSize: 26.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _HeaderIcon(
                            icon: Icons.notifications_none_rounded,
                            onTap: () => HapticFeedback.lightImpact(),
                          ),
                          SizedBox(width: 8.w),
                          _HeaderIcon(
                            icon: Icons.people_outline_rounded,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              context.push('/manage-patients');
                            },
                          ),
                        ],
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.08, end: 0, duration: 400.ms),

                  SizedBox(height: 22.h),

                  /// ═══ BENTO ROW: Adherence + Smart Action + Add Med ═══
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: const AdherenceRingWidget()
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 80.ms)
                            .scale(
                              begin: const Offset(0.96, 0.96),
                              duration: 400.ms,
                              delay: 80.ms,
                            ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            SmartActionCard(
                              medName: nextMedName,
                              time: nextMedTime,
                            )
                                .animate()
                                .fadeIn(duration: 400.ms, delay: 160.ms)
                                .scale(
                                  begin: const Offset(0.96, 0.96),
                                  duration: 400.ms,
                                  delay: 160.ms,
                                ),
                            SizedBox(height: 12.h),
                            BentoCard(
                              onTap: () {
                                if (activeId != null) {
                                  context.push('/patient/$activeId/add-med');
                                }
                              },
                              padding: EdgeInsets.all(14.w),
                              child: Column(
                                children: [
                                  Container(
                                    height: 40.w,
                                    width: 40.w,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0D9488)
                                          .withValues(alpha: 0.08),
                                      borderRadius:
                                          BorderRadius.circular(14.r),
                                    ),
                                    child: Icon(
                                      Icons.medication_rounded,
                                      size: 22.w,
                                      color: const Color(0xFF0D9488),
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    "Add Med'",
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    'Add Medication Form',
                                    style: GoogleFonts.inter(
                                      fontSize: 10.sp,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Container(
                                    height: 30.w,
                                    width: 30.w,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF6B6B),
                                      borderRadius:
                                          BorderRadius.circular(10.r),
                                    ),
                                    child: Icon(Icons.add_rounded,
                                        size: 18.w, color: Colors.white),
                                  ),
                                ],
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 400.ms, delay: 240.ms)
                                .scale(
                                  begin: const Offset(0.96, 0.96),
                                  duration: 400.ms,
                                  delay: 240.ms,
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  /// ═══ PILL TIMELINE ═══
                  const PillTimeline()
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 300.ms)
                      .scale(
                        begin: const Offset(0.96, 0.96),
                        duration: 400.ms,
                        delay: 300.ms,
                      ),

                  SizedBox(height: 16.h),

                  /// ═══ LIFESTYLE STRIP ═══
                  const LifestyleStrip()
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 360.ms),

                  SizedBox(height: 16.h),

                  /// ═══ VITALS ═══
                  const VitalsBento()
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 420.ms)
                      .scale(
                        begin: const Offset(0.96, 0.96),
                        duration: 400.ms,
                        delay: 420.ms,
                      ),

                  SizedBox(height: 16.h),

                  /// ═══ SOS ═══
                  SosSlider(
                    onTriggered: () {
                      // SOS action
                    },
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 480.ms),

                  SizedBox(height: 20.h),

                  /// ═══ QUICK ACTIONS ═══
                  Text(
                    'Quick Actions',
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 520.ms),
                  SizedBox(height: 12.h),

                  Row(
                    children: [
                      _QuickAction(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Message\nDoctor',
                        color: const Color(0xFF0D9488),
                        onTap: () => HapticFeedback.lightImpact(),
                      ),
                      SizedBox(width: 12.w),
                      _QuickAction(
                        icon: Icons.calendar_month_rounded,
                        label: 'Schedule\nAppointment',
                        color: const Color(0xFF0891B2),
                        onTap: () => HapticFeedback.lightImpact(),
                      ),
                      SizedBox(width: 12.w),
                      _QuickAction(
                        icon: Icons.assignment_outlined,
                        label: 'View\nReports',
                        color: const Color(0xFF7C3AED),
                        onTap: () => HapticFeedback.lightImpact(),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 560.ms),

                  SizedBox(height: 20.h),

                  /// ═══ CARE CIRCLE LINK ═══
                  BentoCard(
                    onTap: () => context.push('/manage-patients'),
                    padding: EdgeInsets.symmetric(
                        horizontal: 16.w, vertical: 14.h),
                    child: Row(
                      children: [
                        Container(
                          height: 36.w,
                          width: 36.w,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(Icons.people_rounded,
                              size: 20.w,
                              color: const Color(0xFF0D9488)),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'Patient / Caregiver Management',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            size: 20.w,
                            color: const Color(0xFF94A3B8)),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 600.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42.w,
        width: 42.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 22.w, color: const Color(0xFF64748B)),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BentoCard(
        onTap: onTap,
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 10.w),
        child: Column(
          children: [
            Container(
              height: 42.w,
              width: 42.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(icon, size: 22.w, color: color),
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
