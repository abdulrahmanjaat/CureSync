import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/role_provider.dart';

class DashboardPlaceholderScreen extends ConsumerWidget {
  const DashboardPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(roleProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final isPatient = role == UserRole.patient;

    // Load role from Firestore if not set locally
    if (role == null && user != null) {
      ref.listen(userDataProvider(user.uid), (_, next) {
        next.whenData((userData) {
          if (userData?.role != null) {
            final firestoreRole = userData!.role == 'patient'
                ? UserRole.patient
                : UserRole.caregiver;
            ref.read(roleProvider.notifier).selectRole(firestoreRole);
          }
        });
      });
    }

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24.h),

              /// --- Header ---
              Row(
                children: [
                  Container(
                    height: 48.w,
                    width: 48.w,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(
                      isPatient ? Icons.favorite_rounded : Icons.people_rounded,
                      color: Colors.white,
                      size: 24.w,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back!',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          user?.displayName ?? 'User',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await ref.read(authControllerProvider.notifier).signOut();
                    },
                    child: Container(
                      height: 40.w,
                      width: 40.w,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        color: AppColors.textSecondary,
                        size: 20.w,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              /// --- Role badge ---
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(100.r),
                ),
                child: Text(
                  isPatient ? '🩺 Patient' : '👥 Caregiver',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              SizedBox(height: 40.h),

              /// --- Placeholder ---
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 100.w,
                        width: 100.w,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPatient
                              ? Icons.monitor_heart_outlined
                              : Icons.medical_information_outlined,
                          size: 48.w,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        isPatient
                            ? 'Your health dashboard\nis coming soon'
                            : 'Patient management\nis coming soon',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
