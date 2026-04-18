import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/prescription_order_model.dart';
import '../../data/models/inventory_item_model.dart';
import '../providers/pharmacy_provider.dart';
import 'pharmacy_orders_screen.dart';
import 'pharmacy_inventory_screen.dart';

// ── Brand palette ─────────────────────────────────────────────────────────────
const Color _orange  = Color(0xFFEA580C);
const Color _orangeL = Color(0xFFF97316);
const Color _bg      = Color(0xFFFFF8F3);

// ── Helpers ───────────────────────────────────────────────────────────────────
String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

Color _orderStatusColor(OrderStatus s) => switch (s) {
      OrderStatus.pending    => const Color(0xFFF59E0B),
      OrderStatus.processing => const Color(0xFF0891B2),
      OrderStatus.ready      => _orange,
      OrderStatus.dispensed  => const Color(0xFF16A34A),
      OrderStatus.cancelled  => const Color(0xFFEF4444),
    };

Color _stockColor(StockStatus s) => switch (s) {
      StockStatus.inStock    => const Color(0xFF16A34A),
      StockStatus.lowStock   => const Color(0xFFF59E0B),
      StockStatus.outOfStock => const Color(0xFFEF4444),
    };

// ════════════════════════════════════════════════════════════════════════════
// Screen
// ════════════════════════════════════════════════════════════════════════════
class PharmacyDashboardScreen extends ConsumerWidget {
  const PharmacyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser   = ref.watch(authStateProvider).valueOrNull;
    final firstName  = (authUser?.displayName ?? 'Pharmacist').split(' ').first;
    final photoUrl   = authUser?.photoURL;
    final stats      = ref.watch(pharmacyStatsProvider);
    final pendingOrders = ref.watch(pendingOrdersProvider).valueOrNull ?? [];
    final lowStock   = ref.watch(lowStockProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero Header ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _HeroHeader(
              firstName: firstName,
              photoUrl:  photoUrl,
              stats:     stats,
            ),
          ),

          // ── Quick Actions ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 0),
              child: _QuickActions(context: context),
            ).animate().fadeIn(duration: 300.ms, delay: 60.ms),
          ),

          // ── Pending Queue ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 22.h, 16.w, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionTitle(
                    icon: Icons.pending_actions_rounded,
                    label: 'Pending Queue',
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const PharmacyOrdersScreen()),
                    ),
                    child: Text(
                      'View all',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: _orangeL,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 280.ms, delay: 80.ms),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 12.h)),

          if (pendingOrders.isEmpty)
            SliverToBoxAdapter(
              child: _EmptyQueue()
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 100.ms),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                  child: _OrderCard(order: pendingOrders[i])
                      .animate()
                      .fadeIn(duration: 280.ms, delay: (i * 60).ms)
                      .slideY(
                          begin: 0.04,
                          end: 0,
                          duration: 280.ms,
                          delay: (i * 60).ms),
                ),
                childCount: pendingOrders.length > 5
                    ? 5
                    : pendingOrders.length,
              ),
            ),

          // ── Low Stock Alerts ───────────────────────────────────────────────
          if (lowStock.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 22.h, 16.w, 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SectionTitle(
                      icon: Icons.warning_amber_rounded,
                      label: 'Stock Alerts',
                      color: const Color(0xFFF59E0B),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const PharmacyInventoryScreen()),
                      ),
                      child: Text(
                        'Manage',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: _orangeL,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 280.ms, delay: 120.ms),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                  child: _StockAlertRow(item: lowStock[i])
                      .animate()
                      .fadeIn(duration: 260.ms, delay: (i * 50).ms),
                ),
                childCount: lowStock.length > 4 ? 4 : lowStock.length,
              ),
            ),
          ],

          SliverToBoxAdapter(child: SizedBox(height: 120.h)),
        ],
      ),
    );
  }
}

// ─── Hero Header ──────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final String firstName;
  final String? photoUrl;
  final PharmacyStats stats;

  const _HeroHeader({
    required this.firstName,
    required this.photoUrl,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_orange, _orangeL],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 26.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_greeting()},',
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          firstName,
                          style: GoogleFonts.poppins(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/notifications');
                    },
                    child: Container(
                      height: 42.w,
                      width: 42.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(13.r),
                      ),
                      child: Icon(Icons.notifications_rounded,
                          size: 22.w, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      height: 42.w,
                      width: 42.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(13.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: photoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: Image.network(photoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      Icon(Icons.person_rounded,
                                          size: 22.w,
                                          color: Colors.white)),
                            )
                          : Icon(Icons.person_rounded,
                              size: 22.w, color: Colors.white),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 22.h),

              // Stats row
              Row(
                children: [
                  _StatCard(
                    icon: Icons.pending_actions_rounded,
                    value: stats.pendingOrders.toString(),
                    label: 'Pending',
                    flex: 1,
                  ),
                  SizedBox(width: 10.w),
                  _StatCard(
                    icon: Icons.check_circle_rounded,
                    value: stats.dispensedToday.toString(),
                    label: 'Dispensed',
                    flex: 1,
                  ),
                  SizedBox(width: 10.w),
                  _StatCard(
                    icon: Icons.warning_amber_rounded,
                    value: stats.lowStockItems.toString(),
                    label: 'Low Stock',
                    flex: 1,
                    highlight: stats.lowStockItems > 0,
                  ),
                  SizedBox(width: 10.w),
                  _StatCard(
                    icon: Icons.inventory_2_rounded,
                    value: stats.totalInventory.toString(),
                    label: 'Products',
                    flex: 1,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: -0.04, end: 0, duration: 350.ms);
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final int flex;
  final bool highlight;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.flex = 1,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: highlight
              ? const Color(0xFFFEF3C7).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: highlight
                ? const Color(0xFFFBBF24).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 16.w,
                color: highlight
                    ? const Color(0xFFFBBF24)
                    : Colors.white.withValues(alpha: 0.9)),
            SizedBox(height: 4.h),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                color: Colors.white.withValues(alpha: 0.75),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final BuildContext context;
  const _QuickActions({required this.context});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.bolt_rounded,
          label: 'Quick Actions',
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            _ActionTile(
              icon: Icons.receipt_long_rounded,
              label: 'Prescription\nQueue',
              color: _orange,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const PharmacyOrdersScreen()),
              ),
            ),
            SizedBox(width: 12.w),
            _ActionTile(
              icon: Icons.inventory_2_rounded,
              label: 'Manage\nInventory',
              color: const Color(0xFF0891B2),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const PharmacyInventoryScreen()),
              ),
            ),
            SizedBox(width: 12.w),
            _ActionTile(
              icon: Icons.add_box_rounded,
              label: 'Add\nStock',
              color: const Color(0xFF16A34A),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const PharmacyInventoryScreen()),
                );
              },
            ),
            SizedBox(width: 12.w),
            _ActionTile(
              icon: Icons.bar_chart_rounded,
              label: 'Reports',
              color: const Color(0xFF7C3AED),
              onTap: () => HapticFeedback.lightImpact(),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 40.w,
                width: 40.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, size: 20.w, color: color),
              ),
              SizedBox(height: 8.h),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionTitle({
    required this.icon,
    required this.label,
    this.color = _orange,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 28.w,
          width: 28.w,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 15.w, color: color),
        ),
        SizedBox(width: 8.w),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

// ─── Order Card ───────────────────────────────────────────────────────────────

class _OrderCard extends ConsumerWidget {
  final PrescriptionOrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                Row(
                  children: [
                    Container(
                      height: 40.w,
                      width: 40.w,
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
                            'Dr. ${order.doctorName} · ${order.patientAge} yrs',
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

                // Medication chips
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: order.medications
                      .take(3)
                      .map((m) => Container(
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
                          ))
                      .toList(),
                ),

                SizedBox(height: 10.h),

                // Action buttons
                Row(
                  children: [
                    if (order.status == OrderStatus.pending)
                      Expanded(
                        child: _OrderBtn(
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
                        child: _OrderBtn(
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
                      child: _OrderBtn(
                        label: 'Dispense',
                        color: const Color(0xFF16A34A),
                        onTap: () async {
                          if (order.id != null) {
                            await updateOrderStatus(
                                order.id!, OrderStatus.dispensed);
                          }
                        },
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

class _OrderBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OrderBtn({
    required this.label,
    required this.color,
    required this.onTap,
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
          color: color,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Stock Alert Row ──────────────────────────────────────────────────────────

class _StockAlertRow extends StatelessWidget {
  final InventoryItemModel item;
  const _StockAlertRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = _stockColor(item.stockStatus);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 36.w,
            width: 36.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.medication_rounded, size: 18.w, color: color),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.dosageForm,
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
              Text(
                '${item.quantity} ${item.unit}',
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(5.r),
                ),
                child: Text(
                  item.stockStatus.label,
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
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

// ─── Empty Queue ─────────────────────────────────────────────────────────────

class _EmptyQueue extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 36.h, horizontal: 20.w),
      child: Column(
        children: [
          Container(
            height: 68.w,
            width: 68.w,
            decoration: BoxDecoration(
              color: _orange.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_outline_rounded,
                size: 32.w, color: _orange),
          ),
          SizedBox(height: 12.h),
          Text(
            'No pending prescriptions',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'All orders have been fulfilled.',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
