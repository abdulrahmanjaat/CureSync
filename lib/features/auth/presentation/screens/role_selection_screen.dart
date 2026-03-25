import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/snackbar_service.dart';
import '../providers/auth_provider.dart';
import '../providers/role_provider.dart';

// ─── Node data ──────────────────────────────────────────────────
class _Node {
  final String id;
  final String label;
  final IconData icon;
  final String description;
  final UserRole? role;
  final Color color;

  const _Node({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
    this.role,
    required this.color,
  });
}

const _nodes = [
  _Node(
    id: 'patient',
    label: 'Patient',
    icon: Icons.person_outline_rounded,
    description:
        'Manage your health records, track vitals and stay on top of your medications.',
    role: UserRole.patient,
    color: Color(0xFF0D9488),
  ),
  _Node(
    id: 'caregiver',
    label: 'Caregiver',
    icon: Icons.favorite_border_rounded,
    description:
        'Monitor your loved ones\' health remotely and receive real-time critical alerts.',
    role: UserRole.caregiver,
    color: Color(0xFF0891B2),
  ),
  _Node(
    id: 'family',
    label: 'Family',
    icon: Icons.people_outline_rounded,
    description: 'View shared health updates from your family circle.',
    color: Color(0xFF7C3AED),
  ),
  _Node(
    id: 'doctor',
    label: 'Doctor',
    icon: Icons.local_hospital_outlined,
    description: 'Access patient records and manage consultations.',
    color: Color(0xFFDB2777),
  ),
  _Node(
    id: 'pharmacy',
    label: 'Pharmacy',
    icon: Icons.medication_outlined,
    description: 'Process prescriptions and manage medication stock.',
    color: Color(0xFFEA580C),
  ),
];

// ═══════════════════════════════════════════════════════════════════
class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen>
    with TickerProviderStateMixin {
  String? _selectedId;
  bool _isSaving = false;

  late AnimationController _pulseController;
  late AnimationController _orbitController;
  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 50),
    )..repeat();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _orbitController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  _Node? get _selected =>
      _selectedId == null
          ? null
          : _nodes.firstWhere((n) => n.id == _selectedId);

  Future<void> _handleContinue() async {
    if (_selected?.role == null) return;
    setState(() => _isSaving = true);
    await ref
        .read(authControllerProvider.notifier)
        .updateRole(_selected!.role!);
    if (mounted) {
      SnackbarService.showSuccess(
          'Welcome! You\'re all set as ${_selected!.label}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFDFC),
      body: Stack(
        children: [
          /// ── Ambient background glow ──
          if (_selected != null)
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.9,
                    colors: [
                      _selected!.color.withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 28.h),

                /// ═══ HEADER ═══
                _Stagger(
                  controller: _entryController,
                  interval: const Interval(0, 0.3),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Column(
                      children: [
                        Text(
                          'Choose Your Identity',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'Select the role that best describes your\nconnection to the healthcare journey.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                /// ═══ CIRCULAR GRAPHIC ═══
                _Stagger(
                  controller: _entryController,
                  interval: const Interval(0.15, 0.55),
                  slideOffset: Offset.zero,
                  child: SizedBox(
                    height: 320.w,
                    width: 320.w,
                    child: _CircularGraphic(
                      selectedId: _selectedId,
                      onSelect: (id) => setState(() => _selectedId = id),
                      pulseController: _pulseController,
                      orbitController: _orbitController,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                /// ═══ DESCRIPTION BOX ═══
                _Stagger(
                  controller: _entryController,
                  interval: const Interval(0.4, 0.75),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28.w),
                    child: _InfoCard(selected: _selected),
                  ),
                ),

                const Spacer(),

                /// ═══ CTA ═══
                _Stagger(
                  controller: _entryController,
                  interval: const Interval(0.6, 1.0),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28.w),
                    child: Column(
                      children: [
                        if (_selected != null && _selected!.role == null)
                          Padding(
                            padding: EdgeInsets.only(bottom: 10.h),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.warning.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(100.r),
                                border: Border.all(
                                  color:
                                      AppColors.warning.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                'Coming soon — select Patient or Caregiver',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ),
                        _buildCTA(),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 36.h),
              ],
            ),
          ),

          if (_isSaving) _SavingOverlay(node: _selected!),
        ],
      ),
    );
  }

  Widget _buildCTA() {
    final active = _selected?.role != null;
    final label =
        active ? 'Get Started as ${_selected!.label}' : 'Tap a role above';

    return GestureDetector(
      onTap: active ? _handleContinue : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        height: 58.h,
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(colors: [
                  _selected!.color,
                  _selected!.color.withValues(alpha: 0.75),
                ])
              : null,
          color: active ? null : const Color(0xFFE8EDED),
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: _selected!.color.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                label,
                key: ValueKey(label),
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? Colors.white : AppColors.textHint,
                ),
              ),
            ),
            if (active) ...[
              SizedBox(width: 8.w),
              Container(
                height: 26.w,
                width: 26.w,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 16.w, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Circular Graphic — center YOU + orbit ring + 5 nodes + lines
// ═══════════════════════════════════════════════════════════════════
class _CircularGraphic extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final AnimationController pulseController;
  final AnimationController orbitController;

  const _CircularGraphic({
    required this.selectedId,
    required this.onSelect,
    required this.pulseController,
    required this.orbitController,
  });

  @override
  Widget build(BuildContext context) {
    final s = 320.w;
    final center = s / 2;
    final orbitR = s * 0.37;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        /// ── Inner orbit — dotted, counter-rotating ──
        Positioned.fill(
          child: AnimatedBuilder(
            animation: orbitController,
            builder: (_, _) => CustomPaint(
              painter: _DotOrbitPainter(
                radius: orbitR * 0.68,
                progress: 1.0 - (orbitController.value * 0.4 % 1.0),
                dotCount: 36,
                maxDotRadius: 1.8,
                color: AppColors.primary.withValues(alpha: 0.12),
                highlightColor: AppColors.primaryLight.withValues(alpha: 0.3),
                highlightSpan: 8,
              ),
            ),
          ),
        ),

        /// ── Main orbit — premium animated dot ring ──
        Positioned.fill(
          child: AnimatedBuilder(
            animation: orbitController,
            builder: (_, _) => CustomPaint(
              painter: _DotOrbitPainter(
                radius: orbitR,
                progress: orbitController.value,
                dotCount: 60,
                maxDotRadius: 2.5,
                color: AppColors.primary.withValues(alpha: 0.08),
                highlightColor: AppColors.primary.withValues(alpha: 0.35),
                highlightSpan: 12,
              ),
            ),
          ),
        ),

        /// ── Outermost faint ring — static, ultra-thin ──
        Positioned.fill(
          child: CustomPaint(
            painter: _ThinRingPainter(
              radius: orbitR * 1.12,
              color: AppColors.primary.withValues(alpha: 0.04),
            ),
          ),
        ),

        /// ── Connection lines ──
        Positioned.fill(
          child: CustomPaint(
            painter: _LinePainter(
              center: Offset(center, center),
              orbitR: orbitR,
              count: _nodes.length,
              selectedIdx:
                  _nodes.indexWhere((n) => n.id == selectedId),
              nodes: _nodes,
            ),
          ),
        ),

        /// ── Center YOU ──
        Center(
          child: _CenterYou(
            pulse: pulseController,
            selectedColor: selectedId == null
                ? null
                : _nodes.firstWhere((n) => n.id == selectedId).color,
          ),
        ),

        /// ── Orbit nodes ──
        for (int i = 0; i < _nodes.length; i++)
          _buildNode(i, center, orbitR),
      ],
    );
  }

  Widget _buildNode(int i, double center, double orbitR) {
    final angle = (2 * pi * i / _nodes.length) - pi / 2;
    final x = center + orbitR * cos(angle);
    final y = center + orbitR * sin(angle);
    final node = _nodes[i];
    final isSelected = selectedId == node.id;
    final isSelectable = node.role != null;
    final nodeRadius = isSelected ? 30.w : 25.w;

    return Positioned(
      left: x - 34.w,
      top: y - 34.w,
      child: GestureDetector(
        onTap: () => onSelect(node.id),
        child: SizedBox(
          width: 68.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// ── Outer glow ring (selected only) ──
              Stack(
                alignment: Alignment.center,
                children: [
                  if (isSelected)
                    AnimatedBuilder(
                      animation: pulseController,
                      builder: (_, _) {
                        final scale =
                            1.0 + pulseController.value * 0.15;
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            height: nodeRadius * 2 + 12.w,
                            width: nodeRadius * 2 + 12.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: node.color.withValues(
                                    alpha:
                                        0.2 * (1 - pulseController.value)),
                                width: 1.5,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  /// ── Node circle ──
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    height: nodeRadius * 2,
                    width: nodeRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isSelected
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                node.color,
                                node.color.withValues(alpha: 0.7),
                              ],
                            )
                          : null,
                      color: isSelected ? null : AppColors.surface,
                      border: isSelected
                          ? null
                          : Border.all(
                              color: isSelectable
                                  ? node.color.withValues(alpha: 0.25)
                                  : AppColors.divider,
                              width: 1.5,
                            ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color:
                                    node.color.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Icon(
                      node.icon,
                      size: isSelected ? 26.w : 20.w,
                      color: isSelected
                          ? Colors.white
                          : isSelectable
                              ? node.color
                              : AppColors.textHint,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),

              /// ── Label ──
              Text(
                node.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSelected ? 11.sp : 10.sp,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? node.color
                      : isSelectable
                          ? AppColors.textPrimary
                          : AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Center "YOU" — reacts to selected node color
// ═══════════════════════════════════════════════════════════════════
class _CenterYou extends StatelessWidget {
  final AnimationController pulse;
  final Color? selectedColor;

  const _CenterYou({required this.pulse, this.selectedColor});

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? AppColors.primary;

    return SizedBox(
      height: 90.w,
      width: 90.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          /// Ring 2 — outer expanding
          AnimatedBuilder(
            animation: pulse,
            builder: (_, _) {
              final s = 1.0 + pulse.value * 0.35;
              final a = 0.1 * (1 - pulse.value);
              return Transform.scale(
                scale: s,
                child: Container(
                  height: 90.w,
                  width: 90.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: a),
                      width: 1.5,
                    ),
                  ),
                ),
              );
            },
          ),

          /// Ring 1 — inner glow
          AnimatedBuilder(
            animation: pulse,
            builder: (_, _) {
              final s = 1.0 + pulse.value * 0.15;
              final a = 0.06 + pulse.value * 0.04;
              return Transform.scale(
                scale: s,
                child: Container(
                  height: 68.w,
                  width: 68.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: a),
                  ),
                ),
              );
            },
          ),

          /// Core circle
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            height: 54.w,
            width: 54.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(AppColors.primaryDark, color, 0.3)!,
                  color,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'YOU',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Info Card — glassmorphism description box
// ═══════════════════════════════════════════════════════════════════
class _InfoCard extends StatelessWidget {
  final _Node? selected;

  const _InfoCard({required this.selected});

  @override
  Widget build(BuildContext context) {
    final hasRole = selected != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 20.w,
        vertical: hasRole ? 18.h : 14.h,
      ),
      decoration: BoxDecoration(
        color: hasRole
            ? selected!.color.withValues(alpha: 0.05)
            : const Color(0xFFF0F5F4),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: hasRole
              ? selected!.color.withValues(alpha: 0.15)
              : AppColors.divider.withValues(alpha: 0.4),
        ),
        boxShadow: hasRole
            ? [
                BoxShadow(
                  color: selected!.color.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOut,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: child,
            ),
          );
        },
        child: hasRole
            ? Column(
                key: ValueKey(selected!.id),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// Gradient icon badge
                      Container(
                        height: 36.w,
                        width: 36.w,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            selected!.color,
                            selected!.color.withValues(alpha: 0.65),
                          ]),
                          borderRadius: BorderRadius.circular(11.r),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  selected!.color.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(selected!.icon,
                            size: 18.w, color: Colors.white),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        selected!.label,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (selected!.role == null) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: AppColors.warning
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            'Soon',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    selected!.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                      height: 1.55,
                    ),
                  ),
                ],
              )
            : Row(
                key: const ValueKey('empty'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app_outlined,
                      size: 18.w, color: AppColors.textHint),
                  SizedBox(width: 8.w),
                  Text(
                    'Tap a role in the circle above',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Saving overlay — branded with selected node
// ═══════════════════════════════════════════════════════════════════
class _SavingOverlay extends StatelessWidget {
  final _Node node;

  const _SavingOverlay({required this.node});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (_, s, child) =>
                Transform.scale(scale: s, child: child),
            child: Container(
              width: 220.w,
              padding: EdgeInsets.all(28.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 40,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 56.w,
                    width: 56.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        node.color,
                        node.color.withValues(alpha: 0.7),
                      ]),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: node.color.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child:
                        Icon(node.icon, size: 28.w, color: Colors.white),
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    'Setting up as\n${node.label}...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: 100.w,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4.r),
                      child: LinearProgressIndicator(
                        color: node.color,
                        backgroundColor:
                            node.color.withValues(alpha: 0.15),
                        minHeight: 4,
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

// ═══════════════════════════════════════════════════════════════════
// Entry animation helper
// ═══════════════════════════════════════════════════════════════════
class _Stagger extends StatelessWidget {
  final AnimationController controller;
  final Interval interval;
  final Offset slideOffset;
  final Widget child;

  const _Stagger({
    required this.controller,
    required this.interval,
    this.slideOffset = const Offset(0, 0.08),
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: controller, curve: interval);
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(curve),
      child: SlideTransition(
        position:
            Tween(begin: slideOffset, end: Offset.zero).animate(curve),
        child: child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Painters
// ═══════════════════════════════════════════════════════════════════
/// Premium dot-orbit: dots with a travelling highlight that fades
/// like a comet tail. Each dot varies in size based on proximity
/// to the highlight position.
class _DotOrbitPainter extends CustomPainter {
  final double radius;
  final double progress; // 0..1 animated
  final int dotCount;
  final double maxDotRadius;
  final Color color;
  final Color highlightColor;
  final int highlightSpan; // how many dots the highlight covers

  _DotOrbitPainter({
    required this.radius,
    required this.progress,
    required this.dotCount,
    required this.maxDotRadius,
    required this.color,
    required this.highlightColor,
    required this.highlightSpan,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final highlightIdx = (progress * dotCount).floor() % dotCount;

    for (int i = 0; i < dotCount; i++) {
      final angle = (2 * pi * i / dotCount) - pi / 2;
      final x = cx + radius * cos(angle);
      final y = cy + radius * sin(angle);

      // Distance from highlight (wrapping around)
      int dist = (i - highlightIdx).abs();
      if (dist > dotCount ~/ 2) dist = dotCount - dist;

      // Normalized: 0 = at highlight, 1 = far away
      final t = (dist / highlightSpan).clamp(0.0, 1.0);

      // Dot size: bigger near highlight
      final dotR = maxDotRadius * (1.0 - t * 0.6);

      // Color: blend from highlight to base
      final dotColor = Color.lerp(highlightColor, color, t)!;

      canvas.drawCircle(Offset(x, y), dotR, Paint()..color = dotColor);
    }
  }

  @override
  bool shouldRepaint(covariant _DotOrbitPainter old) =>
      old.progress != progress;
}

/// Ultra-thin static ring for depth layering
class _ThinRingPainter extends CustomPainter {
  final double radius;
  final Color color;

  _ThinRingPainter({required this.radius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LinePainter extends CustomPainter {
  final Offset center;
  final double orbitR;
  final int count;
  final int selectedIdx;
  final List<_Node> nodes;

  _LinePainter({
    required this.center,
    required this.orbitR,
    required this.count,
    required this.selectedIdx,
    required this.nodes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < count; i++) {
      final angle = (2 * pi * i / count) - pi / 2;
      final target = Offset(
        center.dx + orbitR * cos(angle),
        center.dy + orbitR * sin(angle),
      );

      final isActive = i == selectedIdx;
      final node = nodes[i];
      final dx = target.dx - center.dx;
      final dy = target.dy - center.dy;
      final dist = sqrt(dx * dx + dy * dy);
      final ux = dx / dist;
      final uy = dy / dist;

      final from = Offset(center.dx + ux * 30, center.dy + uy * 30);
      final to = Offset(target.dx - ux * 27, target.dy - uy * 27);

      // Active: solid colored line. Inactive: subtle dashed.
      if (isActive) {
        final paint = Paint()
          ..color = node.color.withValues(alpha: 0.35)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(from, to, paint);

        // Small dot at midpoint
        final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
        canvas.drawCircle(
            mid, 3, Paint()..color = node.color.withValues(alpha: 0.4));
      } else {
        final paint = Paint()
          ..color = AppColors.divider.withValues(alpha: 0.3)
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round;
        _drawDashed(canvas, from, to, paint);
      }
    }
  }

  void _drawDashed(Canvas c, Offset a, Offset b, Paint p) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final d = sqrt(dx * dx + dy * dy);
    final ux = dx / d;
    final uy = dy / d;
    double pos = 0;
    while (pos < d) {
      c.drawLine(
        Offset(a.dx + ux * pos, a.dy + uy * pos),
        Offset(
            a.dx + ux * min(pos + 4, d), a.dy + uy * min(pos + 4, d)),
        p,
      );
      pos += 9;
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.selectedIdx != selectedIdx;
}
