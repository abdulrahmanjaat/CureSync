import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/appointment_model.dart';
import '../providers/doctor_provider.dart';

// ── Brand palette ─────────────────────────────────────────────────────────────
const Color _indigo  = Color(0xFF4338CA);
const Color _indigoL = Color(0xFF6366F1);
const Color _bg      = Color(0xFFF5F5FF);

String _formatDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
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

// ── Filter state ─────────────────────────────────────────────────────────────

final _filterProvider = StateProvider<AppointmentStatus?>((ref) => null);

// ════════════════════════════════════════════════════════════════════════════
// Screen
// ════════════════════════════════════════════════════════════════════════════
class DoctorAppointmentsScreen extends ConsumerWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAppts = ref.watch(allAppointmentsProvider).valueOrNull ?? [];
    final filter   = ref.watch(_filterProvider);

    final visible = filter == null
        ? allAppts
        : allAppts.where((a) => a.status == filter).toList();

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140.h,
            pinned: true,
            backgroundColor: _indigo,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_indigo, _indigoL],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 50.h, 20.w, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appointments',
                          style: GoogleFonts.poppins(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${allAppts.length} total · ${visible.length} shown',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Filter chips ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _FilterBar(
              selected: filter,
              onSelect: (s) =>
                  ref.read(_filterProvider.notifier).state = s,
            ).animate().fadeIn(duration: 280.ms),
          ),

          // ── List ─────────────────────────────────────────────────────────
          if (visible.isEmpty)
            SliverToBoxAdapter(
              child: _EmptyState(filter: filter)
                  .animate()
                  .fadeIn(duration: 300.ms),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                  child: _ApptCard(appt: visible[i])
                      .animate()
                      .fadeIn(duration: 260.ms, delay: (i * 50).ms)
                      .slideY(
                          begin: 0.04,
                          end: 0,
                          duration: 260.ms,
                          delay: (i * 50).ms),
                ),
                childCount: visible.length,
              ),
            ),

          SliverToBoxAdapter(child: SizedBox(height: 120.h)),
        ],
      ),
    );
  }
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final AppointmentStatus? selected;
  final ValueChanged<AppointmentStatus?> onSelect;

  const _FilterBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final chips = <(AppointmentStatus?, String, Color)>[
      (null, 'All', _indigo),
      (AppointmentStatus.pending, 'Pending', const Color(0xFFF59E0B)),
      (AppointmentStatus.confirmed, 'Confirmed', const Color(0xFF0D9488)),
      (AppointmentStatus.completed, 'Completed', const Color(0xFF16A34A)),
      (AppointmentStatus.cancelled, 'Cancelled', const Color(0xFFEF4444)),
    ];

    return SizedBox(
      height: 52.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
        physics: const BouncingScrollPhysics(),
        children: chips.map((c) {
          final (status, label, color) = c;
          final isActive = selected == status;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(status);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: EdgeInsets.only(right: 8.w),
              padding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: isActive ? color : Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isActive ? color : const Color(0xFFE2E8F0),
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Appointment Card ─────────────────────────────────────────────────────────

class _ApptCard extends StatelessWidget {
  final AppointmentModel appt;
  const _ApptCard({required this.appt});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(appt.status);
    final isToday = _isToday(appt.scheduledAt);

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
          Container(
            height: 4.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Date/time block
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: isToday
                            ? _indigo.withValues(alpha: 0.08)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _formatTime(appt.scheduledAt),
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: isToday
                                  ? _indigo
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            isToday ? 'Today' : _formatDate(appt.scheduledAt),
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: isToday
                                  ? _indigoL
                                  : const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
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
                        ],
                      ),
                    ),

                    // Status badge
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        appt.status.label,
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),

                if (appt.reason.isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notes_rounded,
                          size: 13.w,
                          color: const Color(0xFF94A3B8),
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            appt.reason,
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: const Color(0xFF64748B),
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action buttons for actionable statuses
                if (appt.status == AppointmentStatus.pending ||
                    appt.status == AppointmentStatus.confirmed) ...[
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      if (appt.status == AppointmentStatus.pending)
                        Expanded(
                          child: _ActionButton(
                            label: 'Confirm',
                            color: const Color(0xFF0D9488),
                            onTap: () async {
                              if (appt.id != null) {
                                await updateAppointmentStatus(
                                    appt.id!, AppointmentStatus.confirmed);
                              }
                            },
                          ),
                        ),
                      if (appt.status == AppointmentStatus.pending)
                        SizedBox(width: 8.w),
                      Expanded(
                        child: _ActionButton(
                          label: 'Complete',
                          color: const Color(0xFF16A34A),
                          onTap: () async {
                            if (appt.id != null) {
                              await updateAppointmentStatus(
                                  appt.id!, AppointmentStatus.completed);
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _ActionButton(
                        label: 'Cancel',
                        color: const Color(0xFFEF4444),
                        outlined: true,
                        onTap: () async {
                          if (appt.id != null) {
                            await updateAppointmentStatus(
                                appt.id!, AppointmentStatus.cancelled);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(10.r),
          border: outlined ? Border.all(color: color) : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: outlined ? color : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AppointmentStatus? filter;
  const _EmptyState({this.filter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 60.h, horizontal: 20.w),
      child: Column(
        children: [
          Container(
            height: 72.w,
            width: 72.w,
            decoration: BoxDecoration(
              color: _indigo.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_busy_rounded,
                size: 34.w, color: _indigo),
          ),
          SizedBox(height: 14.h),
          Text(
            filter == null
                ? 'No appointments yet'
                : 'No ${filter!.label.toLowerCase()} appointments',
            style: GoogleFonts.poppins(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'They will appear here once created.',
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
