import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/custom_bottom_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/patient_provider.dart';
import '../widgets/greeting_header.dart';
import '../widgets/add_patient_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final patientsAsync = ref.watch(patientsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFDFC),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          children: [
            /// ═══ GREETING ═══
            GreetingHeader(
              name: user?.displayName ?? 'User',
              photoUrl: user?.photoURL,
              onLogout: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
            ),
            SizedBox(height: 28.h),

            /// ═══ SECTION TITLE ═══
            Text(
              'Patient Profiles',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Manage health records for your family',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 20.h),

            /// ═══ 2-COLUMN GRID ═══
            patientsAsync.when(
              loading: () => SizedBox(
                height: 160.h,
                child: const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (e, _) => _ErrorTile(
                error: e.toString(),
                onRetry: () => ref.invalidate(patientsStreamProvider),
              ),
              data: (patients) {
                // Build grid items: My Profile + each patient + Add card
                final items = <Widget>[
                  /// My Profile card (from auth user)
                  _ProfileCard(
                    name: user?.displayName ?? 'My Profile',
                    subtitle: 'Your personal health',
                    icon: Icons.person_rounded,
                    gradient: const [Color(0xFF0D9488), Color(0xFF14B8A6)],
                    onTap: () {
                      // Navigate to own profile details
                    },
                  ),

                  /// Patient cards
                  ...patients.map((p) => _ProfileCard(
                        name: p.name,
                        subtitle: '${p.relation} · ${p.age} yrs',
                        icon: Icons.favorite_rounded,
                        code: p.accessCode,
                        gradient: const [
                          Color(0xFF0891B2),
                          Color(0xFF06B6D4)
                        ],
                        onTap: () =>
                            context.push('/patient/${p.patientId}'),
                      )),

                  /// Add new member card
                  _AddCard(
                    onTap: () => _showAddSheet(context),
                  ),
                ];

                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14.h,
                  crossAxisSpacing: 14.w,
                  childAspectRatio: 0.85,
                  children: items,
                );
              },
            ),
          ],
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
class _ProfileCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final String? code;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    this.code,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Avatar
            Container(
              height: 48.w,
              width: 48.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(icon, size: 24.w, color: Colors.white),
            ),
            SizedBox(height: 14.h),

            Text(
              name,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),

            const Spacer(),

            if (code != null)
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  code!,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                    letterSpacing: 2,
                  ),
                ),
              )
            else
              Icon(Icons.arrow_forward_rounded,
                  size: 18.w, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _AddCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 52.w,
              width: 52.w,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child:
                  Icon(Icons.add_rounded, size: 28.w, color: AppColors.accent),
            ),
            SizedBox(height: 12.h),
            Text(
              'Add Family\nMember',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorTile({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Text(error,
              style: TextStyle(fontSize: 12.sp, color: AppColors.textHint)),
          SizedBox(height: 10.h),
          GestureDetector(
            onTap: onRetry,
            child: Text('Retry',
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
