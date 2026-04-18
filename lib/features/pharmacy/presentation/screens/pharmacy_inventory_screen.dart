import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/inventory_item_model.dart';
import '../../data/repositories/pharmacy_repository.dart';
import '../providers/pharmacy_provider.dart';

// ── Brand palette ─────────────────────────────────────────────────────────────
const Color _orange  = Color(0xFFEA580C);
const Color _orangeL = Color(0xFFF97316);
const Color _bg      = Color(0xFFFFF8F3);

Color _stockColor(StockStatus s) => switch (s) {
      StockStatus.inStock    => const Color(0xFF16A34A),
      StockStatus.lowStock   => const Color(0xFFF59E0B),
      StockStatus.outOfStock => const Color(0xFFEF4444),
    };

// ── Search + filter ───────────────────────────────────────────────────────────
final _invSearchProvider = StateProvider<String>((ref) => '');
final _invFilterProvider = StateProvider<StockStatus?>((ref) => null);

// ════════════════════════════════════════════════════════════════════════════
// Screen
// ════════════════════════════════════════════════════════════════════════════
class PharmacyInventoryScreen extends ConsumerWidget {
  const PharmacyInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all    = ref.watch(inventoryProvider).valueOrNull ?? [];
    final query  = ref.watch(_invSearchProvider);
    final filter = ref.watch(_invFilterProvider);

    final visible = all.where((item) {
      final matchesFilter =
          filter == null || item.stockStatus == filter;
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      return item.name.toLowerCase().contains(query.toLowerCase()) ||
          item.category.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160.h,
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
                    padding: EdgeInsets.fromLTRB(20.w, 50.h, 20.w, 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inventory',
                          style: GoogleFonts.poppins(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${all.length} products',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        SizedBox(height: 14.h),
                        // Search bar
                        Container(
                          height: 40.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: TextField(
                            onChanged: (v) => ref
                                .read(_invSearchProvider.notifier)
                                .state = v.trim(),
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search products…',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 12.sp,
                                color: const Color(0xFF94A3B8),
                              ),
                              prefixIcon: Icon(Icons.search_rounded,
                                  size: 18.w, color: _orange),
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 10.h),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showAddSheet(context, ref);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded,
                            size: 15.w, color: Colors.white),
                        SizedBox(width: 4.w),
                        Text(
                          'Add Item',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
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

          // ── Filter chips ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _StockFilterBar(
              selected: filter,
              onSelect: (s) =>
                  ref.read(_invFilterProvider.notifier).state = s,
            ).animate().fadeIn(duration: 280.ms),
          ),

          // ── List ─────────────────────────────────────────────────────────
          if (visible.isEmpty)
            SliverToBoxAdapter(
              child: _EmptyState()
                  .animate()
                  .fadeIn(duration: 300.ms),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                  child: _InventoryCard(item: visible[i])
                      .animate()
                      .fadeIn(duration: 260.ms, delay: (i * 40).ms)
                      .slideY(
                          begin: 0.03,
                          end: 0,
                          duration: 260.ms,
                          delay: (i * 40).ms),
                ),
                childCount: visible.length,
              ),
            ),

          SliverToBoxAdapter(child: SizedBox(height: 120.h)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showAddSheet(context, ref);
        },
        backgroundColor: _orange,
        icon: const Icon(Icons.add_box_rounded, color: Colors.white),
        label: Text(
          'Add Stock',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddItemSheet(ref: ref),
    );
  }
}

// ─── Stock Filter Bar ─────────────────────────────────────────────────────────

class _StockFilterBar extends StatelessWidget {
  final StockStatus? selected;
  final ValueChanged<StockStatus?> onSelect;

  const _StockFilterBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final chips = <(StockStatus?, String, Color)>[
      (null, 'All', _orange),
      (StockStatus.inStock, 'In Stock', const Color(0xFF16A34A)),
      (StockStatus.lowStock, 'Low Stock', const Color(0xFFF59E0B)),
      (StockStatus.outOfStock, 'Out of Stock', const Color(0xFFEF4444)),
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

// ─── Inventory Card ───────────────────────────────────────────────────────────

class _InventoryCard extends ConsumerStatefulWidget {
  final InventoryItemModel item;
  const _InventoryCard({required this.item});

  @override
  ConsumerState<_InventoryCard> createState() => _InventoryCardState();
}

class _InventoryCardState extends ConsumerState<_InventoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final color = _stockColor(widget.item.stockStatus);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _expanded = !_expanded);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: _orange.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 14.w, vertical: 12.h),
              child: Row(
                children: [
                  Container(
                    height: 44.w,
                    width: 44.w,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.medication_rounded,
                        size: 22.w, color: color),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.name,
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${widget.item.dosageForm} · ${widget.item.category}',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${widget.item.quantity} ${widget.item.unit}',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
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
                          widget.item.stockStatus.label,
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 6.w),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18.w,
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),

            // Expanded detail + actions
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: _expanded
                  ? Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(16.r)),
                      ),
                      padding: EdgeInsets.fromLTRB(
                          14.w, 10.h, 14.w, 14.h),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _DetailChip(
                                label: '\$${widget.item.price.toStringAsFixed(2)}',
                                icon: Icons.attach_money_rounded,
                              ),
                              SizedBox(width: 8.w),
                              if (widget.item.manufacturer != null)
                                Expanded(
                                  child: _DetailChip(
                                    label: widget.item.manufacturer!,
                                    icon: Icons.factory_rounded,
                                    flexible: true,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          // Adjust stock row
                          Row(
                            children: [
                              Text(
                                'Adjust stock:',
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const Spacer(),
                              _StockBtn(
                                icon: Icons.remove_rounded,
                                color: const Color(0xFFEF4444),
                                onTap: () async {
                                  final newQty =
                                      (widget.item.quantity - 1)
                                          .clamp(0, 99999);
                                  if (widget.item.id != null) {
                                    await updateStock(
                                        widget.item.id!, newQty);
                                  }
                                },
                              ),
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Text(
                                  widget.item.quantity.toString(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              _StockBtn(
                                icon: Icons.add_rounded,
                                color: const Color(0xFF16A34A),
                                onTap: () async {
                                  final newQty = widget.item.quantity + 1;
                                  if (widget.item.id != null) {
                                    await updateStock(
                                        widget.item.id!, newQty);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool flexible;

  const _DetailChip({
    required this.label,
    required this.icon,
    this.flexible = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11.w, color: const Color(0xFF64748B)),
        SizedBox(width: 4.w),
        flexible
            ? Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: const Color(0xFF64748B),
                ),
              ),
      ],
    );

    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }
}

class _StockBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StockBtn({
    required this.icon,
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
        height: 32.w,
        width: 32.w,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, size: 16.w, color: color),
      ),
    );
  }
}

// ─── Add Item Sheet ───────────────────────────────────────────────────────────

class _AddItemSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _AddItemSheet({required this.ref});

  @override
  ConsumerState<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<_AddItemSheet> {
  final _nameCtrl      = TextEditingController();
  final _categoryCtrl  = TextEditingController();
  final _dosageCtrl    = TextEditingController();
  final _unitCtrl      = TextEditingController();
  final _priceCtrl     = TextEditingController();
  final _qtyCtrl       = TextEditingController();
  final _threshCtrl    = TextEditingController();
  final _mfgCtrl       = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _categoryCtrl, _dosageCtrl, _unitCtrl,
      _priceCtrl, _qtyCtrl, _threshCtrl, _mfgCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final uid = ref.read(authStateProvider).valueOrNull?.uid ?? '';

    final item = InventoryItemModel(
      pharmacyId:        uid,
      name:              _nameCtrl.text.trim(),
      category:          _categoryCtrl.text.trim().isEmpty
          ? 'General' : _categoryCtrl.text.trim(),
      unit:              _unitCtrl.text.trim().isEmpty
          ? 'units' : _unitCtrl.text.trim(),
      dosageForm:        _dosageCtrl.text.trim().isEmpty
          ? 'Tablet' : _dosageCtrl.text.trim(),
      price:             double.tryParse(_priceCtrl.text.trim()) ?? 0,
      quantity:          int.tryParse(_qtyCtrl.text.trim()) ?? 0,
      lowStockThreshold: int.tryParse(_threshCtrl.text.trim()) ?? 10,
      manufacturer:      _mfgCtrl.text.trim().isEmpty
          ? null : _mfgCtrl.text.trim(),
      updatedAt:         DateTime.now(),
    );

    await addInventoryItem(item);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: EdgeInsets.only(top: 60.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 12.h),
              height: 4.h,
              width: 40.w,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
            child: Row(
              children: [
                Container(
                  height: 36.w,
                  width: 36.w,
                  decoration: BoxDecoration(
                    color: _orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.add_box_rounded,
                      size: 18.w, color: _orange),
                ),
                SizedBox(width: 10.w),
                Text(
                  'Add Inventory Item',
                  style: GoogleFonts.poppins(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  20.w, 16.h, 20.w, bottom + 20.h),
              child: Column(
                children: [
                  _Field(ctrl: _nameCtrl, label: 'Product Name'),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                            ctrl: _categoryCtrl, label: 'Category'),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _Field(
                            ctrl: _dosageCtrl,
                            label: 'Form (e.g. Tablet)'),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: _Field(ctrl: _unitCtrl, label: 'Unit'),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _Field(
                          ctrl: _priceCtrl,
                          label: 'Price (\$)',
                          inputType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          ctrl: _qtyCtrl,
                          label: 'Qty in stock',
                          inputType: TextInputType.number,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _Field(
                          ctrl: _threshCtrl,
                          label: 'Low stock at',
                          inputType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  _Field(
                      ctrl: _mfgCtrl,
                      label: 'Manufacturer (optional)'),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Add to Inventory',
                              style: GoogleFonts.inter(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputType inputType;

  const _Field({
    required this.ctrl,
    required this.label,
    this.inputType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      style: GoogleFonts.inter(
        fontSize: 13.sp,
        color: const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 12.sp,
          color: const Color(0xFF94A3B8),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide:
              const BorderSide(color: _orangeL, width: 1.5),
        ),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
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
            child: Icon(Icons.inventory_2_rounded,
                size: 34.w, color: _orange),
          ),
          SizedBox(height: 14.h),
          Text(
            'No inventory items',
            style: GoogleFonts.poppins(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Tap "Add Stock" to add your first item.',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
