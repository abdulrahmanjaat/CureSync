import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/snackbar_service.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordSheet extends ConsumerStatefulWidget {
  const ForgotPasswordSheet({super.key});

  @override
  ConsumerState<ForgotPasswordSheet> createState() =>
      _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<ForgotPasswordSheet> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _emailSent = false;

  Future<void> _handleSendReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_emailController.text.trim());

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success) {
      setState(() => _emailSent = true);
    } else {
      SnackbarService.showError(result.error ?? 'Failed to send reset email');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 24.h),

            if (_emailSent) ..._buildSuccessState() else ..._buildEmailStep(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEmailStep() {
    return [
      Text(
        'Forgot Password',
        style: TextStyle(
          fontSize: 24.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      SizedBox(height: 8.h),
      Text(
        'Enter your email address and we\'ll send you a link to reset your password.',
        style: TextStyle(
          fontSize: 14.sp,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
      SizedBox(height: 28.h),
      CustomTextField(
        controller: _emailController,
        label: 'Email',
        hint: 'Enter your email',
        validatorType: ValidatorType.email,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textHint),
      ),
      SizedBox(height: 32.h),
      CustomButton(
        text: 'Send Reset Link',
        isLoading: _isLoading,
        onPressed: _isLoading ? null : _handleSendReset,
      ),
    ];
  }

  List<Widget> _buildSuccessState() {
    return [
      Center(
        child: Container(
          height: 72.w,
          width: 72.w,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            color: AppColors.success,
            size: 36.w,
          ),
        ),
      ),
      SizedBox(height: 24.h),
      Center(
        child: Text(
          'Check Your Email',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      SizedBox(height: 8.h),
      Center(
        child: Text(
          'We\'ve sent a password reset link to\n${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ),
      SizedBox(height: 32.h),
      CustomButton(
        text: 'Done',
        onPressed: () => Navigator.of(context).pop(),
      ),
    ];
  }
}
