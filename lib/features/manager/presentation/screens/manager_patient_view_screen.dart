import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../patient/presentation/providers/medication_provider.dart';
import '../../../patient/presentation/screens/home_screen.dart';

/// Wraps the existing [HomeScreen] Bento Dashboard in a [ProviderScope] that
/// pins [resolvedActivePatientIdProvider] to [patientId], making the entire
/// dashboard dynamically render data for the manager's chosen patient.
///
/// The original HomeScreen is completely untouched — this screen is the sole
/// injection point for the manager's patient context.
class ManagerPatientViewScreen extends StatelessWidget {
  final String patientId;

  const ManagerPatientViewScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        resolvedActivePatientIdProvider.overrideWithValue(patientId),
      ],
      child: Scaffold(
        body: Stack(
          children: [
            // Bento Dashboard in tracking-only mode for this specific patientId.
            // SOS, Quick Actions, and Care Circle are hidden.
            // Assigned Caregiver footer is shown at the bottom.
            const HomeScreen(trackingOnly: true),

            // Back button overlay (HomeScreen has no AppBar for this role)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8.h,
              left: 16.w,
              child: _BackButton(onTap: () => context.pop()),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40.w,
        width: 40.w,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18.w,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }
}
