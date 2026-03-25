import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/active_patient_provider.dart';
import '../widgets/dashboard/glass_card.dart';
import '../widgets/dashboard/adherence_ring_widget.dart';
import '../widgets/dashboard/smart_action_card.dart';
import '../widgets/dashboard/pill_timeline.dart';
import '../widgets/dashboard/vitals_bento.dart';
import '../widgets/dashboard/wellness_strip.dart';
import '../widgets/dashboard/quick_actions_row.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final activeId = ref.watch(activePatientIdProvider);
    final firstName = (user?.displayName ?? 'User').split(' ').first;

    // Get next medication for the active patient
    String? nextMedName;
    String? nextMedTime;
    if (activeId != null) {
      final medsAsync = ref.watch(medicationsStreamProvider(activeId));
      medsAsync.whenData((meds) {
        final active = meds.where((m) => m.isActive).toList();
        if (active.isNotEmpty && active.first.reminderTimes.isNotEmpty) {
          nextMedName = active.first.name;
          nextMedTime = active.first.reminderTimes.first;
        }
      });
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B1F1E),
              Color(0xFF0F2928),
              Color(0xFF122D2B),
              Color(0xFF0B1F1E),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ═══ GREETING ═══
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                          Text(
                            '$firstName 👋',
                            style: GoogleFonts.poppins(
                              fontSize: 26.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        height: 42.w,
                        width: 42.w,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Icon(Icons.notifications_none_rounded,
                            size: 22.w,
                            color: const Color(0xFF5EEAD4)),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.1, end: 0, duration: 400.ms),

                SizedBox(height: 20.h),

                /// ═══ BENTO GRID: Adherence + Smart Action + Add Med ═══
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Left: Adherence ring
                    Expanded(
                      flex: 3,
                      child: const AdherenceRingWidget()
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 100.ms)
                          .scale(
                            begin: const Offset(0.95, 0.95),
                            duration: 400.ms,
                            delay: 100.ms,
                          ),
                    ),
                    SizedBox(width: 12.w),

                    /// Right column
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          SmartActionCard(
                            medName: nextMedName,
                            time: nextMedTime,
                          )
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 200.ms)
                              .scale(
                                begin: const Offset(0.95, 0.95),
                                duration: 400.ms,
                                delay: 200.ms,
                              ),
                          SizedBox(height: 12.h),
                          GlassCard(
                            onTap: () {
                              if (activeId != null) {
                                context
                                    .push('/patient/$activeId/add-med');
                              }
                            },
                            padding: EdgeInsets.all(14.w),
                            child: Column(
                              children: [
                                Icon(Icons.medication_rounded,
                                    size: 28.w,
                                    color: const Color(0xFF5EEAD4)),
                                SizedBox(height: 6.h),
                                Text(
                                  "Add Med'",
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                Text(
                                  'Add Medication\nForm',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 9.sp,
                                    color:
                                        Colors.white.withValues(alpha: 0.4),
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Container(
                                  height: 28.w,
                                  width: 28.w,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF6B6B),
                                    borderRadius:
                                        BorderRadius.circular(8.r),
                                  ),
                                  child: Icon(Icons.add_rounded,
                                      size: 18.w, color: Colors.white),
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 300.ms)
                              .scale(
                                begin: const Offset(0.95, 0.95),
                                duration: 400.ms,
                                delay: 300.ms,
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
                    .fadeIn(duration: 400.ms, delay: 350.ms)
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      duration: 400.ms,
                      delay: 350.ms,
                    ),

                SizedBox(height: 16.h),

                /// ═══ WELLNESS STRIP ═══
                const WellnessStrip()
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 400.ms),

                SizedBox(height: 16.h),

                /// ═══ VITALS ═══
                const VitalsBento()
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 450.ms)
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      duration: 400.ms,
                      delay: 450.ms,
                    ),

                SizedBox(height: 20.h),

                /// ═══ QUICK ACTIONS ═══
                const QuickActionsRow()
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 500.ms),

                SizedBox(height: 24.h),

                /// ═══ PATIENT/CAREGIVER MANAGEMENT LINK ═══
                GlassCard(
                  onTap: () => context.push('/manage-patients'),
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  child: Row(
                    children: [
                      Icon(Icons.people_rounded,
                          size: 22.w, color: const Color(0xFF5EEAD4)),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'Patient/Caregiver Management',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: 20.w,
                          color: Colors.white.withValues(alpha: 0.4)),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 550.ms),

                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
