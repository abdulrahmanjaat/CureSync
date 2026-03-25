import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_images.dart';
import '../../../../core/utils/snackbar_service.dart';
import '../widgets/auth_header_illustration.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/custom_bottom_sheet.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../providers/auth_provider.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref.read(authControllerProvider.notifier).signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (result.success) {
      TextInput.finishAutofillContext();
      // Router redirect handles navigation based on role
    } else {
      SnackbarService.showError(result.error ?? 'Login failed');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final result =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();

    if (!mounted) return;

    if (!result.success && result.error != null && result.error != 'Sign-in was cancelled') {
      SnackbarService.showError(result.error!);
    }
    // Router redirect handles navigation based on role
  }

  @override
  void dispose() {
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
      body: LoadingOverlay(
        isLoading: isLoading,
        message: 'Signing in...',
        child: Stack(
          children: [
            /// --- Top gradient ---
            const Positioned(
              top: 0, left: 0, right: 0,
              child: AuthHeaderIllustration(type: AuthHeaderType.login),
            ),

            /// --- Form ---
            Padding(
              padding: EdgeInsets.only(top: 230.h),
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
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome Back!',
                            style: TextStyle(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Sign in to continue managing your health',
                            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
                          ),
                          SizedBox(height: 36.h),

                          CustomTextField(
                            controller: _emailController,
                            label: 'Email',
                            hint: 'Enter your email',
                            validatorType: ValidatorType.email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            autofillHints: const [AutofillHints.email],
                            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textHint),
                          ),
                          SizedBox(height: 20.h),

                          CustomTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: 'Enter your password',
                            validatorType: ValidatorType.password,
                            obscureText: true,
                            isPasswordField: true,
                            keyboardType: TextInputType.visiblePassword,
                            textInputAction: TextInputAction.done,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            autofillHints: const [AutofillHints.password],
                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textHint),
                            onEditingComplete: _handleLogin,
                          ),
                          SizedBox(height: 16.h),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _rememberMe = !_rememberMe),
                                child: Row(
                                  children: [
                                    Icon(
                                      _rememberMe
                                          ? Icons.check_box_rounded
                                          : Icons.check_box_outline_blank_rounded,
                                      size: 20.w,
                                      color: _rememberMe ? AppColors.primary : AppColors.textHint,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text('Remember me', style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => CustomBottomSheet.show(
                                  context: context,
                                  initialChildSize: 0.55,
                                  child: const ForgotPasswordSheet(),
                                ),
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(fontSize: 14.sp, color: AppColors.primary, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 32.h),

                          CustomButton(
                            text: 'Login',
                            onPressed: _handleLogin,
                          ),
                          SizedBox(height: 24.h),

                          _buildOrDivider(),
                          SizedBox(height: 24.h),

                          _buildGoogleButton(),
                          SizedBox(height: 32.h),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Don't have an account? ", style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary)),
                              GestureDetector(
                                onTap: () => context.go('/signup'),
                                child: Text('Sign Up', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.primary)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text('Or', style: TextStyle(fontSize: 14.sp, color: AppColors.textHint)),
        ),
        Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: OutlinedButton(
        onPressed: _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.divider, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(AppImages.googleIcon, width: 20.w, height: 20.w),
            SizedBox(width: 10.w),
            Text(
              'Continue with Google',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
