import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/appointment_model.dart';
import '../providers/doctor_provider.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_prescriptions_screen.dart';

// ── Brand palette ─────────────────────────────────────────────────────────────
const Color _indigo  = Color(0xFF4338CA);
const Color _indigoL = Color(0xFF6366F1);
const Color _bg      = Color(0xFFF5F5FF);

// ─── Helpers ──────────────────────────────────────────────────────────────────
String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

String _formatTime(DateTime dt) {
  final h   = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final min = dt.minute.toString().padLeft(2, '0');
  final ap  = dt.hour >= 12 ? 'PM' : 'AM';
  return '$h:$min $ap';
}

Color _statusColor(AppointmentStatus s) => switch (s) {
      AppointmentStatus.confirmed => const Color(0xFF0D9488),
      AppointmentStatus.completed => const Color(0xFF16A34A),
      AppointmentStatus.cancelled => const Color(0xFFEF4444),
      AppointmentStatus.noShow    => const Color(0xFF94A3B8),
      _                           => const Color(0xFFF59E0B),
    };

// ════════════════════════════════════════════════════════════════════════════
// Screen
// ════════════════════════════════════════════════════════════════════════════
class DoctorDashboardScreen extends ConsumerWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser    = ref.watch(authStateProvider).valueOrNull;
    final firstName   = (authUser?.displayName ?? 'Doctor').split(' ').first;
    final photoUrl    = authUser?.photoURL;
    final stats       = ref.watch(doctorStatsProvider);
    final todayAppts  = ref.watch(todayAppointmentsProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero Header ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _HeroHeader(
              firstName: firstName,
              photoUrl:  photoUrl,
              stats:     stats,
            ),
          ),

          // ── Quick Actions ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 0),
              child: _QuickActions(context: context),
            ).animate().fadeIn(duration: 300.ms, delay: 60.ms),
          ),

          // ── Today's Schedule ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 22.h, 16.w, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionTitle(
                    icon: Icons.today_rounded,
                    label: "Today's Schedule",
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const DoctorAppointmentsScreen()),
                    ),
                    child: Text(
                      'View all',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: _indigoL,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 280.ms, delay: 80.ms),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 12.h)),

          if (todayAppts.isEmpty)
            SliverToBoxAdapter(
              child: _EmptySchedule()
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 100.ms),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                  child: _AppointmentCard(appt: todayAppts[i])
                      .animate()
                      .fadeIn(duration: 280.ms, delay: (i * 60).ms)
                      .slideY(
                          begin: 0.04,
                          end: 0,
                          duration: 280.ms,
                          delay: (i * 60).ms),
                ),
                childCount: todayAppts.length,
              ),
            ),

          SliverToBoxAdapter(child: SizedBox(height: 120.h)),
        ],
      ),
    );
  }
}

// ─── Hero Header ──────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final String firstName;
  final String? photoUrl;
  final DoctorStats stats;

  const _HeroHeader({
    required this.firstName,
    required this.photoUrl,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_indigo, _indigoL],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 26.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: greeting + avatar + notifications
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_greeting()},',
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Dr. $firstName',
                          style: GoogleFonts.poppins(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Notification bell
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/notifications');
                    },
                    child: Container(
                      height: 42.w,
                      width: 42.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(13.r),
                      ),
                      child: Icon(
                        Icons.notifications_rounded,
                        size: 22.w,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  // Profile avatar
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      height: 42.w,
                      width: 42.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(13.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: photoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: Image.network(
                                photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _avatarPlaceholder(),
                              ),
                            )
                          : _avatarPlaceholder(),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 22.h),

              // Stats bento row
              Row(
                children: [
                  _StatCard(
                    icon: Icons.calendar_today_rounded,
                    value: stats.todayTotal.toString(),
                    label: "Today's Appts",
                    flex: 2,
                  ),
                  SizedBox(width: 10.w),
                  _StatCard(
                    icon: Icons.people_alt_rounded,
                    value: stats.totalPatients.toString(),
                    label: 'Patients',
                    flex: 1,
                  ),
                  SizedBox(width: 10.w),
                  _StatCard(
                    icon: Icons.receipt_long_rounded,
                    value: stats.activePrescriptions.toString(),
                    label: 'Active Rxs',
                    flex: 1,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: -0.04, end: 0, duration: 350.ms);
  }

  Widget _avatarPlaceholder() => Center(
        child: Icon(
          Icons.person_rounded,
          size: 22.w,
          color: Colors.white,
        ),
      );
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final int flex;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18.w, color: Colors.white.withValues(alpha: 0.9)),
            SizedBox(height: 6.h),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: Colors.white.withValues(alpha: 0.75),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final BuildContext context;
  const _QuickActions({required this.context});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.bolt_rounded,
          label: 'Quick Actions',
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            _ActionTile(
              icon: Icons.edit_document,
              label: 'Write\nPrescription',
              color: _indigo,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const DoctorPrescriptionsScreen()),
              ),
            ),
            SizedBox(width: 12.w),
            _ActionTile(
              icon: Icons.calendar_month_rounded,
              label: 'All\nAppointments',
              color: const Color(0xFF0891B2),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const DoctorAppointmentsScreen()),
              ),
            ),
            SizedBox(width: 12.w),
            _ActionTile(
              icon: Icons.bar_chart_rounded,
              label: 'Patient\nReports',
              color: const Color(0xFF7C3AED),
              onTap: () => HapticFeedback.lightImpact(),
            ),
            SizedBox(width: 12.w),
            _ActionTile(
              icon: Icons.search_rounded,
              label: 'Find\nPatient',
              color: const Color(0xFF16A34A),
              onTap: () => HapticFeedback.lightImpact(),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 40.w,
                width: 40.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, size: 20.w, color: color),
              ),
              SizedBox(height: 8.h),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 28.w,
          width: 28.w,
          decoration: BoxDecoration(
            color: _indigo.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 15.w, color: _indigo),
        ),
        SizedBox(width: 8.w),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

// ─── Appointment Card ─────────────────────────────────────────────────────────

class _AppointmentCard extends ConsumerWidget {
  final AppointmentModel appt;
  const _AppointmentCard({required this.appt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(appt.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: _indigo.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Colored top bar
          Container(
            height: 4.h,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                // Time column
                Container(
                  width: 56.w,
                  padding: EdgeInsets.symmetric(
                      vertical: 10.h, horizontal: 6.w),
                  decoration: BoxDecoration(
                    color: _indigo.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _formatTime(appt.scheduledAt)
                            .split(' ')
                            .first,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: _indigo,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        _formatTime(appt.scheduledAt)
                            .split(' ')
                            .last,
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: _indigoL,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 12.w),

                // Patient info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appt.patientName,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${appt.patientAge} yrs · ${appt.type.label}',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      if (appt.reason.isNotEmpty)
                        Text(
                          appt.reason,
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: const Color(0xFF94A3B8),
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                SizedBox(width: 10.w),

                // Status + actions column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        appt.status.label,
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    if (appt.status == AppointmentStatus.pending ||
                        appt.status == AppointmentStatus.confirmed)
                      _StatusMenu(appt: appt),
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

// ─── Status Menu ─────────────────────────────────────────────────────────────

class _StatusMenu extends StatelessWidget {
  final AppointmentModel appt;
  const _StatusMenu({required this.appt});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AppointmentStatus>(
      onSelected: (s) async {
        HapticFeedback.lightImpact();
        if (appt.id != null) await updateAppointmentStatus(appt.id!, s);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      itemBuilder: (_) => [
        if (appt.status == AppointmentStatus.pending)
          PopupMenuItem(
            value: AppointmentStatus.confirmed,
            child: _menuItem(
                Icons.check_circle_rounded, 'Confirm',
                const Color(0xFF0D9488)),
          ),
        PopupMenuItem(
          value: AppointmentStatus.completed,
          child: _menuItem(
              Icons.task_alt_rounded, 'Complete',
              const Color(0xFF16A34A)),
        ),
        PopupMenuItem(
          value: AppointmentStatus.noShow,
          child: _menuItem(
              Icons.person_off_rounded, 'No Show',
              const Color(0xFF94A3B8)),
        ),
        PopupMenuItem(
          value: AppointmentStatus.cancelled,
          child: _menuItem(
              Icons.cancel_rounded, 'Cancel',
              const Color(0xFFEF4444)),
        ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: _indigo.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Update',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: _indigo,
              ),
            ),
            SizedBox(width: 2.w),
            Icon(Icons.expand_more_rounded, size: 12.w, color: _indigo),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

// ─── Empty Schedule ───────────────────────────────────────────────────────────

class _EmptySchedule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 36.h, horizontal: 20.w),
      child: Column(
        children: [
          Container(
            height: 72.w,
            width: 72.w,
            decoration: BoxDecoration(
              color: _indigo.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_available_rounded,
                size: 34.w, color: _indigo),
          ),
          SizedBox(height: 14.h),
          Text(
            'No appointments today',
            style: GoogleFonts.poppins(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Your schedule is clear for today.',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
