import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/custom_bottom_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/patient_provider.dart';
import '../widgets/greeting_header.dart';
import '../widgets/access_code_card.dart';
import '../widgets/health_snapshot.dart';
import '../widgets/patient_profiles_section.dart';
import '../widgets/add_patient_sheet.dart';

class PatientDashboardScreen extends ConsumerWidget {
  const PatientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final patientsAsync = ref.watch(patientsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFDFC),
      body: SafeArea(
        child: patientsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) {
            debugPrint('Dashboard error: $e');
            return Center(
              child: Padding(
                padding: EdgeInsets.all(32.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off_rounded,
                        size: 48.w, color: AppColors.textHint),
                    SizedBox(height: 16.h),
                    Text(
                      'Something went wrong',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      e.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textHint,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    GestureDetector(
                      onTap: () => ref.invalidate(patientsStreamProvider),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          data: (patients) {
            final firstPatient =
                patients.isNotEmpty ? patients.first : null;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async =>
                  ref.invalidate(patientsStreamProvider),
              child: ListView(
                padding: EdgeInsets.symmetric(
                    horizontal: 20.w, vertical: 16.h),
                children: [
                  /// ═══ GREETING ═══
                  GreetingHeader(
                    name: user?.displayName ?? 'User',
                    photoUrl: user?.photoURL,
                    onLogout: () => ref
                        .read(authControllerProvider.notifier)
                        .signOut(),
                  ),
                  SizedBox(height: 24.h),

                  /// ═══ ACCESS CODE ═══
                  if (firstPatient != null) ...[
                    AccessCodeCard(
                      code: firstPatient.accessCode,
                      patientName: firstPatient.name,
                    ),
                    SizedBox(height: 24.h),
                  ],

                  /// ═══ HEALTH SNAPSHOT ═══
                  const HealthSnapshot(),
                  SizedBox(height: 24.h),

                  /// ═══ PATIENT PROFILES ═══
                  PatientProfilesSection(
                    patients: patients,
                    onAdd: () => _showAddSheet(context),
                    onTap: (p) {
                      // Future: navigate to patient detail
                    },
                  ),
                  SizedBox(height: 24.h),

                  /// ═══ QUICK ACTIONS ═══
                  _QuickActions(
                    onAddPatient: () => _showAddSheet(context),
                  ),
                  SizedBox(height: 32.h),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    CustomBottomSheet.show(
      context: context,
      useDraggable: false,
      child: const AddPatientSheet(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Quick Actions grid
// ═══════════════════════════════════════════════════════════════════
class _QuickActions extends StatelessWidget {
  final VoidCallback onAddPatient;

  const _QuickActions({required this.onAddPatient});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.person_add_alt_1_rounded,
                label: 'Add Patient',
                color: AppColors.primary,
                onTap: onAddPatient,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _ActionTile(
                icon: Icons.medication_rounded,
                label: 'Medications',
                color: AppColors.warning,
                onTap: () {},
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _ActionTile(
                icon: Icons.calendar_month_rounded,
                label: 'Appointments',
                color: AppColors.info,
                onTap: () {},
              ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 10.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: color.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 40.w,
              width: 40.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, size: 22.w, color: color),
            ),
            SizedBox(height: 10.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
