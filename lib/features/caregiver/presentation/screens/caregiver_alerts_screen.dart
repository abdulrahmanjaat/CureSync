import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    extends ConsumerState<CaregiverAlertsScreen> {
  int _tab = 0; // 0=Emergency, 1=Missed Meds, 2=Hiring

  static const _tabs = ['Emergency', 'Missed Meds', 'Hiring'];
  static const _tabIcons = [
    Icons.sos_rounded,
    Icons.medication_rounded,
    Icons.handshake_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final sosPatient = ref.watch(sosTriggerProvider);
    final missedCount = ref.watch(totalMissedMedsProvider);
    final pendingDeals = ref.watch(pendingDealCountProvider);

    final badges = [
      sosPatient != null ? 1 : 0,
      missedCount,
      pendingDeals,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alerts',
                        style: GoogleFonts.poppins(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Real-time patient notifications',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // ── Tab Row ───────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                height: 48.h,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  children: List.generate(_tabs.length, (i) {
                    final isActive = i == _tab;
                    final badge = badges[i];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _tab = i);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10.r),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _tabIcons[i],
                                    size: 14.w,
                                    color: isActive
                                        ? _tabColor(i)
                                        : const Color(0xFF94A3B8),
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    _tabs[i],
                                    style: GoogleFonts.inter(
                                      fontSize: 11.sp,
                                      fontWeight: isActive
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isActive
                                          ? _tabColor(i)
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                              if (badge > 0)
                                Positioned(
                                  top: 4.h,
                                  right: 6.w,
                                  child: Container(
                                    height: 16.w,
                                    width: 16.w,
                                    decoration: BoxDecoration(
                                      color: _tabColor(i),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$badge',
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
                      ),
                    );
                  }),
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // ── Content ───────────────────────────────────────────────
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: const [
                  _EmergencyTab(),
                  _MissedMedsTab(),
                  _HiringTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _tabColor(int i) {
    return switch (i) {
      0 => const Color(0xFFEF4444),
      1 => const Color(0xFFF59E0B),
      _ => const Color(0xFF0D9488),
    };
  }
}

// ─── Emergency Tab ────────────────────────────────────────────────────────────

class _EmergencyTab extends ConsumerWidget {
  const _EmergencyTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sosPatient = ref.watch(sosTriggerProvider);

    if (sosPatient == null) {
      return _EmptyState(
        icon: Icons.shield_rounded,
        iconColor: const Color(0xFF16A34A),
        title: 'All Clear',
        subtitle: 'No active emergencies from any\nof your patients.',
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          // SOS Alert Card
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color:
                      const Color(0xFFEF4444).withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      height: 48.w,
                      width: 48.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.sos_rounded,
                          size: 26.w, color: Colors.white),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SOS ALERT',
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              color:
                                  Colors.white.withValues(alpha: 0.8),
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            sosPatient.patientName,
                            style: GoogleFonts.poppins(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Emergency alert triggered',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color:
                                  Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
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
                          height: 44.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Center(
                            child: Text(
                              'View Profile',
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
                    SizedBox(width: 10.w),
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
                            height: 44.h,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color:
                                    Colors.white.withValues(alpha: 0.4),
                              ),
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
          ),
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
    final patients =
        ref.watch(assignedPatientsProvider).valueOrNull ?? [];
    final overduePatients = patients
        .where((p) =>
            ref.watch(patientMedStatusProvider(p.patientId)) ==
            MedStatus.overdue)
        .toList();

    if (overduePatients.isEmpty) {
      return const _EmptyState(
        icon: Icons.check_circle_rounded,
        iconColor: Color(0xFF16A34A),
        title: 'All Meds On Track',
        subtitle: 'No missed medications across\nyour assigned patients.',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      itemCount: overduePatients.length,
      separatorBuilder: (_, _) => SizedBox(height: 10.h),
      itemBuilder: (_, i) {
        final p = overduePatients[i];
        final meds = ref
                .watch(assignedPatientMedsProvider(p.patientId))
                .valueOrNull ??
            [];
        final takenKeys =
            ref.watch(patientTakenKeysProvider(p.patientId)).valueOrNull ??
                [];
        final now = DateTime.now();
        final nowMins = now.hour * 60 + now.minute;

        final overdueMeds = <String>[];
        for (final m in meds.where((m) => m.isActive && !m.isExpired)) {
          for (final t in m.reminderTimes) {
            final parts = t.split(':');
            if (parts.length != 2) continue;
            final mMins = (int.tryParse(parts[0]) ?? 0) * 60 +
                (int.tryParse(parts[1]) ?? 0);
            final key = '${m.id}_$t';
            if (mMins < nowMins && !takenKeys.contains(key)) {
              overdueMeds.add('${m.name} @ $t');
            }
          }
        }

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/caregiver/patient/${p.patientId}');
          },
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: 44.w,
                  width: 44.w,
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      p.patientName.isNotEmpty
                          ? p.patientName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.patientName,
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          )),
                      Text(
                        '${overdueMeds.length} med${overdueMeds.length == 1 ? '' : 's'} overdue',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFFF59E0B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (overdueMeds.isNotEmpty)
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
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 18.w, color: const Color(0xFFCBD5E1)),
              ],
            ),
          ),
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
    final dealsAsync = ref.watch(dealRequestsProvider);
    final pendingDeals = dealsAsync.valueOrNull
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
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      itemCount: pendingDeals.length,
      separatorBuilder: (_, _) => SizedBox(height: 10.h),
      itemBuilder: (_, i) {
        final deal = pendingDeals[i];
        return _HireCard(deal: deal, uid: uid);
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
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
            color: const Color(0xFF0D9488).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44.w,
                width: 44.w,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF0D9488).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    deal.patientName.isNotEmpty
                        ? deal.patientName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0D9488),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deal.patientName,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        )),
                    Text('From ${deal.managerName}',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFF64748B),
                        )),
                  ],
                ),
              ),
              Text(
                fmt.format(deal.createdAt),
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
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
                            backgroundColor:
                                const Color(0xFF16A34A),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Error: ${e.toString()}'),
                            backgroundColor:
                                const Color(0xFFEF4444),
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Center(
                      child: Text('Accept',
                          style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(caregiverRepositoryProvider)
                        .rejectDeal(uid, deal.id ?? '');
                  },
                  child: Container(
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                          color: const Color(0xFFEF4444)
                              .withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text('Decline',
                          style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFEF4444))),
                    ),
                  ),
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
              height: 72.w,
              width: 72.w,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36.w, color: iconColor),
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: const Color(0xFF94A3B8),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
