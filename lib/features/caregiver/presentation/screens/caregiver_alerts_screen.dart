import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/models/deal_request_model.dart';
import '../providers/caregiver_provider.dart';

class CaregiverAlertsScreen extends ConsumerStatefulWidget {
  const CaregiverAlertsScreen({super.key});

  @override
  ConsumerState<CaregiverAlertsScreen> createState() =>
      _CaregiverAlertsScreenState();
}

class _CaregiverAlertsScreenState
    extends ConsumerState<CaregiverAlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sosPatient = ref.watch(sosTriggerProvider);
    final missedCount = ref.watch(totalMissedMedsProvider);
    final pendingDeals = ref.watch(pendingDealCountProvider);
    final totalAlerts =
        (sosPatient != null ? 1 : 0) + missedCount + pendingDeals;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      // NestedScrollView is intentionally NOT used here.
      // NestedScrollView requires every tab body to expose a primary scroll
      // controller; non-scrollable bodies (e.g. _EmptyState) cause a layout
      // freeze. A simple Column + Expanded avoids that entirely.
      body: Column(
        children: [
          // ── Gradient header ──────────────────────────────────────────────
          _AlertsHeader(
            totalAlerts: totalAlerts,
            sosCount: sosPatient != null ? 1 : 0,
            missedCount: missedCount,
            pendingCount: pendingDeals,
            onBack: Navigator.canPop(context) ? () => context.pop() : null,
          ),

          // ── Pinned tab bar ───────────────────────────────────────────────
          Container(
            color: const Color(0xFFF1F5F9),
            child: TabBar(
              controller: _tabController,
              labelPadding: EdgeInsets.symmetric(horizontal: 4.w),
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              padding:
                  EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              tabs: [
                _TabItem(
                  icon: Icons.sos_rounded,
                  label: 'Emergency',
                  badge: sosPatient != null ? 1 : 0,
                  color: const Color(0xFFEF4444),
                ),
                _TabItem(
                  icon: Icons.medication_rounded,
                  label: 'Missed Meds',
                  badge: missedCount,
                  color: const Color(0xFFF59E0B),
                ),
                _TabItem(
                  icon: Icons.handshake_rounded,
                  label: 'Hiring',
                  badge: pendingDeals,
                  color: const Color(0xFF0D9488),
                ),
              ],
            ),
          ),

          // ── Tab content fills remaining height ───────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _EmergencyTab(),
                _MissedMedsTab(),
                _HiringTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Alerts Header ────────────────────────────────────────────────────────────

class _AlertsHeader extends StatelessWidget {
  final int totalAlerts;
  final int sosCount;
  final int missedCount;
  final int pendingCount;
  final VoidCallback? onBack;

  const _AlertsHeader({
    required this.totalAlerts,
    required this.sosCount,
    required this.missedCount,
    required this.pendingCount,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final hasAlert = totalAlerts > 0;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20.w, MediaQuery.of(context).padding.top + 16.h, 20.w, 24.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasAlert
              ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
              : [const Color(0xFF0D9488), const Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(32.r)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button + title row
          Row(
            children: [
              if (onBack != null)
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    height: 36.w,
                    width: 36.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16.w,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (onBack != null) SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  hasAlert ? 'Active Alerts' : 'All Clear',
                  style: GoogleFonts.poppins(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              // Total badge
              if (totalAlerts > 0)
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '$totalAlerts alert${totalAlerts == 1 ? '' : 's'}',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            hasAlert
                ? 'Immediate attention required'
                : 'No active emergencies or missed meds',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),

          SizedBox(height: 20.h),

          // ── Stat chips ──────────────────────────────────────────────
          Row(
            children: [
              _StatChip(
                icon: Icons.sos_rounded,
                label: 'SOS',
                count: sosCount,
                activeColor: Colors.white,
              ),
              SizedBox(width: 10.w),
              _StatChip(
                icon: Icons.medication_rounded,
                label: 'Missed',
                count: missedCount,
                activeColor: Colors.white,
              ),
              SizedBox(width: 10.w),
              _StatChip(
                icon: Icons.handshake_rounded,
                label: 'Requests',
                count: pendingCount,
                activeColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.04, end: 0, duration: 350.ms);
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color activeColor;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: count > 0 ? 0.22 : 0.10),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: count > 0 ? 0.4 : 0.15),
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 18.w,
                color: Colors.white.withValues(alpha: count > 0 ? 1 : 0.5)),
            SizedBox(height: 4.h),
            Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: count > 0 ? 1 : 0.5),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                color: Colors.white.withValues(alpha: count > 0 ? 0.9 : 0.45),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ─── Tab Item ─────────────────────────────────────────────────────────────────

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badge;
  final Color color;

  const _TabItem({
    required this.icon,
    required this.label,
    required this.badge,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 42.h,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14.w),
              SizedBox(width: 5.w),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (badge > 0)
            Positioned(
              top: -2.h,
              right: -10.w,
              child: Container(
                height: 15.w,
                width: 15.w,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$badge',
                    style: GoogleFonts.inter(
                      fontSize: 8.sp,
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

// ─── Emergency Tab ────────────────────────────────────────────────────────────

class _EmergencyTab extends ConsumerWidget {
  const _EmergencyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sosPatient = ref.watch(sosTriggerProvider);

    if (sosPatient == null) {
      return const _EmptyState(
        icon: Icons.shield_rounded,
        iconColor: Color(0xFF16A34A),
        title: 'All Clear',
        subtitle: 'No active emergencies from any\nof your patients.',
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
      child: Column(
        children: [
          // ── SOS Alert Card ──────────────────────────────────────────
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      height: 56.w,
                      width: 56.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.sos_rounded,
                          size: 30.w, color: Colors.white),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SOS ALERT',
                            style: GoogleFonts.poppins(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.75),
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            sosPatient.patientName,
                            style: GoogleFonts.poppins(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Emergency alert triggered — respond now',
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
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.heavyImpact();
                          context.push(
                              '/caregiver/patient/${sosPatient.patientId}');
                        },
                        child: Container(
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: Center(
                            child: Text(
                              'View Dashboard',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Consumer(
                        builder: (_, ref, _) => GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(caregiverRepositoryProvider)
                                .clearSos(sosPatient.patientId);
                          },
                          child: Container(
                            height: 48.h,
                            decoration: BoxDecoration(
                              color:
                                  Colors.white.withValues(alpha: 0.18),
                              borderRadius:
                                  BorderRadius.circular(14.r),
                              border: Border.all(
                                  color: Colors.white
                                      .withValues(alpha: 0.4)),
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
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(
                  duration: 1800.ms,
                  color: Colors.white.withValues(alpha: 0.06)),
        ],
      ),
    );
  }
}

// ─── Missed Meds Tab ──────────────────────────────────────────────────────────

class _MissedMedsTab extends ConsumerWidget {
  const _MissedMedsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patients = ref.watch(assignedPatientsProvider).valueOrNull ?? [];
    final now = DateTime.now();
    final nowMins = now.hour * 60 + now.minute;

    final overdueList = patients
        .where((p) =>
            ref.watch(patientMedStatusProvider(p.patientId)) ==
            MedStatus.overdue)
        .toList();

    if (overdueList.isEmpty) {
      return const _EmptyState(
        icon: Icons.check_circle_rounded,
        iconColor: Color(0xFF16A34A),
        title: 'All Meds On Track',
        subtitle:
            'No missed medications across\nyour assigned patients.',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
      itemCount: overdueList.length,
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (_, i) {
        final p = overdueList[i];
        final meds =
            ref.watch(assignedPatientMedsProvider(p.patientId)).valueOrNull ??
                [];
        final takenKeys =
            ref.watch(patientTakenKeysProvider(p.patientId)).valueOrNull ??
                [];

        final overdueMeds = <String>[];
        for (final m in meds.where((m) => m.isActive && !m.isExpired)) {
          for (final t in m.reminderTimes) {
            final parts = t.split(':');
            if (parts.length != 2) continue;
            final mMins = (int.tryParse(parts[0]) ?? 0) * 60 +
                (int.tryParse(parts[1]) ?? 0);
            final key = '${m.id}_$t';
            if (mMins < nowMins && !takenKeys.contains(key)) {
              overdueMeds.add('${m.name} at $t');
            }
          }
        }

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/caregiver/patient/${p.patientId}');
          },
          child: Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: 52.w,
                  width: 52.w,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B)
                            .withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      p.patientName.isNotEmpty
                          ? p.patientName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.patientName,
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              '${overdueMeds.length} overdue',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (overdueMeds.isNotEmpty) ...[
                        SizedBox(height: 5.h),
                        Text(
                          overdueMeds.take(2).join('  ·  '),
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: const Color(0xFF94A3B8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 15.w, color: const Color(0xFFCBD5E1)),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 350.ms, delay: (i * 60).ms)
              .slideX(begin: 0.04, end: 0, duration: 350.ms, delay: (i * 60).ms),
        );
      },
    );
  }
}

// ─── Hiring Tab ───────────────────────────────────────────────────────────────

class _HiringTab extends ConsumerWidget {
  const _HiringTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).valueOrNull?.uid ?? '';
    final pendingDeals = ref
            .watch(dealRequestsProvider)
            .valueOrNull
            ?.where((d) => d.status == DealStatus.pending)
            .toList() ??
        [];

    if (pendingDeals.isEmpty) {
      return const _EmptyState(
        icon: Icons.handshake_rounded,
        iconColor: Color(0xFF0D9488),
        title: 'No Pending Requests',
        subtitle:
            'New hire requests from patient managers\nwill appear here.',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
      itemCount: pendingDeals.length,
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (_, i) {
        return _HireCard(deal: pendingDeals[i], uid: uid)
            .animate()
            .fadeIn(duration: 350.ms, delay: (i * 60).ms)
            .slideX(
                begin: 0.04,
                end: 0,
                duration: 350.ms,
                delay: (i * 60).ms);
      },
    );
  }
}

class _HireCard extends ConsumerWidget {
  final DealRequestModel deal;
  final String uid;

  const _HireCard({required this.deal, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('MMM d, y');

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
            color: const Color(0xFF0D9488).withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 52.w,
                width: 52.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    deal.patientName.isNotEmpty
                        ? deal.patientName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.poppins(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deal.patientName,
                      style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'Requested by ${deal.managerName}',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  fmt.format(deal.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0D9488),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    try {
                      await ref
                          .read(caregiverRepositoryProvider)
                          .acceptDeal(uid, deal);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Connected to ${deal.patientName}!'),
                            backgroundColor: const Color(0xFF16A34A),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: const Color(0xFFEF4444),
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    height: 46.h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D9488)
                              .withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Accept Request',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref
                      .read(caregiverRepositoryProvider)
                      .rejectDeal(uid, deal.id ?? '');
                },
                child: Container(
                  height: 46.h,
                  width: 46.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                        color: const Color(0xFFEF4444)
                            .withValues(alpha: 0.25)),
                  ),
                  child: Icon(Icons.close_rounded,
                      size: 20.w, color: const Color(0xFFEF4444)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 80.w,
              width: 80.w,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40.w, color: iconColor),
            ),
            SizedBox(height: 18.h),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: const Color(0xFF94A3B8),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.92, 0.92), duration: 400.ms);
  }
}
