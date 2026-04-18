import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/data/models/patient_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/patient_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/dashboard/bento_card.dart';
import '../widgets/dashboard/adherence_ring_widget.dart';
import '../widgets/dashboard/smart_action_card.dart';
import '../widgets/dashboard/pill_timeline.dart';
import '../widgets/dashboard/vitals_bento.dart';
import '../widgets/dashboard/lifestyle_strip.dart';
import '../widgets/dashboard/sos_slider.dart';
import '../widgets/dashboard/access_code_card.dart';
import '../../../notifications/presentation/screens/notification_history_screen.dart';
import '../../../../core/services/notification_service.dart';

// Fetches a user profile by UID — used for care circle and assigned caregiver
final _caregiverUserProvider =
    StreamProvider.autoDispose.family<UserModel?, String>((ref, uid) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((s) => s.exists ? UserModel.fromFirestore(s) : null);
});

// ═══════════════════════════════════════════════════════════════════
class HomeScreen extends ConsumerWidget {
  /// When [trackingOnly] is true the dashboard is rendered in read-only
  /// tracking mode for a Manager viewing a sub-patient:
  ///   • Shows: Adherence Ring, Add Med, Pill Timeline, Vitals,
  ///            LifestyleStrip, Assigned Caregiver footer.
  ///   • Hides: SOS slider, Quick Actions, Care Circle card,
  ///            and the greeting/notification/profile App Bar row.
  ///   • Replaces App Bar row with a patient-name context header.
  final bool trackingOnly;

  /// Controls whether the Assigned Caregiver footer is shown in
  /// [trackingOnly] mode. Set to false when a caregiver is viewing
  /// the patient dashboard — the card is only relevant for patients
  /// and managers.
  final bool showCaregiverCard;

  const HomeScreen({
    super.key,
    this.trackingOnly = false,
    this.showCaregiverCard = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final firstName = (authUser?.displayName ?? 'User').split(' ').first;

    // Local Drift image takes priority over Firebase Auth photoURL
    final imageRecord = ref.watch(profileImageRecordProvider).valueOrNull;
    final localPath   = imageRecord?.localImagePath;
    final hasLocal    = localPath != null && File(localPath).existsSync();
    final photoUrl    = authUser?.photoURL;

    // ── Patient-role: ensure self-document exists then use uid directly ──────
    // selfPatientInitProvider is idempotent — it creates patients/{uid} once
    // and is a no-op on every subsequent call.
    if (!trackingOnly) ref.watch(selfPatientInitProvider);

    // Patient dashboard  → locked to the logged-in user's own UID.
    // Manager tracking   → resolves the explicitly-selected patient.
    final selfId   = ref.watch(selfPatientIdProvider);
    final activeId = trackingOnly
        ? ref.watch(resolvedActivePatientIdProvider)
        : selfId;

    // Own patient document — direct doc read, available as soon as Firestore
    // responds (no query required). Used for the access code card.
    final selfPatientDoc = !trackingOnly
        ? ref.watch(selfPatientDocProvider).valueOrNull
        : null;

    // Active patient object — used for the trackingOnly header and caregiver footer.
    // In trackingOnly mode read the patient doc directly so the name shows even
    // when the caller is a caregiver (patientsStreamProvider filters by managerId
    // and returns empty for caregivers).
    PatientModel? activePatient;
    if (trackingOnly && activeId != null) {
      activePatient =
          ref.watch(patientDocStreamProvider(activeId)).valueOrNull;
    } else {
      final allPatients =
          ref.watch(patientsStreamProvider).valueOrNull ?? [];
      if (activeId != null) {
        final matches = allPatients.where((p) => p.patientId == activeId);
        if (matches.isNotEmpty) activePatient = matches.first;
      }
    }

    // Derived data — empty/zero when no patient selected
    final adherence = activeId != null
        ? ref.watch(todayAdherenceProvider(activeId))
        : (taken: 0, total: 0);

    final timelineEntries = activeId != null
        ? ref.watch(todayPillTimelineProvider(activeId))
        : <PillTimelineEntry>[];

    final nextDose =
        activeId != null ? ref.watch(nextDoseProvider(activeId)) : null;

    // Countdown label for the SmartActionCard ("2h 15m", "45m", …).
    // Recomputed each build since the home screen rebuilds every minute
    // via the minuteTickProvider dependency chain.
    final countdownLabel = _countdownLabel(nextDose);

    final adherencePct =
        adherence.total == 0 ? 0.0 : adherence.taken / adherence.total;

    // Care circle data — all UIDs in accessList from the patient's own document.
    // Uses selfPatientDocProvider (direct doc read) which is always up-to-date
    // and avoids depending on the managerId-query-based patientsStreamProvider.
    final caregiverIds = !trackingOnly
        ? (selfPatientDoc?.accessList ?? [])
        : <String>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFA),
      body: Stack(
        children: [
          /// ─── Faint teal mesh gradient ───
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
                  // ═══════════════════════════════════════════════════════════
                  // APP BAR ROW — switches between full and tracking-only header
                  // ═══════════════════════════════════════════════════════════

                  if (!trackingOnly)
                    /// Full mode: greeting + notification bell + profile avatar
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
                              badgeCount: ref
                                  .watch(notificationHistoryProvider)
                                  .where((n) => !n.isRead)
                                  .length,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                context.push('/notifications');
                              },
                            ),
                            SizedBox(width: 8.w),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                context.push('/profile');
                              },
                              child: Container(
                                height: 42.w,
                                width: 42.w,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14.r),
                                  child: hasLocal
                                      ? Image.file(
                                          File(localPath),
                                          fit: BoxFit.cover,
                                        )
                                      : photoUrl != null
                                          ? Image.network(
                                              photoUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  _buildAvatarFallback(firstName),
                                            )
                                          : _buildAvatarFallback(firstName),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: -0.08, end: 0, duration: 400.ms)
                  else
                    /// Tracking-only mode: patient context header.
                    /// Left-padded to clear the back button injected by
                    /// ManagerPatientViewScreen (40.w button + 16.w gap = 56.w).
                    Padding(
                      padding: EdgeInsets.only(left: 56.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tracking View',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            activePatient?.name ?? 'Patient',
                            style: GoogleFonts.poppins(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          if (activePatient != null)
                            Text(
                              '${activePatient.relation} · ${activePatient.age} yrs',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: -0.08, end: 0, duration: 400.ms),

                  SizedBox(height: 22.h),

                  // ═══════════════════════════════════════════════════════════
                  // BENTO ROW: Adherence Ring + Smart Action + Add Med
                  // Identical in both modes — tracking is the core purpose.
                  // ═══════════════════════════════════════════════════════════
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: AdherenceRingWidget(
                          percentage: adherencePct,
                          taken: adherence.taken,
                          remaining: adherence.total - adherence.taken,
                        )
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
                              medName: nextDose?.medName,
                              time: nextDose?.time,
                              isDue: nextDose?.isDue ?? false,
                              countdownLabel: countdownLabel,
                              // Only allow marking done when the dose is
                              // actually due — prevents pre-emptive logging.
                              onDone: (nextDose?.isDue ?? false) &&
                                      nextDose != null &&
                                      activeId != null
                                  ? () => _markDone(ref, activeId, nextDose)
                                  : null,
                            )
                                .animate()
                                .fadeIn(duration: 400.ms, delay: 160.ms)
                                .scale(
                                  begin: const Offset(0.96, 0.96),
                                  duration: 400.ms,
                                  delay: 160.ms,
                                ),
                            SizedBox(height: 12.h),

                            /// ─── ADD MED BENTO ───
                            BentoCard(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                // activeId is always the user's own UID in
                                // patient mode (selfPatientInitProvider ensures
                                // the doc exists before the dashboard renders).
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
                                    'Add Medication',
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

                  // ═══════════════════════════════════════════════════════════
                  // PILL TIMELINE — shown in both modes
                  // ═══════════════════════════════════════════════════════════
                  PillTimeline(
                    entries: timelineEntries,
                    onToggle: activeId != null
                        ? (entry) => _toggleDose(ref, activeId, entry)
                        : null,
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 300.ms)
                      .scale(
                        begin: const Offset(0.96, 0.96),
                        duration: 400.ms,
                        delay: 300.ms,
                      ),

                  SizedBox(height: 16.h),

                  // ═══════════════════════════════════════════════════════════
                  // LIFESTYLE STRIP — shown in both modes
                  // ═══════════════════════════════════════════════════════════
                  LifestyleStrip(patientId: activeId)
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 360.ms),

                  SizedBox(height: 16.h),

                  // ═══════════════════════════════════════════════════════════
                  // VITALS BENTO — shown in both modes
                  // ═══════════════════════════════════════════════════════════
                  VitalsBento(patientId: activeId)
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 420.ms)
                      .scale(
                        begin: const Offset(0.96, 0.96),
                        duration: 400.ms,
                        delay: 420.ms,
                      ),

                  SizedBox(height: 16.h),

                  // ═══════════════════════════════════════════════════════════
                  // SOS SLIDER — full mode only
                  // ═══════════════════════════════════════════════════════════
                  if (!trackingOnly) ...[
                    SosSlider(
                      onTriggered: () async {
                        // Write isSosActive to Firestore so caregivers
                        // watching patientLiveDataProvider are notified.
                        final patientId = selfId;
                        if (patientId != null) {
                          await FirebaseFirestore.instance
                              .collection('patients')
                              .doc(patientId)
                              .set(
                            {
                              'isSosActive': true,
                              'sosTriggerTime':
                                  FieldValue.serverTimestamp(),
                            },
                            SetOptions(merge: true),
                          );
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'SOS alert sent!',
                                style: GoogleFonts.inter(color: Colors.white),
                              ),
                              backgroundColor: const Color(0xFFEF4444),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r)),
                            ),
                          );
                        }
                      },
                    ).animate().fadeIn(duration: 400.ms, delay: 480.ms),

                    SizedBox(height: 16.h),

                    // ═══════════════════════════════════════════════════════
                    // ACCESS CODE CARD — full mode only
                    // Direct doc stream so it appears even before the
                    // patientsStreamProvider query resolves.
                    // ═══════════════════════════════════════════════════════
                    AccessCodeCard(patient: selfPatientDoc)
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 500.ms),

                    SizedBox(height: 20.h),

                    // ═══════════════════════════════════════════════════════
                    // QUICK ACTIONS — full mode only
                    // ═══════════════════════════════════════════════════════
                    Text(
                      'Quick Actions',
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 520.ms),
                    SizedBox(height: 12.h),

                    Row(
                      children: [
                        _QuickAction(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'Message\nDoctor',
                          color: const Color(0xFF0D9488),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.push('/discovery');
                          },
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
                          onTap: () {
                            HapticFeedback.lightImpact();
                            if (activeId != null) {
                              context.push(
                                '/patient/$activeId/report',
                                extra: authUser?.displayName ?? 'Patient',
                              );
                            }
                          },
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms, delay: 560.ms),

                    SizedBox(height: 20.h),

                    // ═══════════════════════════════════════════════════════
                    // CARE CIRCLE CARD — full mode only
                    // ═══════════════════════════════════════════════════════
                    _CareCircleCard(caregiverIds: caregiverIds)
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 600.ms),

                  ],

                  // ═══════════════════════════════════════════════════════════
                  // ASSIGNED CAREGIVER FOOTER — tracking-only mode
                  // Reads caregiverId directly from the active patient document.
                  // Data is scoped strictly to this patientId via the
                  // ProviderScope override in ManagerPatientViewScreen.
                  // ═══════════════════════════════════════════════════════════
                  if (trackingOnly && showCaregiverCard) ...[
                    SizedBox(height: 4.h),
                    _AssignedCaregiverCard(
                      caregiverId: activePatient?.caregiverId,
                      patientName: activePatient?.name ?? 'Patient',
                    ).animate().fadeIn(duration: 400.ms, delay: 480.ms),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns a human-readable countdown string ("2h 15m", "45m") until
  /// the given [entry]'s scheduled time, or null if already due / no entry.
  String? _countdownLabel(PillTimelineEntry? entry) {
    if (entry == null || entry.isDue) return null;
    final parts = entry.rawTime.split(':');
    if (parts.length != 2) return null;
    final doseMinutes =
        (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final diff = doseMinutes - nowMinutes;
    if (diff <= 0) return null;
    final h = diff ~/ 60;
    final m = diff % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  Widget _buildAvatarFallback(String firstName) {
    return Container(
      color: const Color(0xFF0D9488),
      child: Center(
        child: Text(
          firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _markDone(WidgetRef ref, String patientId, PillTimelineEntry entry) {
    HapticFeedback.lightImpact();
    ref.read(medicationRepositoryProvider).markDoseTaken(
          patientId:    patientId,
          medId:        entry.medId,
          medName:      entry.medName,
          reminderTime: entry.rawTime,
        );
    // Cancel all four daily alerts (early-warning, at-time, overdue, SOS)
    // for today.  The recurring schedule re-arms automatically tomorrow.
    NotificationService.cancelDoseAlerts(
      medId:        entry.medId,
      reminderTime: entry.rawTime,
    );
  }

  void _toggleDose(WidgetRef ref, String patientId, PillTimelineEntry entry) {
    if (entry.isTaken) {
      // ── Unmark: dose log removed → re-arm all four daily alerts ──────────
      ref.read(medicationRepositoryProvider).unmarkDoseTaken(
            patientId:    patientId,
            medId:        entry.medId,
            reminderTime: entry.rawTime,
          );
      // Re-schedule the full escalation stack so overdue/SOS will fire
      // if the patient doesn't re-confirm the dose.
      NotificationService.scheduleDoseAlerts(
        medId:        entry.medId,
        medName:      entry.medName,
        dosage:       entry.dosage,
        reminderTime: entry.rawTime,
      ).catchError((_) {});
    } else {
      // ── Mark taken: write Firestore + silence all alerts ─────────────────
      ref.read(medicationRepositoryProvider).markDoseTaken(
            patientId:    patientId,
            medId:        entry.medId,
            medName:      entry.medName,
            reminderTime: entry.rawTime,
          );
      NotificationService.cancelDoseAlerts(
        medId:        entry.medId,
        reminderTime: entry.rawTime,
      );
    }
  }
}

// ─── Assigned Caregiver Footer ─────────────────────────────────────────────────
// Shown only in trackingOnly mode at the bottom of the dashboard.
// caregiverId comes from patients/{patientId}.caregiverId — already fetched
// as part of patientsStreamProvider, no additional Firestore read needed
// beyond the single user profile lookup for display name/specialty.

class _AssignedCaregiverCard extends ConsumerWidget {
  final String? caregiverId;
  final String patientName;

  const _AssignedCaregiverCard({
    required this.caregiverId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BentoCard(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                height: 36.w,
                width: 36.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFDB2777).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.badge_rounded,
                    size: 20.w, color: const Color(0xFFDB2777)),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assigned Caregiver',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'For $patientName',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),
          Divider(color: const Color(0xFFE2E8F0), height: 1.h),
          SizedBox(height: 10.h),

          // ── Content: caregiver row OR empty state ──
          if (caregiverId == null || caregiverId!.isEmpty)
            _NoCaregiverState()
          else
            _CaregiverDetailRow(caregiverId: caregiverId!),
        ],
      ),
    );
  }
}

class _NoCaregiverState extends StatelessWidget {
  const _NoCaregiverState();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.person_off_outlined,
            size: 18.w, color: const Color(0xFFCBD5E1)),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            'No caregiver assigned yet. Hire one from the Discover tab.',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: const Color(0xFF94A3B8),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _CaregiverDetailRow extends ConsumerWidget {
  final String caregiverId;
  const _CaregiverDetailRow({required this.caregiverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(_caregiverUserProvider(caregiverId));

    return userAsync.when(
      loading: () => Row(
        children: [
          Container(
            height: 40.w,
            width: 40.w,
            decoration: const BoxDecoration(
              color: Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 10.h,
                width: 120.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 4.h),
              Container(
                height: 8.h,
                width: 80.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ],
          ),
        ],
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (user) {
        final name =
            user?.name.isNotEmpty == true ? user!.name : 'Caregiver';
        final isFamily = user?.role == 'family';
        final roleLabel = isFamily ? 'Family Member' : 'Pro Caregiver';
        const accent = Color(0xFF0D9488);

        return Row(
          children: [
            // Avatar
            Container(
              height: 40.w,
              width: 40.w,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),

            // Name + role
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    roleLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),

            // Active status dot
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 7.w,
                  width: 7.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 5.w),
                Text(
                  'Active',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ─── Care Circle Card ─────────────────────────────────────────────────────────

class _CareCircleCard extends StatelessWidget {
  final List<String> caregiverIds;
  const _CareCircleCard({required this.caregiverIds});

  @override
  Widget build(BuildContext context) {
    final hasCarers = caregiverIds.isNotEmpty;

    return GestureDetector(
      onTap: hasCarers
          ? () {
              HapticFeedback.lightImpact();
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) =>
                    _AccessInfoSheet(caregiverIds: caregiverIds),
              );
            }
          : null,
      child: BentoCard(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 36.w,
                  width: 36.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Icons.shield_rounded,
                      size: 20.w, color: const Color(0xFF0D9488)),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Care Circle',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        hasCarers
                            ? '${caregiverIds.length} ${caregiverIds.length == 1 ? 'person has' : 'people have'} access'
                            : 'No active caregivers',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasCarers)
                  Icon(Icons.chevron_right_rounded,
                      size: 20.w, color: const Color(0xFFCBD5E1)),
              ],
            ),

            SizedBox(height: 12.h),
            Divider(color: const Color(0xFFE2E8F0), height: 1.h),
            SizedBox(height: 10.h),

            if (!hasCarers)
              Row(
                children: [
                  Icon(Icons.link_off_rounded,
                      size: 18.w, color: const Color(0xFFCBD5E1)),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'No active caregivers. Share your code to connect.',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: const Color(0xFF94A3B8),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              )
            else ...[
              ...caregiverIds.take(3).map(
                    (id) => Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: _CaregiverRow(caregiverId: id),
                    ),
                  ),
              if (caregiverIds.length > 3)
                Text(
                  '+${caregiverIds.length - 3} more',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: const Color(0xFF0D9488),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Caregiver Row (fetches live user data) ───────────────────────────────────

class _CaregiverRow extends ConsumerWidget {
  final String caregiverId;
  const _CaregiverRow({required this.caregiverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(_caregiverUserProvider(caregiverId));

    return userAsync.when(
      loading: () => Row(
        children: [
          Container(
            height: 32.w,
            width: 32.w,
            decoration: const BoxDecoration(
              color: Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 10.w),
          Container(
            height: 10.h,
            width: 100.w,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ],
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (user) {
        final name =
            user?.name.isNotEmpty == true ? user!.name : 'Caregiver';
        final role = user?.role ?? 'caregiver';
        final isFamily = role == 'family';
        final roleLabel = isFamily ? 'Family' : 'Professional';
        final roleColor = isFamily
            ? const Color(0xFF7C3AED)
            : const Color(0xFF0D9488);

        return Row(
          children: [
            Container(
              height: 32.w,
              width: 32.w,
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: roleColor,
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    roleLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: roleColor,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 7.w,
                  width: 7.w,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 5.w),
                Text(
                  'Connected',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ─── Access Info Bottom Sheet ─────────────────────────────────────────────────

class _AccessInfoSheet extends ConsumerWidget {
  final List<String> caregiverIds;
  const _AccessInfoSheet({required this.caregiverIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Icon(Icons.shield_rounded,
                  color: const Color(0xFF0D9488), size: 22.w),
              SizedBox(width: 10.w),
              Text(
                'Who can see your data',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'These people have been granted access to your health records via your access code.',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          SizedBox(height: 20.h),
          Divider(color: const Color(0xFFE2E8F0), height: 1.h),
          SizedBox(height: 12.h),
          ...caregiverIds.map(
            (id) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _CaregiverRow(caregiverId: id),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header Icon ─────────────────────────────────────────────────────────────

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  const _HeaderIcon({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
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
          if (badgeCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                height: badgeCount > 9 ? 18.w : 16.w,
                constraints: BoxConstraints(minWidth: 16.w),
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
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
    );
  }
}

// ─── Quick Action ─────────────────────────────────────────────────────────────

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
