import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/caregiver/data/models/assigned_patient_model.dart';
import '../../../../features/caregiver/presentation/providers/caregiver_provider.dart';
import '../../../../features/patient/presentation/widgets/dashboard/bento_card.dart';

// ─── Family Home Screen ───────────────────────────────────────────────────────
// Monitoring-only. Family members cannot edit meds or vitals.
// They link to a patient via 5-digit access code (same handshake as caregivers).
class FamilyHomeScreen extends ConsumerWidget {
  const FamilyHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final firstName =
        (authUser?.displayName ?? 'there').split(' ').first;
    final patients =
        ref.watch(assignedPatientsProvider).valueOrNull ?? [];
    final sosPatient = ref.watch(sosTriggerProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF8FBFA),
          body: Stack(
            children: [
              // ── Ambient gradient ──
              Positioned(
                top: -80.h,
                left: -60.w,
                child: Container(
                  height: 300.w,
                  width: 300.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      const Color(0xFF7C3AED).withValues(alpha: 0.07),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),

              SafeArea(
                child: CustomScrollView(
                  slivers: [
                    // ── AppBar ──
                    SliverToBoxAdapter(
                      child: _FamilyAppBar(
                        firstName: firstName,
                        photoUrl: authUser?.photoURL,
                        onAvatarTap: () => context.push('/profile'),
                        onBellTap: () =>
                            context.push('/notifications'),
                      ).animate().fadeIn(duration: 350.ms),
                    ),

                    SliverToBoxAdapter(
                        child: SizedBox(height: 20.h)),

                    // ── Link Patient Card ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20.w),
                        child: const _LinkPatientCard(),
                      )
                          .animate()
                          .fadeIn(duration: 350.ms, delay: 60.ms),
                    ),

                    SliverToBoxAdapter(
                        child: SizedBox(height: 20.h)),

                    // ── Section title ──
                    if (patients.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.w),
                          child: Text(
                            'My Family Members',
                            style: GoogleFonts.poppins(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ).animate().fadeIn(
                            duration: 350.ms, delay: 100.ms),
                      ),

                    if (patients.isNotEmpty)
                      SliverToBoxAdapter(
                          child: SizedBox(height: 12.h)),

                    // ── Patient grid ──
                    if (patients.isNotEmpty)
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.w),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12.w,
                            mainAxisSpacing: 12.h,
                            childAspectRatio: 0.85,
                          ),
                          delegate:
                              SliverChildBuilderDelegate(
                            (context, i) {
                              final p = patients[i];
                              return _PatientMonitorCard(
                                patient: p,
                              )
                                  .animate()
                                  .fadeIn(
                                    duration: 350.ms,
                                    delay: (80 * i).ms,
                                  )
                                  .scale(
                                    begin: const Offset(0.96, 0.96),
                                    duration: 350.ms,
                                    delay: (80 * i).ms,
                                  );
                            },
                            childCount: patients.length,
                          ),
                        ),
                      ),

                    // ── Empty state ──
                    if (patients.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.w, vertical: 48.h),
                          child: Column(
                            children: [
                              Container(
                                height: 80.w,
                                width: 80.w,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED)
                                      .withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.people_outline_rounded,
                                  size: 36.w,
                                  color: const Color(0xFF7C3AED),
                                ),
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'No family members linked yet',
                                style: GoogleFonts.poppins(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                'Enter a 5-digit access code above\nto start monitoring.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13.sp,
                                  color: const Color(0xFF94A3B8),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(
                            duration: 400.ms, delay: 120.ms),
                      ),

                    SliverToBoxAdapter(
                        child: SizedBox(height: 120.h)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── SOS Overlay ──
        if (sosPatient != null)
          _SosOverlay(
            patient: sosPatient,
            onResolve: () => ref
                .read(caregiverRepositoryProvider)
                .clearSos(sosPatient.patientId),
          ),
      ],
    );
  }
}

// ─── AppBar ───────────────────────────────────────────────────────────────────

class _FamilyAppBar extends StatelessWidget {
  final String firstName;
  final String? photoUrl;
  final VoidCallback onAvatarTap;
  final VoidCallback onBellTap;

  const _FamilyAppBar({
    required this.firstName,
    required this.photoUrl,
    required this.onAvatarTap,
    required this.onBellTap,
  });

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  firstName,
                  style: GoogleFonts.poppins(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          // Bell
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onBellTap();
            },
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
              child: Icon(Icons.notifications_none_rounded,
                  size: 22.w, color: const Color(0xFF64748B)),
            ),
          ),
          SizedBox(width: 8.w),
          // Avatar
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
                color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.r),
                child: photoUrl != null
                    ? Image.network(
                        photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _avatarFallback(),
                      )
                    : _avatarFallback(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return Center(
      child: Icon(Icons.people_rounded,
          size: 22.w, color: const Color(0xFF7C3AED)),
    );
  }
}

// ─── Link Patient Card ────────────────────────────────────────────────────────

class _LinkPatientCard extends ConsumerStatefulWidget {
  const _LinkPatientCard();

  @override
  ConsumerState<_LinkPatientCard> createState() =>
      _LinkPatientCardState();
}

class _LinkPatientCardState extends ConsumerState<_LinkPatientCard> {
  bool _expanded = false;
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final linkState = ref.watch(linkPatientProvider);
    final isLoading = linkState is AsyncLoading;

    return BentoCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40.w,
                width: 40.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.link_rounded,
                    size: 20.w, color: const Color(0xFF7C3AED)),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Link Family Member',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Enter 5-digit access code',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _expanded = !_expanded);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 32.w,
                  width: 32.w,
                  decoration: BoxDecoration(
                    color: _expanded
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.add_rounded,
                    size: 18.w,
                    color: _expanded
                        ? Colors.white
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                SizedBox(height: 14.h),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFA),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                        color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _codeCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 8,
                      color: const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: '• • • • •',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        color: const Color(0xFFCBD5E1),
                        letterSpacing: 8,
                      ),
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 14.h),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                GestureDetector(
                  onTap: isLoading
                      ? null
                      : () async {
                          final code = _codeCtrl.text.trim();
                          if (code.length != 5) return;
                          HapticFeedback.heavyImpact();
                          final messenger =
                              ScaffoldMessenger.of(context);
                          final error = await ref
                              .read(linkPatientProvider.notifier)
                              .link(code);
                          if (!mounted) return;
                          if (error != null) {
                            messenger.showSnackBar(SnackBar(
                              content: Text(error,
                                  style: GoogleFonts.inter(
                                      color: Colors.white)),
                              backgroundColor:
                                  const Color(0xFFEF4444),
                              behavior: SnackBarBehavior.floating,
                            ));
                          } else {
                            _codeCtrl.clear();
                            setState(() => _expanded = false);
                            messenger.showSnackBar(SnackBar(
                              content: Text(
                                  'Patient linked successfully!',
                                  style: GoogleFonts.inter(
                                      color: Colors.white)),
                              backgroundColor:
                                  const Color(0xFF16A34A),
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        },
                  child: Container(
                    height: 46.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED),
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED)
                              .withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Center(
                      child: isLoading
                          ? SizedBox(
                              height: 20.w,
                              width: 20.w,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Connect Patient',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
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
        ],
      ),
    );
  }
}

// ─── Patient Monitor Card ─────────────────────────────────────────────────────

class _PatientMonitorCard extends ConsumerWidget {
  final AssignedPatientModel patient;

  const _PatientMonitorCard({required this.patient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveAsync =
        ref.watch(patientLiveDataProvider(patient.patientId));
    final medStatus =
        ref.watch(patientMedStatusProvider(patient.patientId));

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/caregiver/patient/${patient.patientId}');
      },
      child: BentoCard(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + name
            Row(
              children: [
                Container(
                  height: 36.w,
                  width: 36.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      patient.patientName.isNotEmpty
                          ? patient.patientName[0].toUpperCase()
                          : 'P',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    patient.patientName,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            SizedBox(height: 10.h),
            Divider(color: const Color(0xFFE2E8F0), height: 1.h),
            SizedBox(height: 10.h),

            // Med status chip
            _MedStatusChip(status: medStatus),

            SizedBox(height: 8.h),

            // SOS badge
            liveAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (live) {
                final isSos = live?['isSosActive'] == true;
                if (!isSos) return const SizedBox.shrink();
                return Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: const Color(0xFFEF4444)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 12.w,
                          color: const Color(0xFFEF4444)),
                      SizedBox(width: 4.w),
                      Text(
                        'SOS Active',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const Spacer(),

            // Connected since
            Text(
              'Since ${DateFormat('MMM d').format(patient.connectedAt)}',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: const Color(0xFFCBD5E1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedStatusChip extends StatelessWidget {
  final MedStatus status;
  const _MedStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      MedStatus.allClear => (
          'On Track',
          const Color(0xFF16A34A),
          const Color(0xFFDCFCE7)
        ),
      MedStatus.overdue => (
          'Missed Meds',
          const Color(0xFFEF4444),
          const Color(0xFFFEE2E2)
        ),
      MedStatus.noMeds => (
          'No Meds',
          const Color(0xFF94A3B8),
          const Color(0xFFF1F5F9)
        ),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─── SOS Overlay ─────────────────────────────────────────────────────────────

class _SosOverlay extends StatelessWidget {
  final AssignedPatientModel patient;
  final VoidCallback onResolve;

  const _SosOverlay({required this.patient, required this.onResolve});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.black.withValues(alpha: 0.45),
          child: Center(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 32.w),
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 40,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 64.w,
                    width: 64.w,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.warning_amber_rounded,
                        size: 32.w, color: Colors.white),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'SOS Alert!',
                    style: GoogleFonts.poppins(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    '${patient.patientName} has triggered an emergency alert.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: const Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      onResolve();
                    },
                    child: Container(
                      height: 46.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Center(
                        child: Text(
                          'Mark Resolved',
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
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
          ),
        ),
      ),
    );
  }
}
