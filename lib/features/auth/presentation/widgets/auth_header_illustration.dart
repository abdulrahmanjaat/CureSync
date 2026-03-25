import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';

enum AuthHeaderType { login, signup }

class AuthHeaderIllustration extends StatelessWidget {
  final AuthHeaderType type;

  const AuthHeaderIllustration({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: type == AuthHeaderType.login ? 260.h : 220.h,
      child: Stack(
        children: [
          /// --- Gradient background ---
          Positioned.fill(
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

          /// --- Decorative elements ---
          ..._buildDecorations(),

          /// --- Center content ---
          SafeArea(
            child: Center(
              child: type == AuthHeaderType.login
                  ? _buildLoginContent()
                  : _buildSignupContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 12.h),

        /// Shield with pulse
        Stack(
          alignment: Alignment.center,
          children: [
            /// Pulse rings
            _PulseRing(size: 140),
            _PulseRing(size: 110),

            /// Shield icon
            Container(
              height: 72.w,
              width: 72.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.shield_rounded,
                size: 36.w,
                color: Colors.white,
              ),
            ),

            /// Lock badge
            Positioned(
              bottom: 42.h,
              right: 100.w,
              child: Container(
                height: 32.w,
                width: 32.w,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: Icon(Icons.lock_rounded, size: 16.w, color: Colors.white),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        /// Tagline
        Text(
          'Secure Health Access',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.7),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSignupContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 8.h),

        /// People + plus icon
        Stack(
          alignment: Alignment.center,
          children: [
            /// Outer ring
            Container(
              height: 100.w,
              width: 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 2,
                ),
              ),
            ),

            /// Inner circle with icon
            Container(
              height: 68.w,
              width: 68.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_add_alt_1_rounded,
                size: 34.w,
                color: Colors.white,
              ),
            ),

            /// Floating hearts
            Positioned(
              top: 2.h,
              right: 2.w,
              child: _FloatingIcon(
                icon: Icons.favorite_rounded,
                size: 22,
                color: AppColors.accent,
              ),
            ),
            Positioned(
              bottom: 5.h,
              left: 0,
              child: _FloatingIcon(
                icon: Icons.add_circle_rounded,
                size: 20,
                color: AppColors.primaryLight,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),

        Text(
          'Join CureSync',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.7),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDecorations() {
    return [
      /// Large blurred circle top-right
      Positioned(
        top: -30.h,
        right: -25.w,
        child: Container(
          height: 120.w,
          width: 120.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ),

      /// Small circle bottom-left
      Positioned(
        bottom: 20.h,
        left: -15.w,
        child: Container(
          height: 60.w,
          width: 60.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.04),
          ),
        ),
      ),

      /// Medical cross top-left
      Positioned(
        top: 50.h,
        left: 24.w,
        child: Transform.rotate(
          angle: pi / 6,
          child: Icon(
            Icons.add_rounded,
            size: 24.w,
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),

      /// Dot top-right
      Positioned(
        top: 70.h,
        right: 40.w,
        child: Container(
          height: 8.w,
          width: 8.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryLight.withValues(alpha: 0.4),
          ),
        ),
      ),

      /// Heart icon
      Positioned(
        bottom: 40.h,
        right: 30.w,
        child: Icon(
          Icons.favorite_rounded,
          size: 14.w,
          color: AppColors.accent.withValues(alpha: 0.3),
        ),
      ),

      /// Medical cross bottom
      Positioned(
        bottom: 50.h,
        left: 50.w,
        child: Icon(
          Icons.add_rounded,
          size: 18.w,
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
    ];
  }
}

class _PulseRing extends StatelessWidget {
  final double size;

  const _PulseRing({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size.w,
      width: size.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.5,
        ),
      ),
    );
  }
}

class _FloatingIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;

  const _FloatingIcon({
    required this.icon,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: (size + 10).w,
      width: (size + 10).w,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: size.w, color: color),
    );
  }
}
