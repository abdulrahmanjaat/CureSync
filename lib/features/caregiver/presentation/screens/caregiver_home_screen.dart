import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/models/assigned_patient_model.dart';
import '../../data/models/care_log_model.dart';
import '../providers/caregiver_provider.dart';
import '../../../../core/services/pdf_export_service.dart';

class CaregiverHomeScreen extends ConsumerWidget {
  const CaregiverHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final greeting = _greeting();
    final firstName =
        (authUser?.displayName ?? 'Caregiver').split(' ').first;
    final photoUrl = authUser?.photoURL;
    final patients =
        ref.watch(assignedPatientsProvider).valueOrNull ?? [];
    final sosPatient = ref.watch(sosTriggerProvider);
    final alertCount = (ref.watch(totalMissedMedsProvider) +
        ref.watch(pendingDealCountProvider) +
        (sosPatient != null ? 1 : 0))
        .toInt();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF8FBFA),
          body: Stack(
            children: [
              // Ambient gradient
              Positioned(
                top: -80.h,
                right: -60.w,
                child: Container(
                  height: 280.w,
                  width: 280.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      const Color(0xFF0D9488)
                          .withValues(alpha: 0.07),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),

              SafeArea(
                child: CustomScrollView(
                  slivers: [
                    // ── Sticky AppBar ───────────────────────────────
                    SliverToBoxAdapter(
                      child: _AppBar(
                        greeting: greeting,
                        firstName: firstName,
                        photoUrl: photoUrl,
                        onAvatarTap: () => context.push('/profile'),
                        onAlertsTap: () =>
                            context.push('/caregiver/alerts'),
                        alertCount: alertCount,
                      ).animate().fadeIn(duration: 350.ms),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 20.h)),

                    // ── Link Patient Card ───────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20.w),
                        child: _LinkPatientCard(),
                      )
                          .animate()
                          .fadeIn(duration: 350.ms, delay: 60.ms),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 20.h)),

                    // ── Stats Row ───────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20.w),
                        child: _StatsRow(patients: patients),
                      )
                          .animate()
                          .fadeIn(duration: 350.ms, delay: 100.ms),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 20.h)),

                    // ── Patient Grid header ─────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20.w),
                        child: Row(
                          children: [
                            Text(
                              'Your Patients',
                              style: GoogleFonts.poppins(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const Spacer(),
                            if (patients.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  context.push('/caregiver/deals');
                                },
                                child: Text(
                                  'Manage Deals',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0D9488),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 350.ms, delay: 120.ms),
                    ),

                    SliverToBoxAdapter(child: SizedBox(height: 12.h)),

                    // ── Patient Grid ────────────────────────────────
                    if (patients.isEmpty)
                      SliverToBoxAdapter(
                        child: _EmptyPatientState(
                          onBrowse: () =>
                              context.push('/caregiver/deals'),
                        ),
                      )
                    else
                      SliverPadding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20.w),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: _PatientBentoCard(
                                patient: patients[i],
                                index: i,
                                onExportPdf: () => _exportPdf(
                                    context, ref, patients[i]),
                                onQuickNote: () =>
                                    _showQuickNoteSheet(
                                        context, ref, patients[i]),
                              ),
                            ),
                            childCount: patients.length,
                          ),
                        ),
                      ),

                    SliverToBoxAdapter(child: SizedBox(height: 24.h)),

                    // ── Daily Duty List ─────────────────────────────
                    const SliverToBoxAdapter(child: _DailyDutySection()),

                    SliverToBoxAdapter(child: SizedBox(height: 100.h)),
                  ],
                ),
              ),
            ],
          ),
        ),

      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref,
      AssignedPatientModel patient) async {
    HapticFeedback.mediumImpact();
    try {
      await PdfExportService.exportHealthSummary(
        ref: ref,
        patientId: patient.patientId,
        patientName: patient.patientName,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('PDF export failed: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ));
      }
    }
  }

  void _showQuickNoteSheet(BuildContext context, WidgetRef ref,
      AssignedPatientModel patient) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickNoteSheet(patient: patient),
    );
  }
}

// ─── AppBar ───────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final String greeting;
  final String firstName;
  final String? photoUrl;
  final VoidCallback onAvatarTap;
  final VoidCallback onAlertsTap;
  final int alertCount;

  const _AppBar({
    required this.greeting,
    required this.firstName,
    required this.photoUrl,
    required this.onAvatarTap,
    required this.onAlertsTap,
    required this.alertCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  firstName,
                  style: GoogleFonts.poppins(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),

          // Alerts bell
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onAlertsTap();
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 42.w,
                  width: 42.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Icon(Icons.notifications_rounded,
                      size: 20.w, color: const Color(0xFF0F172A)),
                ),
                if (alertCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      height: 16.w,
                      width: 16.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$alertCount',
                          style: GoogleFonts.inter(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(width: 10.w),

          // Avatar → profile
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onAvatarTap();
            },
            child: Container(
              height: 42.w,
              width: 42.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color:
                      const Color(0xFF0D9488).withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13.r),
                child: photoUrl != null
                    ? Image.network(photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _avatarFallback('C'))
                    : _avatarFallback('C'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String letter) {
    return Container(
      color: const Color(0xFF0D9488),
      child: Center(
        child: Text(
          letter,
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

// ─── Link Patient Card ────────────────────────────────────────────────────────

class _LinkPatientCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_LinkPatientCard> createState() =>
      _LinkPatientCardState();
}

class _LinkPatientCardState extends ConsumerState<_LinkPatientCard> {
  bool _expanded = false;
  final _codeController = TextEditingController();
  bool _linking = false;
  String? _errorMsg;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _linking = true;
      _errorMsg = null;
    });

    final error = await ref
        .read(linkPatientProvider.notifier)
        .link(code);

    if (!mounted) return;
    if (error == null) {
      HapticFeedback.heavyImpact();
      _codeController.clear();
      setState(() {
        _expanded = false;
        _linking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Patient linked successfully!'),
        backgroundColor: Color(0xFF16A34A),
      ));
    } else {
      HapticFeedback.lightImpact();
      setState(() {
        _errorMsg = error;
        _linking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF0891B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _expanded = !_expanded;
                _errorMsg = null;
              });
            },
            child: Row(
              children: [
                Container(
                  height: 40.w,
                  width: 40.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Icons.link_rounded,
                      size: 22.w, color: Colors.white),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Link New Patient',
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Enter 5-digit access code',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 220),
                  turns: _expanded ? 0.5 : 0,
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      size: 22.w, color: Colors.white),
                ),
              ],
            ),
          ),

          // Expandable input
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 280),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 14.h),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 10,
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                      letterSpacing: 4,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. AB123',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        color: const Color(0xFFCBD5E1),
                        letterSpacing: 4,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 12.h),
                      counterText: '',
                    ),
                    onSubmitted: (_) => _link(),
                  ),
                ),
                if (_errorMsg != null) ...[
                  SizedBox(height: 6.h),
                  Text(
                    _errorMsg!,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: const Color(0xFFFECACA),
                    ),
                  ),
                ],
                SizedBox(height: 10.h),
                GestureDetector(
                  onTap: _linking ? null : _link,
                  child: Container(
                    width: double.infinity,
                    height: 44.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Center(
                      child: _linking
                          ? SizedBox(
                              height: 20.w,
                              width: 20.w,
                              child: CircularProgressIndicator(
                                color: const Color(0xFF0D9488),
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Connect Patient',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0D9488),
                              ),
                            ),
                    ),
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

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final List<AssignedPatientModel> patients;
  const _StatsRow({required this.patients});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
          icon: Icons.people_rounded,
          label: 'Patients',
          value: '${patients.length}',
          color: const Color(0xFF0D9488),
        ),
        SizedBox(width: 10.w),
        _StatChip(
          icon: Icons.check_circle_rounded,
          label: 'Active',
          value:
              '${patients.where((p) => p.isActive).length}',
          color: const Color(0xFF16A34A),
        ),
        SizedBox(width: 10.w),
        Consumer(
          builder: (_, ref, _) {
            final missed = ref.watch(totalMissedMedsProvider);
            return _StatChip(
              icon: Icons.medication_rounded,
              label: 'Overdue',
              value: '$missed',
              color: missed > 0
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF94A3B8),
            );
          },
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.w, color: color),
            SizedBox(width: 6.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    )),
                Text(label,
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: const Color(0xFF94A3B8),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Patient Bento Card ───────────────────────────────────────────────────────

class _PatientBentoCard extends ConsumerWidget {
  final AssignedPatientModel patient;
  final int index;
  final VoidCallback onExportPdf;
  final VoidCallback onQuickNote;

  const _PatientBentoCard({
    required this.patient,
    required this.index,
    required this.onExportPdf,
    required this.onQuickNote,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medStatus = ref.watch(patientMedStatusProvider(patient.patientId));
    final liveData =
        ref.watch(patientLiveDataProvider(patient.patientId)).valueOrNull;
    final meds =
        ref.watch(assignedPatientMedsProvider(patient.patientId)).valueOrNull ??
            [];
    final takenKeys =
        ref.watch(patientTakenKeysProvider(patient.patientId)).valueOrNull ??
            [];

    final hr = liveData?['heartRate']?.toString() ?? '—';
    final bp = liveData?['bloodPressure'] as String? ?? '—';
    final isSos = liveData?['isSosActive'] == true;

    // Adherence % — ratio of taken doses to total dues up to now
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    int totalDue = 0;
    int taken = 0;
    for (final med in meds.where((m) => m.isActive && !m.isExpired)) {
      for (final t in med.reminderTimes) {
        final parts = t.split(':');
        if (parts.length != 2) continue;
        final medMin =
            (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
        if (medMin <= nowMinutes) {
          totalDue++;
          if (takenKeys.contains('${med.id}_$t')) taken++;
        }
      }
    }
    final adherencePct = totalDue == 0 ? 100 : ((taken / totalDue) * 100).round();
    final adherenceColor = adherencePct >= 80
        ? const Color(0xFF16A34A)
        : adherencePct >= 50
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    final statusColor = switch (medStatus) {
      MedStatus.overdue => const Color(0xFFEF4444),
      MedStatus.allClear => const Color(0xFF16A34A),
      MedStatus.noMeds => const Color(0xFF94A3B8),
    };
    final statusLabel = switch (medStatus) {
      MedStatus.overdue => 'Med Overdue',
      MedStatus.allClear => 'All Clear',
      MedStatus.noMeds => 'No Meds',
    };
    final statusIcon = switch (medStatus) {
      MedStatus.overdue => Icons.warning_amber_rounded,
      MedStatus.allClear => Icons.check_circle_rounded,
      MedStatus.noMeds => Icons.remove_circle_outline_rounded,
    };

    final initial = patient.patientName.isNotEmpty
        ? patient.patientName[0].toUpperCase()
        : '?';
    final accentColor =
        isSos ? const Color(0xFFEF4444) : const Color(0xFF0D9488);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/caregiver/patient/${patient.patientId}');
      },
      onLongPress: onExportPdf,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: isSos ? Border.all(color: const Color(0xFFEF4444), width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gradient header ───────────────────────────────────────────────
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSos
                      ? [
                          const Color(0xFFEF4444).withValues(alpha: 0.08),
                          const Color(0xFFFEF2F2),
                        ]
                      : [
                          const Color(0xFF0D9488).withValues(alpha: 0.08),
                          const Color(0xFFF0FDFA),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    height: 60.w,
                    width: 60.w,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: GoogleFonts.poppins(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  // Name + status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.patientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon,
                                  size: 12.w, color: statusColor),
                              SizedBox(width: 5.w),
                              Text(
                                statusLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // SOS badge or adherence ring placeholder
                  if (isSos)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.sos_rounded,
                              size: 16.w, color: Colors.white),
                          SizedBox(width: 4.w),
                          Text(
                            'SOS',
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        Text(
                          '$adherencePct%',
                          style: GoogleFonts.poppins(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                            color: adherenceColor,
                          ),
                        ),
                        Text(
                          'adherence',
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // ── Vitals row ────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _BigVitalTile(
                      icon: Icons.favorite_rounded,
                      label: 'Heart Rate',
                      value: hr,
                      unit: 'bpm',
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _BigVitalTile(
                      icon: Icons.monitor_heart_rounded,
                      label: 'Blood Pressure',
                      value: bp,
                      unit: 'mmHg',
                      color: const Color(0xFF0891B2),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _BigVitalTile(
                      icon: Icons.medication_rounded,
                      label: 'Meds Today',
                      value: '$taken/$totalDue',
                      unit: 'doses',
                      color: const Color(0xFF0D9488),
                    ),
                  ),
                ],
              ),
            ),

            // ── Adherence bar ─────────────────────────────────────────────────
            if (totalDue > 0)
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Today\'s Adherence',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$adherencePct%',
                          style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: adherenceColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: LinearProgressIndicator(
                        value: adherencePct / 100,
                        minHeight: 6.h,
                        backgroundColor:
                            adherenceColor.withValues(alpha: 0.12),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(adherenceColor),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Action buttons ────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  // Quick Note
                  Expanded(
                    child: GestureDetector(
                      onTap: onQuickNote,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488)
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                              color: const Color(0xFF0D9488)
                                  .withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.note_add_rounded,
                                size: 15.w,
                                color: const Color(0xFF0D9488)),
                            SizedBox(width: 6.w),
                            Text(
                              'Quick Note',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0D9488),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  // View Dashboard
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push(
                            '/caregiver/patient/${patient.patientId}');
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.dashboard_rounded,
                                size: 15.w, color: Colors.white),
                            SizedBox(width: 6.w),
                            Text(
                              'Dashboard',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: (index * 100).ms)
        .slideY(
            begin: 0.06,
            end: 0,
            duration: 400.ms,
            delay: (index * 100).ms,
            curve: Curves.easeOut);
  }
}

// ─── Big Vital Tile ───────────────────────────────────────────────────────────

class _BigVitalTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _BigVitalTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16.w, color: color),
          SizedBox(height: 6.h),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          Text(
            unit.isEmpty ? label : unit,
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Daily Duty Section ───────────────────────────────────────────────────────

class _DailyDutySection extends ConsumerWidget {
  const _DailyDutySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duties = ref.watch(dailyDutyListProvider);
    if (duties.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Daily Duty List',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  '${duties.length}',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D9488),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...duties.map((d) => _DutyRow(duty: d)),
        ],
      ),
    );
  }
}

class _DutyRow extends StatelessWidget {
  final DutyItem duty;
  const _DutyRow({required this.duty});

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatTime(duty.time);
    final isNow = _isUpcoming(duty.sortKey);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
      decoration: BoxDecoration(
        color: duty.isTaken
            ? const Color(0xFFF0FDF4)
            : isNow
                ? const Color(0xFFFEFCE8)
                : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: duty.isTaken
              ? const Color(0xFF16A34A).withValues(alpha: 0.2)
              : isNow
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                  : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          // Time column
          SizedBox(
            width: 54.w,
            child: Text(
              timeStr,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: duty.isTaken
                    ? const Color(0xFF16A34A)
                    : isNow
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF0F172A),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          // Med icon
          Container(
            height: 32.w,
            width: 32.w,
            decoration: BoxDecoration(
              color: duty.isTaken
                  ? const Color(0xFF16A34A).withValues(alpha: 0.1)
                  : const Color(0xFF0D9488).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              duty.isTaken
                  ? Icons.check_rounded
                  : Icons.medication_rounded,
              size: 16.w,
              color: duty.isTaken
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF0D9488),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  duty.medName,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                    decoration: duty.isTaken
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor:
                        const Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  duty.patientName,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          if (isNow && !duty.isTaken)
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                'Now',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(String t) {
    final parts = t.split(':');
    if (parts.length != 2) return t;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final dt = DateTime(2000, 1, 1, h, m);
    return DateFormat('h:mm a').format(dt);
  }

  bool _isUpcoming(int sortKey) {
    final now = DateTime.now();
    final nowMins = now.hour * 60 + now.minute;
    return (sortKey - nowMins).abs() <= 30;
  }
}

// ─── Quick Note Sheet ─────────────────────────────────────────────────────────

class _QuickNoteSheet extends ConsumerStatefulWidget {
  final AssignedPatientModel patient;
  const _QuickNoteSheet({required this.patient});

  @override
  ConsumerState<_QuickNoteSheet> createState() =>
      _QuickNoteSheetState();
}

class _QuickNoteSheetState extends ConsumerState<_QuickNoteSheet> {
  final _noteController = TextEditingController();
  CareLogType _type = CareLogType.general;
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final note = _noteController.text.trim();
    if (note.isEmpty) return;
    setState(() => _saving = true);

    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;

    final log = CareLogModel(
      patientId: widget.patient.patientId,
      patientName: widget.patient.patientName,
      note: note,
      type: _type,
      createdAt: DateTime.now(),
    );

    await ref
        .read(caregiverRepositoryProvider)
        .addCareLog(uid, log);

    HapticFeedback.mediumImpact();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                height: 4,
                width: 40.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Quick Note',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              widget.patient.patientName,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: const Color(0xFF94A3B8),
              ),
            ),
            SizedBox(height: 16.h),

            // Type chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: CareLogType.values.map((t) {
                  final label = switch (t) {
                    CareLogType.observation => 'Observation',
                    CareLogType.medicationNote => 'Med Note',
                    CareLogType.vitalNote => 'Vital Note',
                    CareLogType.general => 'General',
                  };
                  final isSelected = _type == t;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _type = t);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: 8.w),
                      padding: EdgeInsets.symmetric(
                          horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0D9488)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 14.h),

            // Note input
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFA),
                borderRadius: BorderRadius.circular(14.r),
                border:
                    Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _noteController,
                maxLines: 4,
                maxLength: 500,
                autofocus: true,
                style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: const Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'e.g. Patient ate well today...',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: const Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14.w),
                  counterStyle: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: const Color(0xFFCBD5E1)),
                ),
              ),
            ),
            SizedBox(height: 14.h),

            // Save button
            GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                width: double.infinity,
                height: 52.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488)
                          .withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Center(
                  child: _saving
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5)
                      : Text(
                          'Save Note',
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyPatientState extends StatelessWidget {
  final VoidCallback onBrowse;
  const _EmptyPatientState({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 56.w, color: const Color(0xFFCBD5E1)),
            SizedBox(height: 16.h),
            Text(
              'No patients yet',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Use the Link card above to connect\nwith a patient using their access code.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: const Color(0xFF94A3B8),
                height: 1.5,
              ),
            ),
            SizedBox(height: 20.h),
            GestureDetector(
              onTap: onBrowse,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 24.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Text(
                  'View Pending Deals',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SOS Alert Overlay ───────────────────────────────────────────────────────

class SosAlertOverlay extends StatefulWidget {
  final AssignedPatientModel patient;
  final VoidCallback onNavigate;

  const SosAlertOverlay({
    super.key,
    required this.patient,
    required this.onNavigate,
  });

  @override
  State<SosAlertOverlay> createState() => SosAlertOverlayState();
}

class SosAlertOverlayState extends State<SosAlertOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    HapticFeedback.heavyImpact();
    _scheduleRepeatHaptic();
  }

  void _scheduleRepeatHaptic() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        HapticFeedback.heavyImpact();
        _scheduleRepeatHaptic();
      }
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Static subtree — built ONCE and passed as `child` to AnimatedBuilder.
    // Only the Container background color and icon Transform.scale
    // re-evaluate on every animation frame (≈60 fps).
    final staticChild = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 28.h),
        Text(
          'SOS ALERT',
          style: GoogleFonts.poppins(
            fontSize: 32.sp,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          widget.patient.patientName,
          style: GoogleFonts.poppins(
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'has triggered an emergency alert',
          style: GoogleFonts.inter(
            fontSize: 15.sp,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        SizedBox(height: 48.h),
        GestureDetector(
          onTap: () {
            HapticFeedback.heavyImpact();
            widget.onNavigate();
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_pin_rounded,
                    size: 22.w, color: const Color(0xFFEF4444)),
                SizedBox(width: 10.w),
                Text(
                  'View Patient Profile',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Consumer(
          builder: (_, ref, _) => GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ref
                  .read(caregiverRepositoryProvider)
                  .clearSos(widget.patient.patientId);
            },
            child: Text(
              'Mark as Resolved',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.7),
                decoration: TextDecoration.underline,
                decorationColor: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );

    return AnimatedBuilder(
      animation: _pulse,
      child: staticChild, // built once — not re-created per frame
      builder: (_, child) => Container(
        color: Color.lerp(
          const Color(0xFFEF4444).withValues(alpha: 0.92),
          const Color(0xFFDC2626).withValues(alpha: 0.97),
          _pulse.value,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 32.w, vertical: 40.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Only this icon scales per frame
                Transform.scale(
                  scale: 0.9 + _pulse.value * 0.1,
                  child: Container(
                    height: 100.w,
                    width: 100.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.sos_rounded,
                        size: 56.w, color: Colors.white),
                  ),
                ),
                child!, // all text + buttons — not rebuilt each frame
              ],
            ),
          ),
        ),
      ),
    );
  }
}
