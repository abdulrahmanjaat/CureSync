import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/models/caregiver_profile_model.dart';
import '../providers/caregiver_provider.dart';

/// Pro-Caregiver onboarding — single flow (bio, experience, rates, specializations).
/// This screen is only reachable when the user selected Pro Caregiver on role selection.
class CaregiverOnboardingScreen extends ConsumerStatefulWidget {
  const CaregiverOnboardingScreen({super.key});

  @override
  ConsumerState<CaregiverOnboardingScreen> createState() =>
      _CaregiverOnboardingScreenState();
}

class _CaregiverOnboardingScreenState
    extends ConsumerState<CaregiverOnboardingScreen> {
  bool _saving = false;

  final _bioController = TextEditingController();
  int _yearsOfExperience = 1;
  final List<String> _specializations = [];
  double _hourlyRate = 20;
  double _dailyRate = 150;

  static const _allSpecializations = [
    'Post-Surgery Care',
    'Elderly Care',
    'Palliative Care',
    'Paediatric Care',
    'Mental Health',
    'Wound Management',
    'Physiotherapy',
    'Dementia Care',
    'Diabetes Management',
    'Stroke Rehabilitation',
  ];

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final auth = ref.read(authStateProvider).valueOrNull;
    if (auth == null) {
      setState(() => _saving = false);
      return;
    }

    final profile = CaregiverProfileModel(
      uid: auth.uid,
      name: auth.displayName ?? 'Caregiver',
      photoUrl: auth.photoURL,
      caregiverType: CaregiverType.pro,
      bio: _bioController.text.trim().isEmpty
          ? null
          : _bioController.text.trim(),
      yearsOfExperience: _yearsOfExperience,
      hourlyRate: _hourlyRate,
      dailyRate: _dailyRate,
      specializations: _specializations,
      isAvailableForHire: true,
      createdAt: DateTime.now(),
    );

    await ref.read(caregiverRepositoryProvider).saveProfile(profile);

    // Sync to discovery hub so patients can find this caregiver
    await ref
        .read(caregiverRepositoryProvider)
        .syncToDiscoveryHub(profile);

    HapticFeedback.heavyImpact();
    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFA),
      body: Stack(
        children: [
          // Ambient gradient
          Positioned(
            top: -60.h,
            left: -40.w,
            child: Container(
              height: 240.w,
              width: 240.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF0891B2).withValues(alpha: 0.08),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header bar
                Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.go('/role-selection');
                        },
                        child: Container(
                          height: 38.w,
                          width: 38.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                                color: const Color(0xFFE2E8F0)),
                          ),
                          child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 16.w,
                              color: const Color(0xFF0F172A)),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0891B2)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.badge_rounded,
                                size: 14.w,
                                color: const Color(0xFF0891B2)),
                            SizedBox(width: 5.w),
                            Text(
                              'Pro Caregiver',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0891B2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _ProDetailsPage(
                    bioController: _bioController,
                    yearsOfExperience: _yearsOfExperience,
                    onYearsChanged: (v) =>
                        setState(() => _yearsOfExperience = v),
                    specializations: _specializations,
                    onSpecializationToggle: (s) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (_specializations.contains(s)) {
                          _specializations.remove(s);
                        } else {
                          _specializations.add(s);
                        }
                      });
                    },
                    allSpecializations: _allSpecializations,
                    hourlyRate: _hourlyRate,
                    dailyRate: _dailyRate,
                    onPickRates: _pickRates,
                    onSave: _save,
                    saving: _saving,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickRates() async {
    double tempHourly = _hourlyRate;
    double tempDaily = _dailyRate;

    final hourlyItems =
        List.generate(200, (i) => (i + 1).toDouble());
    final dailyItems =
        List.generate(500, (i) => (i + 20).toDouble());

    await showCupertinoModalPopup(
      context: context,
      builder: (_) => Material(
        color: Colors.transparent,
        child: Container(
          height: 340.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: StatefulBuilder(
            builder: (_, setLocal) => Column(
              children: [
                Container(
                  margin: EdgeInsets.symmetric(vertical: 12.h),
                  height: 4,
                  width: 40.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 20.w, vertical: 4.h),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text('Cancel',
                            style: GoogleFonts.inter(
                                fontSize: 15.sp,
                                color: const Color(0xFF94A3B8))),
                      ),
                      Text('Set Rates',
                          style: GoogleFonts.poppins(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A))),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _hourlyRate = tempHourly;
                            _dailyRate = tempDaily;
                          });
                          Navigator.pop(context);
                        },
                        child: Text('Done',
                            style: GoogleFonts.inter(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0D9488))),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text('Hourly (\$)',
                                style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    color: const Color(0xFF94A3B8))),
                            Expanded(
                              child: CupertinoPicker(
                                itemExtent: 44,
                                scrollController:
                                    FixedExtentScrollController(
                                  initialItem: hourlyItems
                                      .indexWhere(
                                          (v) => v == tempHourly)
                                      .clamp(
                                          0, hourlyItems.length - 1),
                                ),
                                onSelectedItemChanged: (i) {
                                  HapticFeedback.selectionClick();
                                  setLocal(() =>
                                      tempHourly = hourlyItems[i]);
                                },
                                children: hourlyItems
                                    .map((v) => Center(
                                          child: Text(
                                            '\$${v.toStringAsFixed(0)}/hr',
                                            style: GoogleFonts.poppins(
                                                fontSize: 18.sp,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color: const Color(
                                                    0xFF0F172A)),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                          width: 1,
                          color: const Color(0xFFE2E8F0)),
                      Expanded(
                        child: Column(
                          children: [
                            Text('Daily (\$)',
                                style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    color: const Color(0xFF94A3B8))),
                            Expanded(
                              child: CupertinoPicker(
                                itemExtent: 44,
                                scrollController:
                                    FixedExtentScrollController(
                                  initialItem: dailyItems
                                      .indexWhere(
                                          (v) => v == tempDaily)
                                      .clamp(
                                          0, dailyItems.length - 1),
                                ),
                                onSelectedItemChanged: (i) {
                                  HapticFeedback.selectionClick();
                                  setLocal(() =>
                                      tempDaily = dailyItems[i]);
                                },
                                children: dailyItems
                                    .map((v) => Center(
                                          child: Text(
                                            '\$${v.toStringAsFixed(0)}/day',
                                            style: GoogleFonts.poppins(
                                                fontSize: 18.sp,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color: const Color(
                                                    0xFF0F172A)),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Pro Details Page ─────────────────────────────────────────────────────────

class _ProDetailsPage extends StatelessWidget {
  final TextEditingController bioController;
  final int yearsOfExperience;
  final ValueChanged<int> onYearsChanged;
  final List<String> specializations;
  final ValueChanged<String> onSpecializationToggle;
  final List<String> allSpecializations;
  final double hourlyRate;
  final double dailyRate;
  final VoidCallback onPickRates;
  final VoidCallback onSave;
  final bool saving;

  const _ProDetailsPage({
    required this.bioController,
    required this.yearsOfExperience,
    required this.onYearsChanged,
    required this.specializations,
    required this.onSpecializationToggle,
    required this.allSpecializations,
    required this.hourlyRate,
    required this.dailyRate,
    required this.onPickRates,
    required this.onSave,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 36.h),
      children: [
        Text(
          'Your Professional\nProfile',
          style: GoogleFonts.poppins(
            fontSize: 26.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            height: 1.2,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Help patients find and trust you.',
          style: GoogleFonts.inter(
              fontSize: 13.sp, color: const Color(0xFF94A3B8)),
        ),
        SizedBox(height: 28.h),

        // Bio
        Text('Short Bio',
            style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A))),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: bioController,
            maxLines: 3,
            maxLength: 200,
            style: GoogleFonts.inter(
                fontSize: 14.sp, color: const Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText:
                  'e.g. Certified nurse with 5 years in elderly care...',
              hintStyle: GoogleFonts.inter(
                  fontSize: 13.sp, color: const Color(0xFF94A3B8)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(14.w),
              counterStyle: GoogleFonts.inter(
                  fontSize: 11.sp, color: const Color(0xFFCBD5E1)),
            ),
          ),
        ),
        SizedBox(height: 20.h),

        // Years of experience
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text('Years of Experience',
                  style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A))),
            ),
            Row(
              children: [
                _CircleBtn(
                  icon: Icons.remove_rounded,
                  onTap: () {
                    if (yearsOfExperience > 0) {
                      HapticFeedback.selectionClick();
                      onYearsChanged(yearsOfExperience - 1);
                    }
                  },
                ),
                SizedBox(
                  width: 44.w,
                  child: Center(
                    child: Text(
                      '$yearsOfExperience',
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
                _CircleBtn(
                  icon: Icons.add_rounded,
                  onTap: () {
                    if (yearsOfExperience < 50) {
                      HapticFeedback.selectionClick();
                      onYearsChanged(yearsOfExperience + 1);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 20.h),

        // Rates
        GestureDetector(
          onTap: onPickRates,
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: 42.w,
                  width: 42.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Icons.monetization_on_rounded,
                      size: 22.w, color: const Color(0xFF0D9488)),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Service Rates',
                          style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A))),
                      Text(
                        '\$${hourlyRate.toStringAsFixed(0)}/hr  ·  \$${dailyRate.toStringAsFixed(0)}/day',
                        style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 20.w, color: const Color(0xFFCBD5E1)),
              ],
            ),
          ),
        ),
        SizedBox(height: 20.h),

        // Specializations
        Text('Specializations',
            style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A))),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: allSpecializations.map((s) {
            final isSelected = specializations.contains(s);
            return GestureDetector(
              onTap: () => onSpecializationToggle(s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: EdgeInsets.symmetric(
                    horizontal: 12.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0D9488)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0D9488)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  s,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 36.h),

        // Save button
        GestureDetector(
          onTap: saving ? null : onSave,
          child: Container(
            height: 56.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [
                Color(0xFF0D9488),
                Color(0xFF0891B2),
              ]),
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(
                  color:
                      const Color(0xFF0D9488).withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Center(
              child: saving
                  ? const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5)
                  : Text(
                      'Complete Setup →',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32.w,
        width: 32.w,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child:
            Icon(icon, size: 16.w, color: const Color(0xFF0F172A)),
      ),
    );
  }
}
