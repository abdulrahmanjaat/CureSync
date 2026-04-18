import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/utils/snackbar_service.dart';
import '../../../../auth/data/models/patient_model.dart';
import 'bento_card.dart';

/// Displays the patient's access code with a one-tap copy button.
///
/// The code lives in patients/{uid}.accessCode and is the entry-point for
/// family members and caregivers to join the patient's care circle.
class AccessCodeCard extends StatelessWidget {
  final PatientModel? patient;

  const AccessCodeCard({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final code = patient?.accessCode ?? '';
    final memberCount = patient?.accessList.length ?? 0;
    final isLoading = patient == null || code.isEmpty;

    // Display digits with generous spacing: "84521" → "8  4  5  2  1"
    final displayCode = isLoading ? '· · · · ·' : code.split('').join('  ');

    return BentoCard(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Row(
            children: [
              Container(
                height: 38.w,
                width: 38.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.link_rounded,
                  size: 20.w,
                  color: const Color(0xFF7C3AED),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Care Circle Code',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      isLoading
                          ? 'Generating your code…'
                          : memberCount == 0
                              ? 'Share to invite family or a caregiver'
                              : '$memberCount ${memberCount == 1 ? 'person' : 'people'} joined your circle',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: memberCount == 0
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 14.h),

          // ── Code display ─────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 18.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7C3AED).withValues(alpha: 0.07),
                  const Color(0xFF0D9488).withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.18)),
            ),
            child: Column(
              children: [
                Text(
                  displayCode,
                  style: GoogleFonts.poppins(
                    fontSize: 30.sp,
                    fontWeight: FontWeight.w800,
                    color: isLoading
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF7C3AED),
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  isLoading
                      ? 'Setting up your care circle…'
                      : 'Your unique 5-digit invite code',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // ── Action row ───────────────────────────────────────────────────
          Row(
            children: [
              // Copy button
              Expanded(
                child: GestureDetector(
                  onTap: isLoading
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          Clipboard.setData(ClipboardData(text: code));
                          SnackbarService.showSuccess('Code copied to clipboard!');
                        },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: isLoading
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF7C3AED),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: isLoading
                          ? []
                          : [
                              BoxShadow(
                                color: const Color(0xFF7C3AED)
                                    .withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.copy_rounded,
                            size: 15.w, color: Colors.white),
                        SizedBox(width: 7.w),
                        Text(
                          isLoading ? 'Generating…' : 'Copy Code',
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(width: 10.w),

              // Share button
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _showHowItWorks(context, code);
                },
                child: Container(
                  height: 44.h,
                  width: 44.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12.r),
                    border:
                        Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 18.w,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bottom sheet explaining how to use the access code.
  void _showHowItWorks(BuildContext context, String code) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 40.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 22.h),

            Container(
              height: 56.w,
              width: 56.w,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.group_add_rounded,
                  size: 28.w, color: const Color(0xFF7C3AED)),
            ),
            SizedBox(height: 14.h),

            Text(
              'How to invite someone',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Share your code and they can join your care circle from their app.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),

            SizedBox(height: 24.h),

            // Steps
            _Step(
              number: '1',
              text:
                  'Share your code  $code  with the person you want to invite.',
            ),
            SizedBox(height: 12.h),
            _Step(
              number: '2',
              text:
                  'They open CureSync, sign up as Family or Pro Caregiver, then enter your code.',
            ),
            SizedBox(height: 12.h),
            _Step(
              number: '3',
              text:
                  'Once linked, they can view your health data and get SOS alerts.',
            ),

            SizedBox(height: 28.h),

            // Copy again
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Clipboard.setData(ClipboardData(text: code));
                Navigator.pop(context);
                SnackbarService.showSuccess('Code copied!');
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Copy Code  $code',
                    style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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
}

// ─── Step widget ──────────────────────────────────────────────────────────────

class _Step extends StatelessWidget {
  final String number;
  final String text;
  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 24.w,
          width: 24.w,
          decoration: const BoxDecoration(
            color: Color(0xFF7C3AED),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: const Color(0xFF0F172A),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
