import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../caregiver/data/models/assigned_patient_model.dart';
import '../../../caregiver/presentation/providers/caregiver_provider.dart';

// ─── Family Alert Model ───────────────────────────────────────────────────────

enum FamilyAlertType { sos, missedMed, allClear, noMeds }

class FamilyAlert {
  final String patientId;
  final String patientName;
  final FamilyAlertType type;
  final String message;
  final DateTime time;
  final AssignedPatientModel patient;

  const FamilyAlert({
    required this.patientId,
    required this.patientName,
    required this.type,
    required this.message,
    required this.time,
    required this.patient,
  });
}

// ─── Provider ────────────────────────────────────────────────────────────────

final familyAlertsProvider = Provider<List<FamilyAlert>>((ref) {
  final patients = ref.watch(assignedPatientsProvider).valueOrNull ?? [];
  final alerts = <FamilyAlert>[];

  for (final p in patients) {
    final live =
        ref.watch(patientLiveDataProvider(p.patientId)).valueOrNull;
    final medStatus = ref.watch(patientMedStatusProvider(p.patientId));
    final isSos = live?['isSosActive'] == true;

    if (isSos) {
      alerts.add(FamilyAlert(
        patientId: p.patientId,
        patientName: p.patientName,
        type: FamilyAlertType.sos,
        message: '${p.patientName} has triggered an SOS alert. Please check on them immediately.',
        time: DateTime.now(),
        patient: p,
      ));
    }

    switch (medStatus) {
      case MedStatus.overdue:
        alerts.add(FamilyAlert(
          patientId: p.patientId,
          patientName: p.patientName,
          type: FamilyAlertType.missedMed,
          message: '${p.patientName} has missed their scheduled medication.',
          time: DateTime.now(),
          patient: p,
        ));
      case MedStatus.allClear:
        alerts.add(FamilyAlert(
          patientId: p.patientId,
          patientName: p.patientName,
          type: FamilyAlertType.allClear,
          message: '${p.patientName} is on track with all medications today.',
          time: DateTime.now(),
          patient: p,
        ));
      case MedStatus.noMeds:
        alerts.add(FamilyAlert(
          patientId: p.patientId,
          patientName: p.patientName,
          type: FamilyAlertType.noMeds,
          message: 'No medications scheduled for ${p.patientName} today.',
          time: DateTime.now(),
          patient: p,
        ));
    }
  }

  // SOS first, then missed, then others
  alerts.sort((a, b) {
    final priority = {
      FamilyAlertType.sos: 0,
      FamilyAlertType.missedMed: 1,
      FamilyAlertType.noMeds: 2,
      FamilyAlertType.allClear: 3,
    };
    return (priority[a.type] ?? 9).compareTo(priority[b.type] ?? 9);
  });

  return alerts;
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class FamilyNotificationsScreen extends ConsumerWidget {
  const FamilyNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(familyAlertsProvider);
    final patients = ref.watch(assignedPatientsProvider).valueOrNull ?? [];

    final sosAlerts =
        alerts.where((a) => a.type == FamilyAlertType.sos).toList();
    final missedAlerts =
        alerts.where((a) => a.type == FamilyAlertType.missedMed).toList();
    final okAlerts = alerts
        .where((a) =>
            a.type == FamilyAlertType.allClear ||
            a.type == FamilyAlertType.noMeds)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _FamilyNotifHeader(
              patientCount: patients.length,
              sosCount: sosAlerts.length,
              missedCount: missedAlerts.length,
              onBack: () {
                HapticFeedback.lightImpact();
                context.pop();
              },
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 16.h)),

          // ── SOS Section ────────────────────────────────────────────────
          if (sosAlerts.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionLabel(
                icon: Icons.sos_rounded,
                label: 'Emergency Alerts',
                color: const Color(0xFFEF4444),
              ).animate().fadeIn(duration: 300.ms, delay: 80.ms),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _SosCard(alert: sosAlerts[i])
                      .animate()
                      .fadeIn(duration: 300.ms, delay: (i * 60).ms)
                      .slideY(
                          begin: 0.05,
                          end: 0,
                          duration: 300.ms,
                          delay: (i * 60).ms),
                  childCount: sosAlerts.length,
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 12.h)),
          ],

          // ── Missed Meds Section ────────────────────────────────────────
          if (missedAlerts.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionLabel(
                icon: Icons.alarm_off_rounded,
                label: 'Missed Medications',
                color: const Color(0xFFF97316),
              ).animate().fadeIn(duration: 300.ms, delay: 120.ms),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _FamilyAlertCard(alert: missedAlerts[i])
                      .animate()
                      .fadeIn(
                          duration: 300.ms, delay: (i * 50 + 80).ms)
                      .slideY(
                          begin: 0.05,
                          end: 0,
                          duration: 300.ms,
                          delay: (i * 50 + 80).ms),
                  childCount: missedAlerts.length,
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 12.h)),
          ],

          // ── All Good Section ───────────────────────────────────────────
          if (okAlerts.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionLabel(
                icon: Icons.favorite_rounded,
                label: 'Family Status',
                color: const Color(0xFF7C3AED),
              ).animate().fadeIn(duration: 300.ms, delay: 160.ms),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _FamilyAlertCard(alert: okAlerts[i])
                      .animate()
                      .fadeIn(
                          duration: 300.ms, delay: (i * 50 + 120).ms)
                      .slideY(
                          begin: 0.04,
                          end: 0,
                          duration: 300.ms,
                          delay: (i * 50 + 120).ms),
                  childCount: okAlerts.length,
                ),
              ),
            ),
          ],

          // ── Empty state ────────────────────────────────────────────────
          if (alerts.isEmpty)
            SliverFillRemaining(
              child: _EmptyFamily(hasPatients: patients.isNotEmpty),
            ),

          SliverToBoxAdapter(child: SizedBox(height: 100.h)),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _FamilyNotifHeader extends StatelessWidget {
  final int patientCount;
  final int sosCount;
  final int missedCount;
  final VoidCallback onBack;

  const _FamilyNotifHeader({
    required this.patientCount,
    required this.sosCount,
    required this.missedCount,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final allSafe = sosCount == 0 && missedCount == 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: sosCount > 0
              ? [const Color(0xFFEF4444), const Color(0xFF7C3AED)]
              : [const Color(0xFF7C3AED), const Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 22.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      height: 38.w,
                      width: 38.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16.w, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Family Care',
                          style: GoogleFonts.poppins(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '$patientCount ${patientCount == 1 ? 'member' : 'members'} monitored',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // Status banner
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 42.w,
                      width: 42.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        allSafe
                            ? Icons.favorite_rounded
                            : Icons.warning_amber_rounded,
                        size: 22.w,
                        color: allSafe
                            ? const Color(0xFF6EE7B7)
                            : const Color(0xFFFDE68A),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            allSafe
                                ? 'Everyone is doing great!'
                                : sosCount > 0
                                    ? '$sosCount emergency alert${sosCount > 1 ? 's' : ''}!'
                                    : '$missedCount missed medication${missedCount > 1 ? 's' : ''}',
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            allSafe
                                ? 'All medications are on track today.'
                                : 'Please check on your family members.',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: -0.06, end: 0, duration: 350.ms);
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
      child: Row(
        children: [
          Icon(icon, size: 15.w, color: color),
          SizedBox(width: 6.w),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SOS Card ─────────────────────────────────────────────────────────────────

class _SosCard extends StatelessWidget {
  final FamilyAlert alert;
  const _SosCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 48.w,
            width: 48.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(Icons.sos_rounded, size: 26.w, color: Colors.white),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 7.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        alert.patientName,
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Connected ${DateFormat('MMM d').format(alert.patient.connectedAt)}',
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  'Emergency SOS Active',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  alert.message,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Family Alert Card ────────────────────────────────────────────────────────

class _FamilyAlertCard extends StatelessWidget {
  final FamilyAlert alert;
  const _FamilyAlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label, bg) = switch (alert.type) {
      FamilyAlertType.missedMed => (
          Icons.alarm_off_rounded,
          const Color(0xFFF97316),
          'MISSED',
          const Color(0xFFFFF7ED),
        ),
      FamilyAlertType.allClear => (
          Icons.favorite_rounded,
          const Color(0xFF16A34A),
          'ON TRACK',
          const Color(0xFFF0FDF4),
        ),
      FamilyAlertType.noMeds => (
          Icons.medication_outlined,
          const Color(0xFF7C3AED),
          'NO MEDS',
          const Color(0xFFF5F3FF),
        ),
      _ => (
          Icons.info_outline_rounded,
          const Color(0xFF64748B),
          'INFO',
          Colors.white,
        ),
    };

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            height: 42.w,
            width: 42.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                alert.patientName.isNotEmpty
                    ? alert.patientName[0].toUpperCase()
                    : 'F',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.patientName,
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 7.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3.h),
                Text(
                  alert.message,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(Icons.link_rounded,
                        size: 11.w, color: const Color(0xFFCBD5E1)),
                    SizedBox(width: 4.w),
                    Text(
                      'Connected ${DateFormat('MMM d, y').format(alert.patient.connectedAt)}',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const Spacer(),
                    Icon(icon, size: 14.w, color: color),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyFamily extends StatelessWidget {
  final bool hasPatients;
  const _EmptyFamily({required this.hasPatients});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 72.w,
            width: 72.w,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasPatients
                  ? Icons.notifications_off_outlined
                  : Icons.people_outline_rounded,
              size: 34.w,
              color: const Color(0xFF7C3AED),
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            hasPatients
                ? 'No alerts right now'
                : 'No family members linked',
            style: GoogleFonts.poppins(
              fontSize: 15.sp,
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            hasPatients
                ? "All your family members are doing well!"
                : 'Link a family member from the home screen.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(
        begin: const Offset(0.9, 0.9), duration: 400.ms);
  }
}
