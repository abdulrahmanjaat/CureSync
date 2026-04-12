import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../features/caregiver/presentation/providers/caregiver_provider.dart';

/// Schedule Screen — shared between Family and Pro-Caregiver.
/// Shows a chronological daily duty list (all meds across all assigned patients).
class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duties = ref.watch(dailyDutyListProvider);
    final now = DateTime.now();

    // Group by hour bucket for visual timeline
    final upcoming = duties
        .where((d) => !d.isTaken)
        .toList();
    final done = duties
        .where((d) => d.isTaken)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFA),
      body: Stack(
        children: [
          // Ambient gradient
          Positioned(
            top: -60.h,
            right: -50.w,
            child: Container(
              height: 240.w,
              width: 240.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF0D9488).withValues(alpha: 0.06),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          SafeArea(
            child: duties.isEmpty
                ? _EmptyState()
                : CustomScrollView(
                    slivers: [
                      // Header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                              20.w, 20.h, 20.w, 0),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Today\'s Schedule',
                                      style: GoogleFonts.poppins(
                                        fontSize: 22.sp,
                                        fontWeight: FontWeight.w800,
                                        color:
                                            const Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      DateFormat('EEEE, MMMM d')
                                          .format(now),
                                      style: GoogleFonts.inter(
                                        fontSize: 13.sp,
                                        color:
                                            const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Summary badge
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D9488)
                                      .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  '${done.length}/${duties.length} done',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0D9488),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SliverToBoxAdapter(
                          child: SizedBox(height: 20.h)),

                      // Upcoming duties
                      if (upcoming.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: _SectionLabel(
                            label: 'Upcoming',
                            icon: Icons.access_time_rounded,
                            color: const Color(0xFF0D9488),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.w),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) => _DutyRow(
                                duty: upcoming[i],
                                isLast: i == upcoming.length - 1,
                              ),
                              childCount: upcoming.length,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                            child: SizedBox(height: 20.h)),
                      ],

                      // Completed duties
                      if (done.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: _SectionLabel(
                            label: 'Completed',
                            icon: Icons.check_circle_rounded,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.w),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) => _DutyRow(
                                duty: done[i],
                                isLast: i == done.length - 1,
                              ),
                              childCount: done.length,
                            ),
                          ),
                        ),
                      ],

                      SliverToBoxAdapter(
                          child: SizedBox(height: 120.h)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SectionLabel({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(20.w, 0, 20.w, 10.h),
      child: Row(
        children: [
          Icon(icon, size: 14.w, color: color),
          SizedBox(width: 6.w),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Duty Row ─────────────────────────────────────────────────────────────────

class _DutyRow extends StatelessWidget {
  final DutyItem duty;
  final bool isLast;

  const _DutyRow({required this.duty, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final nowMins = now.hour * 60 + now.minute;
    final isNow =
        !duty.isTaken && (duty.sortKey - nowMins).abs() <= 30;
    final isPast =
        !duty.isTaken && duty.sortKey < nowMins;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 56.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(height: 14.h),
                Text(
                  duty.time,
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: isNow
                        ? const Color(0xFF0D9488)
                        : isPast
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 12.w),

          // Connector line + dot
          Column(
            children: [
              Container(
                height: 12.h,
                width: 2,
                color: const Color(0xFFE2E8F0),
              ),
              Container(
                height: 12.w,
                width: 12.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: duty.isTaken
                      ? const Color(0xFF16A34A)
                      : isNow
                          ? const Color(0xFF0D9488)
                          : isPast
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFCBD5E1),
                ),
                child: duty.isTaken
                    ? Icon(Icons.check_rounded,
                        size: 8.w, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Container(
                  height: 40.h,
                  width: 2,
                  color: const Color(0xFFE2E8F0),
                ),
            ],
          ),

          SizedBox(width: 12.w),

          // Card
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isNow
                      ? const Color(0xFF0D9488).withValues(alpha: 0.3)
                      : isPast && !duty.isTaken
                          ? const Color(0xFFEF4444)
                              .withValues(alpha: 0.2)
                          : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          duty.medName,
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: duty.isTaken
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF0F172A),
                            decoration: duty.isTaken
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          duty.patientName,
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: const Color(0xFF94A3B8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isNow)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'Now',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (isPast && !duty.isTaken)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'Missed',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 80.w,
            width: 80.w,
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              size: 36.w,
              color: const Color(0xFF0D9488),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'No schedule yet',
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Link a patient to see their\nmedication schedule here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: const Color(0xFF94A3B8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
