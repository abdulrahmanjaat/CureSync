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

// ── Brand palette ─────────────────────────────────────────────────────────────
const Color _purple  = Color(0xFF7C3AED);
const Color _purpleD = Color(0xFF4C1D95);
const Color _bg      = Color(0xFFFAF8FF);

const List<List<Color>> _memberGradients = [
  [Color(0xFF7C3AED), Color(0xFF5B21B6)],
  [Color(0xFF0891B2), Color(0xFF0E7490)],
  [Color(0xFF16A34A), Color(0xFF15803D)],
  [Color(0xFFDB2777), Color(0xFF9D174D)],
  [Color(0xFFF59E0B), Color(0xFFD97706)],
  [Color(0xFF0D9488), Color(0xFF0F766E)],
];

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
class FamilyHomeScreen extends ConsumerWidget {
  const FamilyHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser      = ref.watch(authStateProvider).valueOrNull;
    final firstName     = (authUser?.displayName ?? 'there').split(' ').first;
    final photoUrl      = authUser?.photoURL;
    final patientsAsync = ref.watch(assignedPatientsProvider);
    final patients      = patientsAsync.valueOrNull ?? [];
    final sosPatient    = ref.watch(sosTriggerProvider);
    final missedCount   = ref.watch(totalMissedMedsProvider);

    // Aggregate status across all linked members
    final onTrackCount = patients
        .where((p) =>
            ref.watch(patientMedStatusProvider(p.patientId)) ==
            MedStatus.allClear)
        .length;
    final sosCount = patients
        .where((p) =>
            ref.watch(patientLiveDataProvider(p.patientId)).valueOrNull
                ?['isSosActive'] ==
            true)
        .length;

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // ── Gradient header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _Header(
              firstName: firstName,
              photoUrl: photoUrl,
              memberCount: patients.length,
              onTrackCount: onTrackCount,
              sosCount: sosCount,
              patientsLoaded: patientsAsync.hasValue,
              hasSos: sosPatient != null,
              missedCount: missedCount,
              onBell: () {
                HapticFeedback.lightImpact();
                context.push('/family/notifications');
              },
              onProfile: () {
                HapticFeedback.lightImpact();
                context.push('/profile');
              },
            ),
          ),

          // ── SOS emergency banner ─────────────────────────────────────────
          if (sosPatient != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
                child: _SosBanner(
                  patientName: sosPatient.patientName,
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    context.push(
                        '/caregiver/patient/${sosPatient.patientId}');
                  },
                ),
              ),
            ),

          SliverToBoxAdapter(child: SizedBox(height: 16.h)),

          // ── Link member card ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: const _LinkCard(),
            ).animate().fadeIn(duration: 350.ms, delay: 60.ms),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 20.h)),

          // ── Family-wide status banner ────────────────────────────────────
          if (patients.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: _FamilyStatusBanner(
                  total: patients.length,
                  onTrack: onTrackCount,
                  hasSos: sosPatient != null,
                  missedCount: missedCount,
                ),
              ).animate().fadeIn(duration: 350.ms, delay: 80.ms),
            ),

          if (patients.isNotEmpty) SliverToBoxAdapter(child: SizedBox(height: 20.h)),

          // ── Section title ────────────────────────────────────────────────
          if (patients.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  children: [
                    Text(
                      'Family Members',
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: _purple.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '${patients.length}',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: _purple,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms, delay: 100.ms),
            ),

          if (patients.isNotEmpty) SliverToBoxAdapter(child: SizedBox(height: 12.h)),

          // ── Member cards ─────────────────────────────────────────────────
          if (patients.isNotEmpty)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final p = patients[i];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: _MemberCard(
                        patient: p,
                        colorIdx: i % _memberGradients.length,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push(
                              '/caregiver/patient/${p.patientId}');
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
                  childCount: patients.length,
                ),
              ),
            ),

          // ── Empty state ──────────────────────────────────────────────────
          if (patients.isEmpty && patientsAsync.hasValue)
            SliverToBoxAdapter(
              child: _EmptyState()
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 120.ms),
            ),

          SliverToBoxAdapter(child: SizedBox(height: 120.h)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Header
// ════════════════════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final String firstName;
  final String? photoUrl;
  final int memberCount;
  final int onTrackCount;
  final int sosCount;
  final bool patientsLoaded;
  final bool hasSos;
  final int missedCount;
  final VoidCallback onBell;
  final VoidCallback onProfile;

  const _Header({
    required this.firstName,
    required this.photoUrl,
    required this.memberCount,
    required this.onTrackCount,
    required this.sosCount,
    required this.patientsLoaded,
    required this.hasSos,
    required this.missedCount,
    required this.onBell,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    // Gradient shifts to red-tint when SOS is active
    final gradientColors = hasSos
        ? [const Color(0xFFDC2626), const Color(0xFF7C3AED)]
        : [const Color(0xFF8B5CF6), _purpleD];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Ambient blobs
          Positioned(
            top: -30.h, right: -40.w,
            child: Container(
              height: 190.w, width: 190.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            top: 55.h, right: 22.w,
            child: Container(
              height: 80.w, width: 80.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 24.h, left: -18.w,
            child: Container(
              height: 110.w, width: 110.w,
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
                  // ── App bar row ──────────────────────────────────────
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
                              color: Colors.white.withValues(alpha: 0.75),
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
                          // Bell with badge
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
                                    Icons.notifications_none_rounded,
                                    size: 22.w,
                                    color: Colors.white,
                                  ),
                                ),
                                if (missedCount > 0)
                                  Positioned(
                                    top: -4,
                                    right: -4,
                                    child: Container(
                                      height: 18.w,
                                      constraints:
                                          BoxConstraints(minWidth: 18.w),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 3.w),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        borderRadius:
                                            BorderRadius.circular(9.r),
                                        border: Border.all(
                                            color: Colors.white,
                                            width: 1.5),
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
                          // Avatar
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

                  // Role pill
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
                        Icon(Icons.favorite_rounded,
                            size: 12.w,
                            color:
                                Colors.white.withValues(alpha: 0.9)),
                        SizedBox(width: 5.w),
                        Text(
                          patientsLoaded
                              ? 'Monitoring $memberCount member${memberCount == 1 ? '' : 's'}'
                              : 'Family Care',
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

                  // ── Stat strip ───────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _HeaderStat(
                          icon: Icons.people_rounded,
                          value: patientsLoaded ? '$memberCount' : '–',
                          label: 'Members',
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _HeaderStat(
                          icon: Icons.check_circle_rounded,
                          value: patientsLoaded ? '$onTrackCount' : '–',
                          label: 'On Track',
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _HeaderStat(
                          icon: sosCount > 0
                              ? Icons.warning_rounded
                              : Icons.shield_rounded,
                          value: patientsLoaded ? '$sosCount' : '–',
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
        child: Icon(Icons.people_rounded,
            size: 20.w,
            color: Colors.white.withValues(alpha: 0.9)),
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
                  color: isAlert
                      ? const Color(0xFFFF8FA3)
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
// SOS emergency banner
// ════════════════════════════════════════════════════════════════════════════
class _SosBanner extends StatelessWidget {
  final String patientName;
  final VoidCallback onTap;
  const _SosBanner({required this.patientName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          ),
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 42.w,
              width: 42.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_rounded,
                  size: 22.w, color: Colors.white),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SOS ALERT',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.80),
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '$patientName needs help!',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                'RESPOND',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFDC2626),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
            duration: 1800.ms,
            color: Colors.white.withValues(alpha: 0.10));
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Family-wide status banner
// ════════════════════════════════════════════════════════════════════════════
class _FamilyStatusBanner extends StatelessWidget {
  final int total;
  final int onTrack;
  final bool hasSos;
  final int missedCount;

  const _FamilyStatusBanner({
    required this.total,
    required this.onTrack,
    required this.hasSos,
    required this.missedCount,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String message;

    if (hasSos) {
      color   = const Color(0xFFEF4444);
      icon    = Icons.warning_rounded;
      message = 'Emergency alert is active!';
    } else if (missedCount > 0) {
      color   = const Color(0xFFF59E0B);
      icon    = Icons.info_rounded;
      message = '$missedCount member${missedCount == 1 ? '' : 's'} missed a dose today';
    } else if (total > 0 && onTrack == total) {
      color   = const Color(0xFF16A34A);
      icon    = Icons.check_circle_rounded;
      message = 'Everyone is on track today 🎉';
    } else {
      color   = _purple;
      icon    = Icons.monitor_heart_rounded;
      message = 'Monitoring $total family member${total == 1 ? '' : 's'}';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
            color: color.withValues(alpha: 0.20), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18.w, color: color),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Link patient card
// ════════════════════════════════════════════════════════════════════════════
class _LinkCard extends ConsumerStatefulWidget {
  const _LinkCard();

  @override
  ConsumerState<_LinkCard> createState() => _LinkCardState();
}

class _LinkCardState extends ConsumerState<_LinkCard> {
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────────────
            Row(
              children: [
                Container(
                  height: 46.w,
                  width: 46.w,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), _purpleD],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15.r),
                    boxShadow: [
                      BoxShadow(
                        color: _purple.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(Icons.person_add_rounded,
                      size: 22.w, color: Colors.white),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Link a Family Member',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Enter their 5-digit access code',
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
                    height: 34.w,
                    width: 34.w,
                    decoration: BoxDecoration(
                      color: _expanded
                          ? _purple
                          : const Color(0xFFF3F0FF),
                      borderRadius: BorderRadius.circular(11.r),
                    ),
                    child: Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.add_rounded,
                      size: 20.w,
                      color: _expanded
                          ? Colors.white
                          : _purple,
                    ),
                  ),
                ),
              ],
            ),

            // ── Expandable input ────────────────────────────────────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  SizedBox(height: 16.h),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F5FF),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: _purple.withValues(alpha: 0.20),
                        width: 1.5,
                      ),
                    ),
                    child: TextField(
                      controller: _codeCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 5,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 10,
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
                            EdgeInsets.symmetric(vertical: 16.h),
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
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12.r)),
                              ));
                            } else {
                              _codeCtrl.clear();
                              setState(() => _expanded = false);
                              messenger.showSnackBar(SnackBar(
                                content: Text(
                                    'Member linked successfully!',
                                    style: GoogleFonts.inter(
                                        color: Colors.white)),
                                backgroundColor:
                                    const Color(0xFF16A34A),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12.r)),
                              ));
                            }
                          },
                    child: Container(
                      height: 50.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isLoading
                              ? [
                                  _purple.withValues(alpha: 0.5),
                                  _purpleD.withValues(alpha: 0.5),
                                ]
                              : [const Color(0xFF8B5CF6), _purpleD],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: isLoading
                            ? []
                            : [
                                BoxShadow(
                                  color:
                                      _purple.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
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
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.link_rounded,
                                      size: 18.w,
                                      color: Colors.white),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Connect Member',
                                    style: GoogleFonts.inter(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
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
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Member card
// ════════════════════════════════════════════════════════════════════════════
class _MemberCard extends ConsumerWidget {
  final AssignedPatientModel patient;
  final int colorIdx;
  final VoidCallback onTap;

  const _MemberCard({
    required this.patient,
    required this.colorIdx,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medStatus  = ref.watch(patientMedStatusProvider(patient.patientId));
    final medsAsync  = ref.watch(assignedPatientMedsProvider(patient.patientId));
    final takenAsync = ref.watch(patientTakenKeysProvider(patient.patientId));
    final liveAsync  = ref.watch(patientLiveDataProvider(patient.patientId));

    final meds      = medsAsync.valueOrNull ?? [];
    final takenKeys = takenAsync.valueOrNull ?? [];
    final isSos     = liveAsync.valueOrNull?['isSosActive'] == true;
    final activeMeds =
        meds.where((m) => m.isActive && !m.isExpired).toList();

    // Compute today's adherence
    int totalDoses = 0, takenDoses = 0;
    final now     = DateTime.now();
    final nowMins = now.hour * 60 + now.minute;
    String? nextDoseTime;
    int? nextMins;

    for (final med in activeMeds) {
      for (final time in med.reminderTimes) {
        totalDoses++;
        final key = '${med.id}_$time';
        if (takenKeys.contains(key)) {
          takenDoses++;
        } else {
          final parts = time.split(':');
          if (parts.length == 2) {
            final h   = int.tryParse(parts[0]) ?? 0;
            final m   = int.tryParse(parts[1]) ?? 0;
            final medMins = h * 60 + m;
            if (medMins >= nowMins) {
              if (nextMins == null || medMins < nextMins) {
                nextMins = medMins;
                final hr   = h == 0 ? 12 : (h > 12 ? h - 12 : h);
                final ampm = h < 12 ? 'AM' : 'PM';
                nextDoseTime =
                    '$hr:${m.toString().padLeft(2, '0')} $ampm';
              }
            }
          }
        }
      }
    }

    final adherencePct =
        totalDoses > 0 ? (takenDoses * 100.0 / totalDoses) : 0.0;
    final colors       = _memberGradients[colorIdx];
    final primaryColor = colors[0];
    final initial      = patient.patientName.isNotEmpty
        ? patient.patientName[0].toUpperCase()
        : 'P';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: [
            BoxShadow(
              color: isSos
                  ? const Color(0xFFEF4444).withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 5),
              spreadRadius: isSos ? 1 : 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SOS top strip
              if (isSos)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                      horizontal: 16.w, vertical: 9.h),
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
                        'SOS ACTIVE — needs attention',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                        duration: 1600.ms,
                        color: Colors.white.withValues(alpha: 0.12)),

              Padding(
                padding: EdgeInsets.all(18.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Identity row ─────────────────────────────────
                    Row(
                      children: [
                        // Gradient avatar
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
                              initial,
                              style: GoogleFonts.poppins(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                patient.patientName,
                                style: GoogleFonts.poppins(
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Since ${DateFormat('MMM d, yyyy').format(patient.connectedAt)}',
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  color: const Color(0xFF94A3B8),
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

                    // ── Adherence bar ────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          totalDoses == 0
                              ? 'No schedule'
                              : '$takenDoses/$totalDoses · ${adherencePct.round()}%',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: totalDoses == 0
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
                        value: totalDoses == 0
                            ? 0
                            : adherencePct / 100,
                        minHeight: 8.h,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          totalDoses == 0
                              ? const Color(0xFFE2E8F0)
                              : _adherenceColor(adherencePct),
                        ),
                      ),
                    ),

                    SizedBox(height: 14.h),

                    // ── Status + info chips ──────────────────────────
                    Row(
                      children: [
                        // Status chip
                        _StatusChip(status: medStatus),
                        SizedBox(width: 6.w),
                        _InfoChip(
                          icon: Icons.medication_rounded,
                          label:
                              '${activeMeds.length} med${activeMeds.length == 1 ? '' : 's'}',
                          color: primaryColor,
                        ),
                        if (nextDoseTime != null) ...[
                          SizedBox(width: 6.w),
                          _InfoChip(
                            icon: Icons.schedule_rounded,
                            label: nextDoseTime,
                            color: const Color(0xFF0891B2),
                          ),
                        ],
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

// ── Status chip ───────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final MedStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg, icon) = switch (status) {
      MedStatus.allClear => (
          'On Track',
          const Color(0xFF16A34A),
          const Color(0xFFDCFCE7),
          Icons.check_circle_rounded,
        ),
      MedStatus.overdue => (
          'Missed Dose',
          const Color(0xFFEF4444),
          const Color(0xFFFEE2E2),
          Icons.alarm_off_rounded,
        ),
      MedStatus.noMeds => (
          'No Meds',
          const Color(0xFF94A3B8),
          const Color(0xFFF1F5F9),
          Icons.medication_outlined,
        ),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: bg,
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
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info chip ─────────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(
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

// ════════════════════════════════════════════════════════════════════════════
// Empty state
// ════════════════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 48.h, 20.w, 0),
      child: Column(
        children: [
          Container(
            height: 90.w,
            width: 90.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), _purpleD],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _purple.withValues(alpha: 0.25),
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
            'No members linked yet',
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Tap "Link a Family Member" above\nand enter their 5-digit code to start monitoring.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0xFF94A3B8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
