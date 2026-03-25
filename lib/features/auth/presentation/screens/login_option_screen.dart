import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_images.dart';
import '../../../../shared/widgets/cure_sync_logo.dart';
import '../providers/auth_provider.dart';

class LoginOptionScreen extends ConsumerStatefulWidget {
  const LoginOptionScreen({super.key});

  @override
  ConsumerState<LoginOptionScreen> createState() => _LoginOptionScreenState();
}

class _LoginOptionScreenState extends ConsumerState<LoginOptionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;
  late Animation<double> _buttonsFade;
  late Animation<Offset> _buttonsSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _heroFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );
    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );
    _buttonsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );
    _buttonsSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  Future<void> _handleGoogleSignIn(BuildContext ctx) async {
    final result =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();

    if (!ctx.mounted) return;

    if (result.success) {
      ctx.go(result.isNewUser ? '/role-selection' : '/dashboard');
    } else if (result.error != null && result.error != 'Sign-in was cancelled') {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(result.error!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// ─── Background: gradient top half ───
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 0.55.sh,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryDark,
                    AppColors.primary,
                    const Color(0xFF14B8A6),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40.r),
                  bottomRight: Radius.circular(40.r),
                ),
              ),
            ),
          ),

          /// ─── Decorative floating elements ───
          ..._buildFloatingElements(),

          /// ─── Content ───
          SafeArea(
            child: Column(
              children: [
                /// === TOP HERO SECTION ===
                Expanded(
                  flex: 55,
                  child: FadeTransition(
                    opacity: _heroFade,
                    child: SlideTransition(
                      position: _heroSlide,
                      child: _buildHeroSection(),
                    ),
                  ),
                ),

                /// === BOTTOM ACTIONS SECTION ===
                Expanded(
                  flex: 45,
                  child: FadeTransition(
                    opacity: _buttonsFade,
                    child: SlideTransition(
                      position: _buttonsSlide,
                      child: _buildActionsSection(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20.h),

          /// Logo
          const CureSyncLogo(size: 48, isWhite: true, showText: false),
          SizedBox(height: 32.h),

          /// Headline
          Text(
            'Your',
            style: TextStyle(
              fontSize: 44.sp,
              fontWeight: FontWeight.w300,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.1,
            ),
          ),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Colors.white,
                AppColors.primaryLight,
              ],
            ).createShader(bounds),
            child: Text(
              'Health',
              style: TextStyle(
                fontSize: 52.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.1,
              ),
            ),
          ),
          Text(
            'In Sync.',
            style: TextStyle(
              fontSize: 44.sp,
              fontWeight: FontWeight.w300,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.1,
            ),
          ),
          SizedBox(height: 16.h),

          /// Subtitle
          Text(
            'Monitor vitals, connect with caregivers,\nand manage medications seamlessly.',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Column(
        children: [
          SizedBox(height: 32.h),

          /// --- Sign Up (primary CTA) ---
          _PrimaryCTAButton(
            text: 'Create Account',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => context.go('/signup'),
          ),
          SizedBox(height: 14.h),

          /// --- Login (secondary) ---
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: OutlinedButton(
              onPressed: () => context.go('/login'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                'I already have an account',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          SizedBox(height: 24.h),

          /// --- Divider ---
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.divider)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  'or continue with',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textHint,
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppColors.divider)),
            ],
          ),
          SizedBox(height: 20.h),

          /// --- Social buttons row ---
          Row(
            children: [
              /// Google
              Expanded(
                child: _SocialButton(
                  icon: SvgPicture.asset(
                    AppImages.googleIcon,
                    width: 22.w,
                    height: 22.w,
                  ),
                  label: 'Google',
                  onPressed: () => _handleGoogleSignIn(context),
                ),
              ),
              SizedBox(width: 14.w),

              /// Apple (placeholder)
              Expanded(
                child: _SocialButton(
                  icon: Icon(
                    Icons.fingerprint_rounded,
                    size: 24.w,
                    color: AppColors.textPrimary,
                  ),
                  label: 'Biometric',
                  onPressed: () {
                    // Biometric auth
                  },
                ),
              ),
            ],
          ),

          const Spacer(),

          /// --- Terms ---
          Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: Text.rich(
              TextSpan(
                text: 'By continuing, you agree to our ',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textHint,
                ),
                children: [
                  TextSpan(
                    text: 'Terms',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const TextSpan(text: ' & '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingElements() {
    return [
      /// Large blurred circle top-right
      Positioned(
        top: -60.h,
        right: -40.w,
        child: Container(
          height: 200.w,
          width: 200.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),

      /// Small circle mid-left
      Positioned(
        top: 0.35.sh,
        left: -20.w,
        child: Container(
          height: 80.w,
          width: 80.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.04),
          ),
        ),
      ),

      /// Tiny dot
      Positioned(
        top: 0.18.sh,
        right: 50.w,
        child: Container(
          height: 12.w,
          width: 12.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryLight.withValues(alpha: 0.5),
          ),
        ),
      ),

      /// Dot cluster
      Positioned(
        top: 0.28.sh,
        right: 30.w,
        child: Container(
          height: 8.w,
          width: 8.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent.withValues(alpha: 0.4),
          ),
        ),
      ),

      /// Cross icon floating
      Positioned(
        top: 0.22.sh,
        right: 40.w,
        child: Transform.rotate(
          angle: pi / 6,
          child: Icon(
            Icons.add_rounded,
            size: 28.w,
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
      ),

      /// Heart icon floating
      Positioned(
        top: 0.38.sh,
        right: 60.w,
        child: Icon(
          Icons.favorite_rounded,
          size: 18.w,
          color: AppColors.accent.withValues(alpha: 0.25),
        ),
      ),
    ];
  }
}

// ─── Primary CTA with gradient & arrow ──────────────────────────
class _PrimaryCTAButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  const _PrimaryCTAButton({
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 56.h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF14B8A6)],
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              height: 28.w,
              width: 28.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: Colors.white, size: 18.w),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Social auth button ─────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 52.h,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.divider, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 15.sp,
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
