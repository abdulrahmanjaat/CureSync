import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/snackbar_service.dart';
import '../../../../shared/widgets/custom_bottom_sheet.dart';
import '../../../auth/data/models/patient_model.dart';
import '../providers/patient_provider.dart';
import '../providers/medication_provider.dart';
import '../providers/active_patient_provider.dart';
import '../widgets/add_patient_sheet.dart';

// Assign vivid colors per patient index
const _cardColors = [
  Color(0xFF0D9488), // Teal
  Color(0xFFFF6B6B), // Coral
  Color(0xFF7C3AED), // Purple
  Color(0xFF0891B2), // Cyan
  Color(0xFF16A34A), // Green
  Color(0xFFF59E0B), // Amber
];

const _cardBgColors = [
  Color(0xFFCCFBF1), // Teal light
  Color(0xFFFFE4E6), // Coral light
  Color(0xFFEDE9FE), // Purple light
  Color(0xFFE0F2FE), // Cyan light
  Color(0xFFDCFCE7), // Green light
  Color(0xFFFEF3C7), // Amber light
];

const _relationEmojis = {
  'Father': '👨',
  'Mother': '👩',
  'Son': '👦',
  'Daughter': '👧',
  'Brother': '🧑',
  'Sister': '👱',
  'Grandparent': '🧓',
  'Grandfather': '👴',
  'Grandmother': '👵',
  'Spouse': '💑',
  'Wife': '👩',
  'Husband': '👨',
  'Child': '🧒',
  'Friend': '🤝',
  'Myself': '🧑',
};

class PatientsTabScreen extends ConsumerWidget {
  const PatientsTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(patientsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFA),
      body: Stack(
        children: [
          // Background gradient
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
                    const Color(0xFF0D9488).withValues(alpha: 0.07),
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
                    padding:
                        EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── Header ───
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Patients',
                                  style: GoogleFonts.poppins(
                                    fontSize: 28.sp,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'Family care circle',
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                CustomBottomSheet.show(
                                  context: context,
                                  useDraggable: false,
                                  child: const AddPatientSheet(),
                                );
                              },
                              child: Container(
                                height: 44.w,
                                width: 44.w,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B6B),
                                  borderRadius: BorderRadius.circular(14.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF6B6B)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(Icons.add_rounded,
                                    size: 24.w, color: Colors.white),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(duration: 350.ms),

                        SizedBox(height: 6.h),

                        // ─── Stats row ───
                        patientsAsync.whenData((patients) {
                          return Row(
                            children: [
                              _StatPill(
                                  icon: Icons.people_rounded,
                                  label: '${patients.length} members',
                                  color: const Color(0xFF0D9488)),
                              SizedBox(width: 8.w),
                              _StatPill(
                                  icon: Icons.favorite_rounded,
                                  label: 'Active care',
                                  color: const Color(0xFFFF6B6B)),
                            ],
                          );
                        }).valueOrNull ?? const SizedBox.shrink(),

                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),

                // ─── Patient Cards ───
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  sliver: patientsAsync.when(
                    loading: () => SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 60.h),
                          child: const CircularProgressIndicator(
                            color: Color(0xFF0D9488),
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
                            child: _EmptyPatients(
                          onAdd: () => CustomBottomSheet.show(
                            context: context,
                            useDraggable: false,
                            child: const AddPatientSheet(),
                          ),
                        ));
                      }
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final p = patients[i];
                            final colorIdx = i % _cardColors.length;
                            return Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: _PatientCard(
                                patient: p,
                                color: _cardColors[colorIdx],
                                bgColor: _cardBgColors[colorIdx],
                                onViewDashboard: () {
                                  HapticFeedback.lightImpact();
                                  ref
                                      .read(activePatientIdProvider.notifier)
                                      .state = p.patientId;
                                  context.push('/patient/${p.patientId}');
                                },
                                onAddMed: () {
                                  HapticFeedback.lightImpact();
                                  context
                                      .push('/patient/${p.patientId}/add-med');
                                },
                                onShowCode: () =>
                                    _showCodeSheet(context, p),
                                onRemove: () =>
                                    _confirmRemove(context, ref, p),
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

                SliverToBoxAdapter(child: SizedBox(height: 100.h)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCodeSheet(BuildContext context, PatientModel patient) {
    CustomBottomSheet.show(
      context: context,
      useDraggable: false,
      child: Padding(
        padding: EdgeInsets.all(28.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              '${patient.name}\'s Access Code',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Share with your caregiver or family',
              style: GoogleFonts.inter(
                  fontSize: 13.sp, color: const Color(0xFF94A3B8)),
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: patient.accessCode.split('').map((d) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 5.w),
                  height: 56.w,
                  width: 46.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                        color:
                            const Color(0xFF0D9488).withValues(alpha: 0.2)),
                  ),
                  child: Center(
                    child: Text(
                      d,
                      style: GoogleFonts.poppins(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0D9488),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 20.h),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: patient.accessCode));
                SnackbarService.showSuccess('Code copied to clipboard');
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.copy_rounded, size: 18.w, color: Colors.white),
                    SizedBox(width: 8.w),
                    Text(
                      'Copy Code',
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
      ),
    );
  }

  void _confirmRemove(BuildContext context, WidgetRef ref, PatientModel patient) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text('Remove ${patient.name}?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: const Text(
            'This will permanently delete the patient profile and all medication data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(patientRepositoryProvider)
                  .deletePatient(patient.patientId!);
              SnackbarService.showInfo('${patient.name} removed');
            },
            child: Text('Remove',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─── Patient Card ────────────────────────────────────────────────────────────

class _PatientCard extends ConsumerWidget {
  final PatientModel patient;
  final Color color;
  final Color bgColor;
  final VoidCallback onViewDashboard;
  final VoidCallback onAddMed;
  final VoidCallback onShowCode;
  final VoidCallback onRemove;

  const _PatientCard({
    required this.patient,
    required this.color,
    required this.bgColor,
    required this.onViewDashboard,
    required this.onAddMed,
    required this.onShowCode,
    required this.onRemove,
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
            // ─── Top row ───
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
                    child: Text(emoji,
                        style: TextStyle(fontSize: 26.sp)),
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
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${patient.relation} · ${patient.age} yrs',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onRemove,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 32.w,
                    width: 32.w,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.close_rounded,
                        size: 16.w,
                        color: color.withValues(alpha: 0.6)),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // ─── Stats chips ───
            Row(
              children: [
                _InfoChip(
                  icon: Icons.medication_rounded,
                  label: '${activeMeds.length} med${activeMeds.length == 1 ? '' : 's'}',
                  color: color,
                ),
                SizedBox(width: 8.w),
                _InfoChip(
                  icon: Icons.schedule_rounded,
                  label: _totalDosesLabel(activeMeds),
                  color: color,
                ),
                SizedBox(width: 8.w),
                _InfoChip(
                  icon: Icons.local_fire_department_rounded,
                  label: '${patient.age} yrs',
                  color: color,
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // ─── Action row ───
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    label: 'View Dashboard',
                    icon: Icons.dashboard_rounded,
                    color: color,
                    filled: true,
                    onTap: onViewDashboard,
                  ),
                ),
                SizedBox(width: 8.w),
                _IconBtn(
                  icon: Icons.medication_liquid_rounded,
                  color: color,
                  onTap: onAddMed,
                  tooltip: 'Add Med',
                ),
                SizedBox(width: 8.w),
                _IconBtn(
                  icon: Icons.key_rounded,
                  color: color,
                  onTap: onShowCode,
                  tooltip: 'Access Code',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _totalDosesLabel(List<dynamic> meds) {
    final total = meds.fold<int>(
        0, (sum, m) => sum + (m.reminderTimes as List).length);
    if (total == 0) return 'No doses';
    return '$total dose${total == 1 ? '' : 's'}/day';
  }
}

// ─── Chip widgets ─────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

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
          Icon(icon, size: 13.w, color: color),
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

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.filled,
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
        padding: EdgeInsets.symmetric(vertical: 11.h),
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: filled
              ? null
              : Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15.w, color: Colors.white),
            SizedBox(width: 6.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 40.w,
        width: 40.w,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, size: 18.w, color: color),
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────────────────────────

class _EmptyPatients extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyPatients({required this.onAdd});

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
              color: const Color(0xFF0D9488).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline_rounded,
                size: 40.w, color: const Color(0xFF0D9488)),
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
            'Add a family member to start\ntracking their health',
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
                color: const Color(0xFF0D9488),
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 20.w, color: Colors.white),
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

// ─── Stat pill ───────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
  });

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
