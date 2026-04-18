import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../patient/presentation/providers/patient_provider.dart';
import '../../../patient/presentation/providers/medication_provider.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

enum ManagerAlertType { sos, missedMed, upcomingMed, taken, system }

class ManagerAlert {
  final String id;
  final String patientName;
  final String patientId;
  final String title;
  final String body;
  final ManagerAlertType type;
  final DateTime time;

  const ManagerAlert({
    required this.id,
    required this.patientName,
    required this.patientId,
    required this.title,
    required this.body,
    required this.type,
    required this.time,
  });
}

// ── Provider ──────────────────────────────────────────────────────────────────

final managerAlertsProvider = Provider<List<ManagerAlert>>((ref) {
  final patients = ref.watch(patientsStreamProvider).valueOrNull ?? [];
  final alerts   = <ManagerAlert>[];

  for (final p in patients) {
    final pid = p.patientId;
    if (pid == null) continue;
    final entries = ref.watch(todayPillTimelineProvider(pid));

    for (final e in entries) {
      if (e.isTaken) {
        alerts.add(ManagerAlert(
          id: '${pid}_${e.medId}_taken',
          patientName: p.name,
          patientId: pid,
          title: 'Dose Taken',
          body: '${e.medName} at ${e.time}',
          type: ManagerAlertType.taken,
          time: DateTime.now(),
        ));
      } else {
        final parts   = e.rawTime.split(':');
        final h       = int.tryParse(parts[0]) ?? 0;
        final m       = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
        final doseTime = DateTime.now().copyWith(hour: h, minute: m, second: 0);
        final isPast  = doseTime.isBefore(DateTime.now());
        alerts.add(ManagerAlert(
          id: '${pid}_${e.medId}_${e.rawTime}',
          patientName: p.name,
          patientId: pid,
          title: isPast ? 'Missed Dose' : 'Upcoming Dose',
          body: '${e.medName} at ${e.time}',
          type: isPast ? ManagerAlertType.missedMed : ManagerAlertType.upcomingMed,
          time: doseTime,
        ));
      }
    }
  }

  alerts.sort((a, b) => b.time.compareTo(a.time));

  alerts.addAll([
    ManagerAlert(
      id: 'sys_sync',
      patientName: 'System',
      patientId: '',
      title: 'Data Synced',
      body: 'All patient records are up to date.',
      type: ManagerAlertType.system,
      time: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ]);

  return alerts;
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ManagerNotificationsScreen extends ConsumerStatefulWidget {
  const ManagerNotificationsScreen({super.key});

  @override
  ConsumerState<ManagerNotificationsScreen> createState() =>
      _ManagerNotificationsScreenState();
}

class _ManagerNotificationsScreenState
    extends ConsumerState<ManagerNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String? _selectedPatientId; // null = All patients

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allAlerts  = ref.watch(managerAlertsProvider);
    final patientsAsync = ref.watch(patientsStreamProvider);
    final patients   = patientsAsync.valueOrNull ?? [];

    // Apply patient filter
    final alerts = _selectedPatientId == null
        ? allAlerts
        : allAlerts
            .where((a) => a.patientId == _selectedPatientId)
            .toList();

    final missed   = alerts.where((a) => a.type == ManagerAlertType.missedMed).toList();
    final upcoming = alerts.where((a) => a.type == ManagerAlertType.upcomingMed).toList();
    final activity = alerts
        .where((a) =>
            a.type == ManagerAlertType.taken ||
            a.type == ManagerAlertType.system)
        .toList();

    // Unfiltered counts for header stats
    final allMissed   = allAlerts.where((a) => a.type == ManagerAlertType.missedMed).length;
    final allUpcoming = allAlerts.where((a) => a.type == ManagerAlertType.upcomingMed).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F7),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          _Header(
            totalPatients: patients.length,
            missedCount:   allMissed,
            upcomingCount: allUpcoming,
            onBack: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
          ),

          SizedBox(height: 12.h),

          // ── Patient filter strip ─────────────────────────────────────────
          if (patients.isNotEmpty)
            SizedBox(
              height: 52.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: patients.length + 1, // +1 for "All" chip
                itemBuilder: (context, i) {
                  if (i == 0) {
                    // "All" chip
                    final isSelected = _selectedPatientId == null;
                    return _PatientFilterChip(
                      label: 'All',
                      initial: '✦',
                      isSelected: isSelected,
                      hasAlert: false,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedPatientId = null);
                      },
                    )
                        .animate()
                        .fadeIn(duration: 250.ms);
                  }
                  final p        = patients[i - 1];
                  final isSelected = _selectedPatientId == p.patientId;
                  final hasAlert = allAlerts.any((a) =>
                      a.patientId == p.patientId &&
                      a.type == ManagerAlertType.missedMed);
                  return _PatientFilterChip(
                    label: p.name.split(' ').first,
                    initial: p.name.isNotEmpty ? p.name[0].toUpperCase() : 'P',
                    isSelected: isSelected,
                    hasAlert: hasAlert,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedPatientId =
                          isSelected ? null : p.patientId);
                    },
                  )
                      .animate()
                      .fadeIn(duration: 250.ms, delay: (i * 40).ms)
                      .slideX(begin: 0.1, end: 0, duration: 250.ms, delay: (i * 40).ms);
                },
              ),
            ),

          if (patients.isNotEmpty) SizedBox(height: 12.h),

          // ── Tab bar ──────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Container(
              height: 48.h,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4E6),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: TabBar(
                controller: _tabs,
                indicator: BoxDecoration(
                  color: const Color(0xFFDB2777),
                  borderRadius: BorderRadius.circular(13.r),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: GoogleFonts.inter(
                    fontSize: 12.sp, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.inter(
                    fontSize: 12.sp, fontWeight: FontWeight.w500),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF9F1239),
                tabs: [
                  _TabLabel(label: 'Missed',   count: missed.length),
                  _TabLabel(label: 'Upcoming', count: upcoming.length),
                  _TabLabel(label: 'Activity', count: activity.length),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 80.ms),

          SizedBox(height: 12.h),

          // ── Alert lists ──────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _AlertList(
                  items: missed,
                  emptyLabel: 'No missed doses today',
                  emptyIcon: Icons.check_circle_outline_rounded,
                  emptyColor: const Color(0xFF16A34A),
                  emptySubtitle: 'All patients are on track',
                ),
                _AlertList(
                  items: upcoming,
                  emptyLabel: 'No upcoming doses',
                  emptyIcon: Icons.alarm_off_rounded,
                  emptyColor: const Color(0xFF94A3B8),
                  emptySubtitle: 'Nothing scheduled for now',
                ),
                _AlertList(
                  items: activity,
                  emptyLabel: 'No activity yet',
                  emptyIcon: Icons.info_outline_rounded,
                  emptyColor: const Color(0xFF7C3AED),
                  emptySubtitle: 'Taken doses will appear here',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int totalPatients;
  final int missedCount;
  final int upcomingCount;
  final VoidCallback onBack;

  const _Header({
    required this.totalPatients,
    required this.missedCount,
    required this.upcomingCount,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8356D), Color(0xFF9D174D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          // Decorative blobs
          Positioned(
            top: -20.h, right: -30.w,
            child: Container(
              height: 150.w, width: 150.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            top: 30.h, right: 10.w,
            child: Container(
              height: 70.w, width: 70.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top row ──────────────────────────────────────────────
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onBack,
                        child: Container(
                          height: 40.w,
                          width: 40.w,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(13.r),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 17.w,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Patient Alerts',
                              style: GoogleFonts.poppins(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "Today's management overview",
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Patient count pill
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 7.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_rounded,
                                size: 14.w, color: Colors.white),
                            SizedBox(width: 5.w),
                            Text(
                              '$totalPatients',
                              style: GoogleFonts.poppins(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 18.h),

                  // ── Equal-width stat bubbles ──────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _StatBubble(
                          icon: Icons.alarm_off_rounded,
                          value: '$missedCount',
                          label: 'Missed',
                          highlight: missedCount > 0,
                          highlightColor: const Color(0xFFFF8FA3),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _StatBubble(
                          icon: Icons.alarm_rounded,
                          value: '$upcomingCount',
                          label: 'Upcoming',
                          highlight: false,
                          highlightColor: const Color(0xFFFDE68A),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _StatBubble(
                          icon: missedCount == 0
                              ? Icons.verified_rounded
                              : Icons.warning_amber_rounded,
                          value: missedCount == 0 ? 'OK' : '!',
                          label: missedCount == 0 ? 'All Clear' : 'Alert',
                          highlight: missedCount > 0,
                          highlightColor: const Color(0xFFFBBF24),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: -0.05, end: 0, duration: 350.ms);
  }
}

// ── Equal-width stat bubble ───────────────────────────────────────────────────

class _StatBubble extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool highlight;
  final Color highlightColor;

  const _StatBubble({
    required this.icon,
    required this.value,
    required this.label,
    required this.highlight,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
      decoration: BoxDecoration(
        color: highlight
            ? highlightColor.withValues(alpha: 0.20)
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: highlight
              ? highlightColor.withValues(alpha: 0.40)
              : Colors.white.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 13.w,
                  color: highlight
                      ? highlightColor
                      : Colors.white.withValues(alpha: 0.80)),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: highlight ? highlightColor : Colors.white,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Patient filter chip ───────────────────────────────────────────────────────

class _PatientFilterChip extends StatelessWidget {
  final String label;
  final String initial;
  final bool isSelected;
  final bool hasAlert;
  final VoidCallback onTap;

  const _PatientFilterChip({
    required this.label,
    required this.initial,
    required this.isSelected,
    required this.hasAlert,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFDB2777)
              : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFDB2777)
                : hasAlert
                    ? const Color(0xFFEF4444).withValues(alpha: 0.40)
                    : const Color(0xFFE2E8F0),
            width: isSelected ? 0 : (hasAlert ? 1.5 : 1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFDB2777).withValues(alpha: 0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar circle
            Container(
              height: 24.w,
              width: 24.w,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFFDB2777).withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFFDB2777),
                  ),
                ),
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            if (hasAlert && !isSelected) ...[
              SizedBox(width: 5.w),
              Container(
                width: 7.w,
                height: 7.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Tab label with optional badge ─────────────────────────────────────────────

class _TabLabel extends StatelessWidget {
  final String label;
  final int count;
  const _TabLabel({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(label, overflow: TextOverflow.ellipsis),
          ),
          if (count > 0) ...[
            SizedBox(width: 5.w),
            Container(
              height: 17.w,
              constraints: BoxConstraints(minWidth: 17.w),
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(9.r),
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Alert list ────────────────────────────────────────────────────────────────

class _AlertList extends StatelessWidget {
  final List<ManagerAlert> items;
  final String emptyLabel;
  final String emptySubtitle;
  final IconData emptyIcon;
  final Color emptyColor;

  const _AlertList({
    required this.items,
    required this.emptyLabel,
    required this.emptySubtitle,
    required this.emptyIcon,
    required this.emptyColor,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 72.w,
              width: 72.w,
              decoration: BoxDecoration(
                color: emptyColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(emptyIcon, size: 34.w, color: emptyColor),
            ),
            SizedBox(height: 14.h),
            Text(
              emptyLabel,
              style: GoogleFonts.poppins(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              emptySubtitle,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms);
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 120.h),
      itemCount: items.length,
      itemBuilder: (context, i) {
        return _AlertCard(alert: items[i])
            .animate()
            .fadeIn(duration: 280.ms, delay: (i * 40).ms)
            .slideY(begin: 0.04, end: 0, duration: 280.ms, delay: (i * 40).ms);
      },
    );
  }
}

// ── Alert card ────────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final ManagerAlert alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (alert.type) {
      ManagerAlertType.sos => (
          Icons.sos_rounded,
          const Color(0xFFEF4444),
          'SOS',
        ),
      ManagerAlertType.missedMed => (
          Icons.alarm_off_rounded,
          const Color(0xFFEF4444),
          'MISSED',
        ),
      ManagerAlertType.upcomingMed => (
          Icons.alarm_rounded,
          const Color(0xFF0891B2),
          'UPCOMING',
        ),
      ManagerAlertType.taken => (
          Icons.check_circle_outline_rounded,
          const Color(0xFF16A34A),
          'TAKEN',
        ),
      ManagerAlertType.system => (
          Icons.info_outline_rounded,
          const Color(0xFF7C3AED),
          'SYSTEM',
        ),
    };

    final timeStr = _relativeTime(alert.time);
    final isUrgent = alert.type == ManagerAlertType.missedMed ||
        alert.type == ManagerAlertType.sos;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isUrgent
              ? color.withValues(alpha: 0.20)
              : const Color(0xFFF1F5F9),
          width: isUrgent ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isUrgent
                ? color.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              height: 52.w,
              width: 52.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(icon, size: 26.w, color: color),
            ),

            SizedBox(width: 14.w),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: patient badge + time
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (alert.patientName != 'System') ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 9.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDB2777).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            alert.patientName,
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFDB2777),
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                      ],
                      // Type badge
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 7.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6.r),
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
                      const Spacer(),
                      Text(
                        timeStr,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 7.h),

                  // Title
                  Text(
                    alert.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Body
                  Text(
                    alert.body,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),

                  // Action button for urgent alerts
                  if (isUrgent && alert.patientId.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/manager/patient/${alert.patientId}');
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 7.h),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                              color: color.withValues(alpha: 0.20), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.open_in_new_rounded,
                                size: 13.w, color: color),
                            SizedBox(width: 5.w),
                            Text(
                              'View Patient Dashboard',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
