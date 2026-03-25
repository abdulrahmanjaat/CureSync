import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_images.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isTermsAccepted = false;

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isTermsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept Terms & Conditions')),
      );
      return;
    }

    final fullName =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

    final result = await ref.read(authControllerProvider.notifier).signUpWithEmail(
      name: fullName,
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (result.success) {
      context.go('/role-selection');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Sign up failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final result =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();

    if (!mounted) return;

    if (result.success) {
      context.go(result.isNewUser ? '/role-selection' : '/dashboard');
    } else if (result.error != null && result.error != 'Sign-in was cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AsyncLoading;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.scaffold,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 220.h,
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40.r),
                  bottomRight: Radius.circular(40.r),
                ),
              ),
              child: SafeArea(
                child: SvgPicture.asset(
                  AppImages.signupIllustration,
                  height: 160.h,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.only(top: 195.h),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32.r),
                  topRight: Radius.circular(32.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    offset: const Offset(0, -4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                child: Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Create Account', style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        SizedBox(height: 4.h),
                        Text('Join CureSync to manage your health journey', style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary)),
                        SizedBox(height: 28.h),

                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _firstNameController,
                                label: 'First name',
                                hint: 'John',
                                validatorType: ValidatorType.name,
                                textInputAction: TextInputAction.next,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: CustomTextField(
                                controller: _lastNameController,
                                label: 'Last name',
                                hint: 'Doe',
                                validatorType: ValidatorType.name,
                                textInputAction: TextInputAction.next,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),

                        CustomTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'you@example.com',
                          validatorType: ValidatorType.email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textHint),
                        ),
                        SizedBox(height: 20.h),

                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Min 8 characters',
                          validatorType: ValidatorType.password,
                          obscureText: true,
                          isPasswordField: true,
                          keyboardType: TextInputType.visiblePassword,
                          textInputAction: TextInputAction.done,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textHint),
                        ),
                        SizedBox(height: 20.h),

                        GestureDetector(
                          onTap: () => setState(() => _isTermsAccepted = !_isTermsAccepted),
                          child: Row(
                            children: [
                              Icon(
                                _isTermsAccepted ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                size: 20.w,
                                color: _isTermsAccepted ? AppColors.primary : AppColors.textHint,
                              ),
                              SizedBox(width: 8.w),
                              Text('I agree to ', style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary)),
                              Text(
                                'Terms & Conditions',
                                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: AppColors.primary, decoration: TextDecoration.underline, decorationColor: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 28.h),

                        CustomButton(text: 'Sign Up', isLoading: isLoading, onPressed: isLoading ? null : _handleSignup),
                        SizedBox(height: 24.h),

                        Row(
                          children: [
                            Expanded(child: Divider(color: AppColors.divider)),
                            Padding(padding: EdgeInsets.symmetric(horizontal: 16.w), child: Text('Or', style: TextStyle(fontSize: 14.sp, color: AppColors.textHint))),
                            Expanded(child: Divider(color: AppColors.divider)),
                          ],
                        ),
                        SizedBox(height: 24.h),

                        SizedBox(
                          width: double.infinity,
                          height: 48.h,
                          child: OutlinedButton(
                            onPressed: isLoading ? null : _handleGoogleSignIn,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.divider, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(AppImages.googleIcon, width: 20.w, height: 20.w),
                                SizedBox(width: 10.w),
                                Text('Continue with Google', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 28.h),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Already have an account? ', style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary)),
                            GestureDetector(
                              onTap: () => context.go('/login'),
                              child: Text('Sign In', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.primary)),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
