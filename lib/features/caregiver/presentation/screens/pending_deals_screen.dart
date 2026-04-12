import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/snackbar_service.dart';
import '../../data/models/deal_request_model.dart';
import '../providers/caregiver_provider.dart';

class PendingDealsScreen extends ConsumerStatefulWidget {
  const PendingDealsScreen({super.key});

  @override
  ConsumerState<PendingDealsScreen> createState() =>
      _PendingDealsScreenState();
}

class _PendingDealsScreenState extends ConsumerState<PendingDealsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deals = ref.watch(dealRequestsProvider).valueOrNull ?? [];
    final pending = deals.where((d) => d.status == DealStatus.pending).toList();
    final accepted = deals.where((d) => d.status == DealStatus.accepted).toList();
    final rejected = deals.where((d) => d.status == DealStatus.rejected).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patient Deals',
                    style: GoogleFonts.poppins(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Accept requests to start managing patients',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            SizedBox(height: 18.h),

            // ── Custom Tab Bar ────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  children: [
                    _DealTab(
                      label: 'Pending',
                      count: pending.length,
                      index: 0,
                      currentIndex: _tab.index,
                      activeColor: const Color(0xFFF59E0B),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _tab.animateTo(0);
                      },
                    ),
                    _DealTab(
                      label: 'Accepted',
                      count: accepted.length,
                      index: 1,
                      currentIndex: _tab.index,
                      activeColor: const Color(0xFF16A34A),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _tab.animateTo(1);
                      },
                    ),
                    _DealTab(
                      label: 'Rejected',
                      count: rejected.length,
                      index: 2,
                      currentIndex: _tab.index,
                      activeColor: const Color(0xFFEF4444),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _tab.animateTo(2);
                      },
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 60.ms),

            SizedBox(height: 16.h),

            // ── Deal Lists ────────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _DealList(
                    deals: pending,
                    emptyMessage: 'No pending requests',
                    emptyIcon: Icons.inbox_rounded,
                    itemBuilder: (deal) => _PendingDealCard(deal: deal),
                  ),
                  _DealList(
                    deals: accepted,
                    emptyMessage: 'No accepted deals yet',
                    emptyIcon: Icons.handshake_rounded,
                    itemBuilder: (deal) => _StatusDealCard(
                      deal: deal,
                      color: const Color(0xFF16A34A),
                      statusLabel: 'Active',
                    ),
                  ),
                  _DealList(
                    deals: rejected,
                    emptyMessage: 'No rejected deals',
                    emptyIcon: Icons.block_rounded,
                    itemBuilder: (deal) => _StatusDealCard(
                      deal: deal,
                      color: const Color(0xFFEF4444),
                      statusLabel: 'Rejected',
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

// ─── Deal Tab ─────────────────────────────────────────────────────────────────

class _DealTab extends StatelessWidget {
  final String label;
  final int count;
  final int index;
  final int currentIndex;
  final Color activeColor;
  final VoidCallback onTap;

  const _DealTab({
    required this.label,
    required this.count,
    required this.index,
    required this.currentIndex,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(vertical: 9.h),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: isActive ? Colors.white : const Color(0xFF64748B),
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.85)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Deal List ────────────────────────────────────────────────────────────────

class _DealList extends StatelessWidget {
  final List<DealRequestModel> deals;
  final String emptyMessage;
  final IconData emptyIcon;
  final Widget Function(DealRequestModel) itemBuilder;

  const _DealList({
    required this.deals,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (deals.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, size: 48.w, color: const Color(0xFFCBD5E1)),
            SizedBox(height: 12.h),
            Text(
              emptyMessage,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 100.h),
      itemCount: deals.length,
      separatorBuilder: (_, _) => SizedBox(height: 12.h),
      itemBuilder: (_, i) => itemBuilder(deals[i])
          .animate()
          .fadeIn(duration: 280.ms, delay: (i * 60).ms)
          .slideX(begin: 0.04, end: 0, duration: 280.ms, delay: (i * 60).ms),
    );
  }
}

// ─── Pending Deal Card (Accept / Reject) ─────────────────────────────────────

class _PendingDealCard extends ConsumerWidget {
  final DealRequestModel deal;
  const _PendingDealCard({required this.deal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Patient info ──────────────────────────────────────────────────
          Row(
            children: [
              Container(
                height: 46.w,
                width: 46.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    deal.patientName.isNotEmpty
                        ? deal.patientName[0].toUpperCase()
                        : 'P',
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
                    Text(
                      deal.patientName,
                      style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Requested by ${deal.managerName}',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              // Pending badge
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Pending',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),
          Divider(color: const Color(0xFFE2E8F0), height: 1.h),
          SizedBox(height: 12.h),

          // ── Metadata ──────────────────────────────────────────────────────
          Row(
            children: [
              _MetaChip(
                icon: Icons.vpn_key_rounded,
                label: 'Code: ${deal.accessCode}',
                color: const Color(0xFF0D9488),
              ),
              SizedBox(width: 8.w),
              _MetaChip(
                icon: Icons.calendar_today_rounded,
                label: DateFormat('MMM d').format(deal.createdAt),
                color: const Color(0xFF64748B),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // ── Action Buttons ────────────────────────────────────────────────
          Row(
            children: [
              // Reject
              Expanded(
                child: GestureDetector(
                  onTap: () => _reject(context, ref),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                          color:
                              const Color(0xFFEF4444).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close_rounded,
                            size: 18.w,
                            color: const Color(0xFFEF4444)),
                        SizedBox(width: 6.w),
                        Text(
                          'Reject',
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              // Accept
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () => _accept(context, ref),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.handshake_rounded,
                            size: 18.w, color: Colors.white),
                        SizedBox(width: 6.w),
                        Text(
                          'Accept Deal',
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
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
        ],
      ),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    try {
      await ref.read(caregiverRepositoryProvider).acceptDeal(uid, deal);
      SnackbarService.showSuccess(
          'Connected with ${deal.patientName}!');
    } catch (e) {
      SnackbarService.showError('Failed to accept deal: $e');
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    try {
      await ref
          .read(caregiverRepositoryProvider)
          .rejectDeal(uid, deal.id!);
      SnackbarService.showInfo('Request rejected');
    } catch (e) {
      SnackbarService.showError('Failed to reject: $e');
    }
  }
}

// ─── Status Deal Card (Accepted / Rejected) ───────────────────────────────────

class _StatusDealCard extends StatelessWidget {
  final DealRequestModel deal;
  final Color color;
  final String statusLabel;

  const _StatusDealCard({
    required this.deal,
    required this.color,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 44.w,
            width: 44.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                deal.patientName.isNotEmpty
                    ? deal.patientName[0].toUpperCase()
                    : 'P',
                style: GoogleFonts.poppins(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deal.patientName,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Manager: ${deal.managerName}',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                DateFormat('MMM d, y').format(deal.createdAt),
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: const Color(0xFFCBD5E1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Meta Chip ────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13.w, color: color),
        SizedBox(width: 4.w),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
