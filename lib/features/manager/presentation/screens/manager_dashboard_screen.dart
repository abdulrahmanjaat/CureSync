import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/custom_bottom_sheet.dart';
import '../../../auth/data/models/patient_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../patient/presentation/providers/patient_provider.dart';
import '../../../patient/presentation/providers/medication_provider.dart';
import '../../../patient/presentation/widgets/add_patient_sheet.dart';
import 'manager_notifications_screen.dart';

// ── Brand palette ─────────────────────────────────────────────────────────────
const Color _rose  = Color(0xFFDB2777);
const Color _roseD = Color(0xFF9D174D);
const Color _bg    = Color(0xFFF9F5F7);

// Per-patient avatar gradient palette (cycles by list index)
const List<List<Color>> _gradients = [
  [Color(0xFFDB2777), Color(0xFF9D174D)],
  [Color(0xFF0891B2), Color(0xFF0E7490)],
  [Color(0xFF7C3AED), Color(0xFF5B21B6)],
  [Color(0xFF16A34A), Color(0xFF15803D)],
  [Color(0xFFF59E0B), Color(0xFFD97706)],
  [Color(0xFF0D9488), Color(0xFF0F766E)],
];

const Map<String, String> _relationEmojis = {
  'Father': '👨', 'Mother': '👩', 'Son': '👦', 'Daughter': '👧',
  'Brother': '🧑', 'Sister': '👱', 'Grandparent': '🧓',
  'Grandfather': '👴', 'Grandmother': '👵', 'Spouse': '💑',
  'Wife': '👩', 'Husband': '👨', 'Child': '🧒',
  'Friend': '🤝', 'Myself': '🧑',
};

// ── Helpers ───────────────────────────────────────────────────────────────────
Color _adherenceColor(double pct) {
  if (pct >= 80) return const Color(0xFF16A34A);
  if (pct >= 50) return const Color(0xFFF59E0B);
  return const Color(0xFFEF4444);
}

String _greetingText() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

// ════════════════════════════════════════════════════════════════════════════
// Main screen
// ════════════════════════════════════════════════════════════════════════════
class ManagerDashboardScreen extends ConsumerWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(patientsStreamProvider);
    final authUser     = ref.watch(authStateProvider).valueOrNull;
    final firstName    = (authUser?.displayName ?? 'Manager').split(' ').first;
    final photoUrl     = authUser?.photoURL;

    final patients = patientsAsync.valueOrNull ?? [];
    final sosCount = patients.where((p) => p.isSosActive).length;

    // Aggregate today's adherence across all managed patients
    int totalTaken = 0, totalDoses = 0;
    for (final p in patients) {
      final adh = ref.watch(todayAdherenceProvider(p.patientId ?? ''));
      totalTaken += adh.taken;
      totalDoses += adh.total;
    }

    final adherenceText = !patientsAsync.hasValue
        ? '–'
        : totalDoses == 0
            ? '–'
            : '${totalTaken * 100 ~/ totalDoses}%';

    // Missed-dose badge: count across all managed patients
    final missedCount = ref
        .watch(managerAlertsProvider)
        .where((a) => a.type == ManagerAlertType.missedMed)
        .length;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // ── Gradient header ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _DashboardHeader(
              firstName: firstName,
              photoUrl: photoUrl,
              patientCount: patients.length,
              adherenceText: adherenceText,
              sosCount: sosCount,
              patientsLoaded: patientsAsync.hasValue,
              missedCount: missedCount,
              onBell: () {
                HapticFeedback.lightImpact();
                context.push('/manager/notifications');
              },
              onProfile: () {
                HapticFeedback.lightImpact();
                context.push('/profile');
              },
            ),
          ),

          // ── Section label ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 12.h),
              child: Row(
                children: [
                  Text(
                    'Patients',
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  if (patients.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: _rose.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '${patients.length}',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: _rose,
                        ),
                      ),
                    ),
                  if (sosCount > 0) ...[
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_rounded,
                              size: 12.w,
                              color: const Color(0xFFEF4444)),
                          SizedBox(width: 4.w),
                          Text(
                            '$sosCount SOS',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Patient list ──────────────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            sliver: patientsAsync.when(
              loading: () =>
                  const SliverToBoxAdapter(child: _LoadingState()),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40.h),
                    child: Text(
                      'Error loading patients',
                      style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: const Color(0xFF94A3B8)),
                    ),
                  ),
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyState(
                      onAdd: () => CustomBottomSheet.show(
                        context: context,
                        useDraggable: false,
                        child: const AddPatientSheet(),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final p = list[i];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16.h),
                        child: _PatientCard(
                          patient: p,
                          colorIdx: i % _gradients.length,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.push(
                                '/manager/patient/${p.patientId}');
                          },
                        )
                            .animate()
                            .fadeIn(
                                duration: 400.ms,
                                delay: (80 * i).ms)
                            .slideY(
                                begin: 0.05,
                                end: 0,
                                duration: 400.ms,
                                delay: (80 * i).ms),
                      );
                    },
                    childCount: list.length,
                  ),
                );
              },
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 120.h)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Gradient header
// ════════════════════════════════════════════════════════════════════════════
class _DashboardHeader extends StatelessWidget {
  final String firstName;
  final String? photoUrl;
  final int patientCount;
  final String adherenceText;
  final int sosCount;
  final int missedCount;
  final bool patientsLoaded;
  final VoidCallback onBell;
  final VoidCallback onProfile;

  const _DashboardHeader({
    required this.firstName,
    required this.photoUrl,
    required this.patientCount,
    required this.adherenceText,
    required this.sosCount,
    required this.missedCount,
    required this.patientsLoaded,
    required this.onBell,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8356D), _roseD],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative ambient blobs
          Positioned(
            top: -30.h,
            right: -40.w,
            child: Container(
              height: 190.w,
              width: 190.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            top: 55.h,
            right: 25.w,
            child: Container(
              height: 80.w,
              width: 80.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 28.h,
            left: -20.w,
            child: Container(
              height: 100.w,
              width: 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── App bar row ────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greetingText(),
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color:
                                  Colors.white.withValues(alpha: 0.75),
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
                      Row(
                        children: [
                          // Bell with missed-dose badge
                          GestureDetector(
                            onTap: onBell,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  height: 42.w,
                                  width: 42.w,
                                  decoration: BoxDecoration(
                                    color: Colors.white
                                        .withValues(alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(14.r),
                                    border: Border.all(
                                      color: Colors.white
                                          .withValues(alpha: 0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    missedCount > 0
                                        ? Icons.notifications_active_rounded
                                        : Icons.notifications_none_rounded,
                                    size: 22.w,
                                    color: Colors.white,
                                  ),
                                ),
                                if (missedCount > 0)
                                  Positioned(
                                    top: -4.h,
                                    right: -4.w,
                                    child: Container(
                                      constraints: BoxConstraints(
                                          minWidth: 18.w, minHeight: 18.w),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 4.w),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        borderRadius:
                                            BorderRadius.circular(10.r),
                                        border: Border.all(
                                            color: _roseD, width: 1.5),
                                      ),
                                      child: Center(
                                        child: Text(
                                          missedCount > 99
                                              ? '99+'
                                              : '$missedCount',
                                          style: GoogleFonts.inter(
                                            fontSize: 9.sp,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          // Profile avatar
                          GestureDetector(
                            onTap: onProfile,
                            child: Container(
                              height: 42.w,
                              width: 42.w,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(14.r),
                                border: Border.all(
                                  color: Colors.white
                                      .withValues(alpha: 0.45),
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(12.r),
                                child: photoUrl != null
                                    ? Image.network(
                                        photoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, e, st) =>
                                            _avatarFallback(),
                                      )
                                    : _avatarFallback(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 8.h),

                  // Subtitle role pill
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.manage_accounts_rounded,
                          size: 12.w,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          patientsLoaded
                              ? 'Managing $patientCount patient${patientCount == 1 ? '' : 's'}'
                              : 'Care Manager',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color:
                                Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 22.h),

                  // ── Stats strip ────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _HeaderStat(
                          icon: Icons.people_rounded,
                          value: patientsLoaded
                              ? '$patientCount'
                              : '–',
                          label: 'Patients',
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _HeaderStat(
                          icon: Icons.donut_large_rounded,
                          value: adherenceText,
                          label: 'Adherence',
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _HeaderStat(
                          icon: sosCount > 0
                              ? Icons.warning_rounded
                              : Icons.check_circle_rounded,
                          value:
                              patientsLoaded ? '$sosCount' : '–',
                          label: 'SOS',
                          isAlert: sosCount > 0,
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
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _avatarFallback() {
    return Container(
      color: Colors.white.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          firstName.isNotEmpty ? firstName[0].toUpperCase() : 'M',
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Frosted glass stat bubble ─────────────────────────────────────────────────
class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool isAlert;

  const _HeaderStat({
    required this.icon,
    required this.value,
    required this.label,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
      decoration: BoxDecoration(
        color: isAlert
            ? const Color(0xFFEF4444).withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isAlert
              ? const Color(0xFFEF4444).withValues(alpha: 0.40)
              : Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 12.w,
                  color: Colors.white.withValues(alpha: 0.8)),
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
          SizedBox(height: 3.h),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Patient card
// ════════════════════════════════════════════════════════════════════════════
class _PatientCard extends ConsumerWidget {
  final PatientModel patient;
  final int colorIdx;
  final VoidCallback onTap;

  const _PatientCard({
    required this.patient,
    required this.colorIdx,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientId  = patient.patientId ?? '';
    final adh        = ref.watch(todayAdherenceProvider(patientId));
    final nextDose   = ref.watch(nextDoseProvider(patientId));
    final medsAsync  = ref.watch(medicationsStreamProvider(patientId));
    final activeMeds = (medsAsync.valueOrNull ?? [])
        .where((m) => m.isActive && !m.isExpired)
        .length;

    final colors       = _gradients[colorIdx];
    final primaryColor = colors[0];
    final emoji        = _relationEmojis[patient.relation] ?? '🧑';
    final adherencePct =
        adh.total > 0 ? (adh.taken * 100.0 / adh.total) : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: [
            BoxShadow(
              color: patient.isSosActive
                  ? const Color(0xFFEF4444).withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 5),
              spreadRadius: patient.isSosActive ? 1 : 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SOS alert banner
              if (patient.isSosActive)
                _SosBanner(triggerTime: patient.sosTriggerTime),

              Padding(
                padding: EdgeInsets.all(18.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Identity row ───────────────────────────────────
                    Row(
                      children: [
                        // Gradient emoji avatar
                        Container(
                          height: 56.w,
                          width: 56.w,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: colors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18.r),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor
                                    .withValues(alpha: 0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              emoji,
                              style: TextStyle(fontSize: 26.sp),
                            ),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        // Name + relation
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                patient.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                '${patient.relation} · ${patient.age} yrs',
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Arrow CTA
                        Container(
                          height: 38.w,
                          width: 38.w,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: colors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(13.r),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor
                                    .withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 18.w,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 18.h),

                    // ── Adherence bar ──────────────────────────────────
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Today's Adherence",
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF94A3B8),
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          adh.total == 0
                              ? 'No schedule'
                              : '${adh.taken}/${adh.total} doses · ${adherencePct.round()}%',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: adh.total == 0
                                ? const Color(0xFFCBD5E1)
                                : _adherenceColor(adherencePct),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: LinearProgressIndicator(
                        value: adh.total == 0
                            ? 0
                            : adherencePct / 100,
                        minHeight: 8.h,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          adh.total == 0
                              ? const Color(0xFFE2E8F0)
                              : _adherenceColor(adherencePct),
                        ),
                      ),
                    ),

                    SizedBox(height: 14.h),

                    // ── Chips row ──────────────────────────────────────
                    Row(
                      children: [
                        _CardChip(
                          icon: Icons.medication_rounded,
                          label:
                              '$activeMeds med${activeMeds == 1 ? '' : 's'}',
                          color: primaryColor,
                        ),
                        if (nextDose != null) ...[
                          SizedBox(width: 6.w),
                          _CardChip(
                            icon: Icons.schedule_rounded,
                            label: nextDose.time,
                            color: const Color(0xFF0891B2),
                          ),
                        ],
                        const Spacer(),
                        // Tappable access code
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Clipboard.setData(ClipboardData(
                                text: patient.accessCode));
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Code copied',
                                  style: GoogleFonts.inter(
                                      color: Colors.white),
                                ),
                                backgroundColor:
                                    const Color(0xFF0D9488),
                                behavior: SnackBarBehavior.floating,
                                duration:
                                    const Duration(seconds: 2),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(10.r)),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 5.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius:
                                  BorderRadius.circular(8.r),
                              border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.key_rounded,
                                    size: 10.w,
                                    color:
                                        const Color(0xFF94A3B8)),
                                SizedBox(width: 4.w),
                                Text(
                                  patient.accessCode,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF475569),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── SOS alert banner ──────────────────────────────────────────────────────────
class _SosBanner extends StatelessWidget {
  final DateTime? triggerTime;
  const _SosBanner({this.triggerTime});

  @override
  Widget build(BuildContext context) {
    String timeAgo = '';
    if (triggerTime != null) {
      final diff = DateTime.now().difference(triggerTime!);
      timeAgo = diff.inMinutes < 60
          ? '${diff.inMinutes}m ago'
          : '${diff.inHours}h ago';
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded,
              size: 14.w, color: Colors.white),
          SizedBox(width: 6.w),
          Text(
            timeAgo.isEmpty ? 'SOS ACTIVE' : 'SOS ACTIVE · $timeAgo',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              'RESPOND',
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
            duration: 1500.ms,
            color: Colors.white.withValues(alpha: 0.12));
  }
}

// ── Card chip ─────────────────────────────────────────────────────────────────
class _CardChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _CardChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.w, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer loading skeleton ──────────────────────────────────────────────────
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: EdgeInsets.only(bottom: 16.h),
          child: Container(
            height: 160.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22.r),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(
                  duration: 1200.ms,
                  color: const Color(0xFFF1F5F9)),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 60.h),
      child: Column(
        children: [
          Container(
            height: 90.w,
            width: 90.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDB2777), Color(0xFF9D174D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _rose.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.people_outline_rounded,
              size: 44.w,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 22.h),
          Text(
            'No patients yet',
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add a patient to start managing\ntheir medications and health.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0xFF94A3B8),
              height: 1.5,
            ),
          ),
          SizedBox(height: 32.h),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 28.w, vertical: 14.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDB2777), Color(0xFF9D174D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: _rose.withValues(alpha: 0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add_rounded,
                      size: 20.w, color: Colors.white),
                  SizedBox(width: 8.w),
                  Text(
                    'Add First Patient',
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
