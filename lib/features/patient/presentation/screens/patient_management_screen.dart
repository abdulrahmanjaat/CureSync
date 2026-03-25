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
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/patient_provider.dart';
import '../providers/active_patient_provider.dart';
import '../widgets/add_patient_sheet.dart';
import '../widgets/dashboard/glass_card.dart';

class PatientManagementScreen extends ConsumerWidget {
  const PatientManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final patientsAsync = ref.watch(patientsStreamProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B1F1E),
              Color(0xFF0F2928),
              Color(0xFF122D2B),
              Color(0xFF0B1F1E),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            children: [
              /// ═══ HEADER ═══
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      height: 40.w,
                      width: 40.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16.w, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Text(
                    'Manage Family Members',
                    style: GoogleFonts.poppins(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms),

              SizedBox(height: 24.h),

              /// ═══ MY PROFILE CARD ═══
              GlassCard(
                padding: EdgeInsets.all(16.w),
                tintColor: const Color(0xFF0D3D38),
                child: Row(
                  children: [
                    Container(
                      height: 50.w,
                      width: 50.w,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Center(
                        child: Text(
                          (user?.displayName ?? 'U')[0].toUpperCase(),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Myself (${user?.displayName ?? "User"})',
                            style: GoogleFonts.poppins(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Myself',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ActionChip(
                      label: 'View Dashboard',
                      color: const Color(0xFF0D9488),
                      onTap: () {
                        ref.read(activePatientIdProvider.notifier).state = null;
                        context.pop();
                      },
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms)
                  .slideX(begin: -0.05, end: 0, duration: 400.ms, delay: 100.ms),

              SizedBox(height: 12.h),

              /// ═══ PATIENT CARDS ═══
              patientsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF5EEAD4), strokeWidth: 2),
                ),
                error: (_, _) => Text('Error loading patients',
                    style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: Colors.white.withValues(alpha: 0.5))),
                data: (patients) {
                  return Column(
                    children: [
                      ...patients.asMap().entries.map((entry) {
                        final i = entry.key;
                        final p = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _PatientAdminCard(
                            patient: p,
                            onViewDashboard: () {
                              ref
                                  .read(activePatientIdProvider.notifier)
                                  .state = p.patientId;
                              context.pop();
                            },
                            onAccessCode: () =>
                                _showCodeSheet(context, p),
                            onRemove: () =>
                                _confirmRemove(context, ref, p),
                          )
                              .animate()
                              .fadeIn(
                                  duration: 400.ms,
                                  delay: (200 + i * 100).ms)
                              .slideX(
                                  begin: -0.05,
                                  end: 0,
                                  duration: 400.ms,
                                  delay: (200 + i * 100).ms),
                        );
                      }),
                    ],
                  );
                },
              ),

              SizedBox(height: 16.h),

              /// ═══ ADD MEMBER ═══
              GestureDetector(
                onTap: () => CustomBottomSheet.show(
                  context: context,
                  useDraggable: false,
                  child: const AddPatientSheet(),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                        const Color(0xFFFF6B6B).withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 32.w,
                        width: 32.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(Icons.add_rounded,
                            size: 20.w, color: Colors.white),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'Add New Member',
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFF6B6B),
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 500.ms),

              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  void _showCodeSheet(BuildContext context, PatientModel patient) {
    CustomBottomSheet.show(
      context: context,
      useDraggable: false,
      child: Container(
        padding: EdgeInsets.all(28.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Access Code for ${patient.name}',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: patient.accessCode.split('').map((d) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 5.w),
                  height: 56.w,
                  width: 46.w,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      d,
                      style: GoogleFonts.poppins(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16.h),
            GestureDetector(
              onTap: () {
                Clipboard.setData(
                    ClipboardData(text: patient.accessCode));
                SnackbarService.showSuccess('Code copied');
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 20.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy_rounded,
                        size: 16.w, color: Colors.white),
                    SizedBox(width: 6.w),
                    Text(
                      'Copy Code',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'Share this code with your caregiver',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemove(
      BuildContext context, WidgetRef ref, PatientModel patient) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r)),
        title: Text('Remove ${patient.name}?'),
        content: const Text(
            'This will delete the patient profile and all their medication data.'),
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

class _PatientAdminCard extends StatelessWidget {
  final PatientModel patient;
  final VoidCallback onViewDashboard;
  final VoidCallback onAccessCode;
  final VoidCallback onRemove;

  const _PatientAdminCard({
    required this.patient,
    required this.onViewDashboard,
    required this.onAccessCode,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44.w,
                width: 44.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Center(
                  child: Icon(Icons.favorite_rounded,
                      size: 22.w, color: const Color(0xFFFF6B6B)),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${patient.relation} (Age: ${patient.age})',
                      style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      patient.name,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onRemove,
                child: Icon(Icons.close_rounded,
                    size: 18.w,
                    color: Colors.white.withValues(alpha: 0.3)),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _ActionChip(
                label: 'View Dashboard',
                color: const Color(0xFF0D9488),
                onTap: onViewDashboard,
              ),
              SizedBox(width: 8.w),
              _ActionChip(
                label: 'Access Code',
                color: const Color(0xFF0891B2),
                onTap: onAccessCode,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
