import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/custom_bottom_sheet.dart';
import '../../../auth/data/models/patient_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../patient/presentation/providers/patient_provider.dart';
import '../../../patient/presentation/providers/medication_provider.dart';
import '../../../patient/presentation/widgets/add_patient_sheet.dart';

// Colorful card palette — cycles per index
const _cardColors = [
  Color(0xFFDB2777), // Pink/Rose — Manager brand
  Color(0xFF0891B2), // Cyan
  Color(0xFF7C3AED), // Purple
  Color(0xFF16A34A), // Green
  Color(0xFFF59E0B), // Amber
  Color(0xFF0D9488), // Teal
];

const _cardBgColors = [
  Color(0xFFFFE4E6),
  Color(0xFFE0F2FE),
  Color(0xFFEDE9FE),
  Color(0xFFDCFCE7),
  Color(0xFFFEF3C7),
  Color(0xFFCCFBF1),
];

const _relationEmojis = {
  'Father': '👨', 'Mother': '👩', 'Son': '👦', 'Daughter': '👧',
  'Brother': '🧑', 'Sister': '👱', 'Grandparent': '🧓',
  'Grandfather': '👴', 'Grandmother': '👵', 'Spouse': '💑',
  'Wife': '👩', 'Husband': '👨', 'Child': '🧒',
  'Friend': '🤝', 'Myself': '🧑',
};

// ═══════════════════════════════════════════════════════════════════
class ManagerDashboardScreen extends ConsumerWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(patientsStreamProvider);
    final authUser = ref.watch(authStateProvider).valueOrNull;
    final firstName = (authUser?.displayName ?? 'Manager').split(' ').first;
    final photoUrl = authUser?.photoURL;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFA),
      // ── FAB: Add Patient ── (moved from App Bar header)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          CustomBottomSheet.show(
            context: context,
            useDraggable: false,
            child: const AddPatientSheet(),
          );
        },
        backgroundColor: const Color(0xFFDB2777),
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Icon(Icons.person_add_rounded, size: 24.w),
      ),
      body: Stack(
        children: [
          // Ambient background glow — rose/pink for manager brand
          Positioned(
            top: -60.h,
            right: -40.w,
            child: Container(
              height: 260.w,
              width: 260.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFDB2777).withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── App Bar Row ───────────────────────────────────
                        // Left: Manager greeting
                        // Right: Notification bell + Profile avatar
                        // Both link to the Manager's own auth data — NOT sub-patients
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
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
                                Text(
                                  'Managed Patients',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),

                            // Notification + Profile — Manager's own
                            Row(
                              children: [
                                _AppBarIcon(
                                  icon: Icons.notifications_none_rounded,
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
                                      borderRadius:
                                          BorderRadius.circular(14.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.06),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(14.r),
                                      child: photoUrl != null
                                          ? Image.network(
                                              photoUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  _avatarFallback(firstName),
                                            )
                                          : _avatarFallback(firstName),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ).animate().fadeIn(duration: 350.ms),

                        SizedBox(height: 16.h),

                        // ─── Stats row ───
                        patientsAsync.whenData((patients) {
                          return Row(
                            children: [
                              _StatPill(
                                icon: Icons.manage_accounts_rounded,
                                label:
                                    '${patients.length} patient${patients.length == 1 ? '' : 's'}',
                                color: const Color(0xFFDB2777),
                              ),
                              SizedBox(width: 8.w),
                              _StatPill(
                                icon: Icons.verified_rounded,
                                label: 'Active management',
                                color: const Color(0xFF0891B2),
                              ),
                            ],
                          );
                        }).valueOrNull ??
                            const SizedBox.shrink(),

                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),

                // ─── Patient Cards ─────────────────────────────────────────
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  sliver: patientsAsync.when(
                    loading: () => SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 60.h),
                          child: const CircularProgressIndicator(
                            color: Color(0xFFDB2777),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ),
                    error: (e, _) => SliverToBoxAdapter(
                      child: Center(
                        child: Text('Error: $e',
                            style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                color: const Color(0xFF94A3B8))),
                      ),
                    ),
                    data: (patients) {
                      if (patients.isEmpty) {
                        return SliverToBoxAdapter(
                          child: _EmptyState(
                            onAdd: () => CustomBottomSheet.show(
                              context: context,
                              useDraggable: false,
                              child: const AddPatientSheet(),
                            ),
                          ),
                        );
                      }
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final p = patients[i];
                            final colorIdx = i % _cardColors.length;
                            return Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: _ManagerPatientCard(
                                patient: p,
                                color: _cardColors[colorIdx],
                                bgColor: _cardBgColors[colorIdx],
                                onViewDashboard: () {
                                  HapticFeedback.lightImpact();
                                  context.push(
                                      '/manager/patient/${p.patientId}');
                                },
                              )
                                  .animate()
                                  .fadeIn(
                                      duration: 400.ms,
                                      delay: (80 * i).ms)
                                  .slideY(
                                      begin: 0.06,
                                      end: 0,
                                      duration: 400.ms,
                                      delay: (80 * i).ms),
                            );
                          },
                          childCount: patients.length,
                        ),
                      );
                    },
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 120.h)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      color: const Color(0xFFDB2777),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'M',
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─── Manager Patient Card ────────────────────────────────────────────────────

class _ManagerPatientCard extends ConsumerWidget {
  final PatientModel patient;
  final Color color;
  final Color bgColor;
  final VoidCallback onViewDashboard;

  const _ManagerPatientCard({
    required this.patient,
    required this.color,
    required this.bgColor,
    required this.onViewDashboard,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync =
        ref.watch(medicationsStreamProvider(patient.patientId ?? ''));
    final meds = medsAsync.valueOrNull ?? [];
    final activeMeds = meds.where((m) => m.isActive && !m.isExpired).toList();
    final emoji = _relationEmojis[patient.relation] ?? '🧑';

    return GestureDetector(
      onTap: onViewDashboard,
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: color.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Top row: emoji avatar + name/relation + open arrow ───
            Row(
              children: [
                Container(
                  height: 52.w,
                  width: 52.w,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Center(
                    child:
                        Text(emoji, style: TextStyle(fontSize: 26.sp)),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: GoogleFonts.poppins(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${patient.relation} · ${patient.age} yrs',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 36.w,
                  width: 36.w,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 18.w, color: Colors.white),
                ),
              ],
            ),

            SizedBox(height: 14.h),

            // ─── Access Code chip + stats row ───
            Row(
              children: [
                // Access code — tappable, copies to clipboard
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Clipboard.setData(
                        ClipboardData(text: patient.accessCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Code copied to clipboard',
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                        backgroundColor: const Color(0xFF0D9488),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                          color: color.withValues(alpha: 0.25), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.key_rounded, size: 12.w, color: color),
                        SizedBox(width: 5.w),
                        Text(
                          patient.accessCode,
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: color,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(width: 5.w),
                        Icon(Icons.copy_rounded,
                            size: 10.w,
                            color: color.withValues(alpha: 0.6)),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 8.w),

                _Chip(
                  icon: Icons.medication_rounded,
                  label:
                      '${activeMeds.length} med${activeMeds.length == 1 ? '' : 's'}',
                  color: color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Small helpers ────────────────────────────────────────────────────────────

class _AppBarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AppBarIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
        child: Icon(icon, size: 22.w, color: const Color(0xFF64748B)),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.w, color: color),
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

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatPill(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.w, color: color),
          SizedBox(width: 5.w),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 60.h),
      child: Column(
        children: [
          Container(
            height: 80.w,
            width: 80.w,
            decoration: BoxDecoration(
              color: const Color(0xFFDB2777).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.manage_accounts_rounded,
                size: 40.w, color: const Color(0xFFDB2777)),
          ),
          SizedBox(height: 20.h),
          Text(
            'No patients yet',
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Tap the + button to add your first\npatient and start managing their care.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: const Color(0xFF94A3B8),
              height: 1.5,
            ),
          ),
          SizedBox(height: 32.h),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 28.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: const Color(0xFFDB2777),
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  BoxShadow(
                    color:
                        const Color(0xFFDB2777).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add_rounded,
                      size: 20.w, color: Colors.white),
                  SizedBox(width: 8.w),
                  Text(
                    'Add First Patient',
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
