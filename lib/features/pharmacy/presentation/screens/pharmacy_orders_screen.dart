import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/prescription_order_model.dart';
import '../providers/pharmacy_provider.dart';

// ── Brand palette ─────────────────────────────────────────────────────────────
const Color _orange  = Color(0xFFEA580C);
const Color _orangeL = Color(0xFFF97316);
const Color _bg      = Color(0xFFFFF8F3);

Color _orderStatusColor(OrderStatus s) => switch (s) {
      OrderStatus.pending    => const Color(0xFFF59E0B),
      OrderStatus.processing => const Color(0xFF0891B2),
      OrderStatus.ready      => _orange,
      OrderStatus.dispensed  => const Color(0xFF16A34A),
      OrderStatus.cancelled  => const Color(0xFFEF4444),
    };

String _formatDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}';
}

// ── Filter provider ───────────────────────────────────────────────────────────
final _orderFilterProvider = StateProvider<OrderStatus?>((ref) => null);

// ════════════════════════════════════════════════════════════════════════════
// Screen
// ════════════════════════════════════════════════════════════════════════════
class PharmacyOrdersScreen extends ConsumerWidget {
  const PharmacyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allOrders = ref.watch(allOrdersProvider).valueOrNull ?? [];
    final filter    = ref.watch(_orderFilterProvider);

    final visible = filter == null
        ? allOrders
        : allOrders.where((o) => o.status == filter).toList();

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140.h,
            pinned: true,
            backgroundColor: _orange,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_orange, _orangeL],
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
                          'Prescription Orders',
                          style: GoogleFonts.poppins(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${allOrders.length} total · ${visible.length} shown',
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
                  ref.read(_orderFilterProvider.notifier).state = s,
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
                  child: _OrderCard(order: visible[i])
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
  final OrderStatus? selected;
  final ValueChanged<OrderStatus?> onSelect;

  const _FilterBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final chips = <(OrderStatus?, String, Color)>[
      (null, 'All', _orange),
      (OrderStatus.pending, 'Pending', const Color(0xFFF59E0B)),
      (OrderStatus.processing, 'Processing', const Color(0xFF0891B2)),
      (OrderStatus.ready, 'Ready', _orange),
      (OrderStatus.dispensed, 'Dispensed', const Color(0xFF16A34A)),
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

// ─── Order Card ───────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final PrescriptionOrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final color = _orderStatusColor(order.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: _orange.withValues(alpha: 0.06),
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
                // Header row
                Row(
                  children: [
                    Container(
                      height: 42.w,
                      width: 42.w,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.receipt_long_rounded,
                          size: 20.w, color: color),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.patientName,
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Dr. ${order.doctorName} · ${_formatDate(order.receivedAt)}',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        order.status.label,
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 10.h),

                // Medications
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: order.medications.map((m) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: _orange.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(7.r),
                        border: Border.all(
                          color: _orange.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        '${m.name} ${m.dosage}',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: _orange,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                if (order.diagnosis != null &&
                    order.diagnosis!.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.medical_information_rounded,
                          size: 12.w,
                          color: const Color(0xFF94A3B8)),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          order.diagnosis!,
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: const Color(0xFF64748B),
                            fontStyle: FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // Action buttons
                if (order.status != OrderStatus.dispensed &&
                    order.status != OrderStatus.cancelled) ...[
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      if (order.status == OrderStatus.pending)
                        Expanded(
                          child: _ActionBtn(
                            label: 'Process',
                            color: const Color(0xFF0891B2),
                            onTap: () async {
                              if (order.id != null) {
                                await updateOrderStatus(
                                    order.id!, OrderStatus.processing);
                              }
                            },
                          ),
                        ),
                      if (order.status == OrderStatus.pending)
                        SizedBox(width: 8.w),
                      if (order.status == OrderStatus.processing)
                        Expanded(
                          child: _ActionBtn(
                            label: 'Mark Ready',
                            color: _orange,
                            onTap: () async {
                              if (order.id != null) {
                                await updateOrderStatus(
                                    order.id!, OrderStatus.ready);
                              }
                            },
                          ),
                        ),
                      if (order.status == OrderStatus.processing)
                        SizedBox(width: 8.w),
                      Expanded(
                        child: _ActionBtn(
                          label: 'Dispense ✓',
                          color: const Color(0xFF16A34A),
                          onTap: () async {
                            if (order.id != null) {
                              await updateOrderStatus(
                                  order.id!, OrderStatus.dispensed);
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _ActionBtn(
                        label: 'Cancel',
                        color: const Color(0xFFEF4444),
                        outlined: true,
                        onTap: () async {
                          if (order.id != null) {
                            await updateOrderStatus(
                                order.id!, OrderStatus.cancelled);
                          }
                        },
                      ),
                    ],
                  ),
                ],

                if (order.status == OrderStatus.dispensed &&
                    order.dispensedAt != null) ...[
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 13.w,
                          color: const Color(0xFF16A34A)),
                      SizedBox(width: 4.w),
                      Text(
                        'Dispensed on ${_formatDate(order.dispensedAt!)}',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: const Color(0xFF16A34A),
                          fontWeight: FontWeight.w500,
                        ),
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
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _ActionBtn({
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
  final OrderStatus? filter;
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
              color: _orange.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_rounded,
                size: 34.w, color: _orange),
          ),
          SizedBox(height: 14.h),
          Text(
            filter == null
                ? 'No orders yet'
                : 'No ${filter!.label.toLowerCase()} orders',
            style: GoogleFonts.poppins(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'New prescriptions will appear here.',
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
