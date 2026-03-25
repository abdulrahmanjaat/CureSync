import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../providers/auth_provider.dart';
import '../providers/role_provider.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  UserRole? _selectedRole;
  bool _isSaving = false;

  Future<void> _handleContinue() async {
    if (_selectedRole == null) return;

    setState(() => _isSaving = true);

    await ref.read(authControllerProvider.notifier).updateRole(_selectedRole!);

    if (mounted) {
      setState(() => _isSaving = false);
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 60.h),

              Text(
                'How will you\nuse CureSync?',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Select your role to personalize your experience.',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 48.h),

              _RoleCard(
                icon: Icons.favorite_outline_rounded,
                title: 'Patient',
                subtitle:
                    'Track your vitals, manage medications, and stay connected with your caregivers.',
                isSelected: _selectedRole == UserRole.patient,
                onTap: () => setState(() => _selectedRole = UserRole.patient),
              ),
              SizedBox(height: 16.h),
              _RoleCard(
                icon: Icons.people_outline_rounded,
                title: 'Caregiver',
                subtitle:
                    'Monitor your patients, receive health alerts, and coordinate care seamlessly.',
                isSelected: _selectedRole == UserRole.caregiver,
                onTap: () => setState(() => _selectedRole = UserRole.caregiver),
              ),

              const Spacer(),

              CustomButton(
                text: 'Continue',
                isLoading: _isSaving,
                onPressed: _selectedRole == null || _isSaving
                    ? null
                    : _handleContinue,
                backgroundColor: _selectedRole == null
                    ? AppColors.disabled
                    : AppColors.primary,
              ),
              SizedBox(height: 48.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : AppColors.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              height: 56.w,
              width: 56.w,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                icon,
                size: 28.w,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                height: 24.w,
                width: 24.w,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded, size: 16.w, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}
