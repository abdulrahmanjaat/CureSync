import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/models/caregiver_profile_model.dart';
import '../providers/caregiver_provider.dart';

// ─── Constants ────────────────────────────────────────────────────────────────

const _kAccent = Color(0xFF0891B2);
const _kTeal = Color(0xFF0D9488);
const _kSurface = Color(0xFFF8FBFA);
const _kBorder = Color(0xFFE2E8F0);
const _kMuted = Color(0xFF94A3B8);
const _kText = Color(0xFF0F172A);
const _kSubtext = Color(0xFF64748B);

const _allSpecializations = [
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
  'ICU / Critical Care',
  'Oncology Care',
  'Cardiac Care',
  'Orthopaedic Care',
  'Neurological Care',
];

const _allQualifications = [
  'Registered Nurse (RN)',
  'Licensed Practical Nurse (LPN)',
  'Certified Nursing Assistant (CNA)',
  'Certified Home Health Aide (CHHA)',
  'First Aid & CPR Certified',
  'Dementia Care Specialist',
  'Palliative Care Certification',
  'Paediatric Care Certification',
  'Medication Management Certified',
  'Physical Therapy Assistant',
  'Mental Health First Aid',
  'Wound Care Certified',
];

// ─── Screen ───────────────────────────────────────────────────────────────────

/// 4-step Pro Caregiver onboarding.
/// Step 1 – Professional Profile (bio, experience, availability)
/// Step 2 – Skills & Languages (specializations, languages spoken)
/// Step 3 – Credentials & Work History (qualifications, past roles, licence)
/// Step 4 – Service Rates & Availability (hourly / daily / monthly, hire toggle)
class CaregiverOnboardingScreen extends ConsumerStatefulWidget {
  const CaregiverOnboardingScreen({super.key});

  @override
  ConsumerState<CaregiverOnboardingScreen> createState() =>
      _CaregiverOnboardingScreenState();
}

class _CaregiverOnboardingScreenState
    extends ConsumerState<CaregiverOnboardingScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _saving = false;

  // ── Step 1 state ────────────────────────────────────────────────────────────
  final _bioController = TextEditingController();
  int _yearsOfExperience = 1;
  AvailabilityPreference _availability = AvailabilityPreference.both;

  // ── Step 2 state ────────────────────────────────────────────────────────────
  final List<String> _specializations = [];
  final List<String> _languages = ['English'];
  final _langController = TextEditingController();

  // ── Step 3 state ────────────────────────────────────────────────────────────
  final List<String> _qualifications = [];
  final List<WorkHistoryItem> _workHistory = [];
  final _licenseController = TextEditingController();
  bool _bgCheckAcknowledged = false;

  // ── Step 4 state ────────────────────────────────────────────────────────────
  double _hourlyRate = 20;
  double _dailyRate = 150;
  double _monthlyRate = 2500;
  bool _isAvailableForHire = true;

  @override
  void dispose() {
    _pageController.dispose();
    _bioController.dispose();
    _langController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  // ── Navigation ───────────────────────────────────────────────────────────────

  void _goNext() {
    if (_currentStep < 3) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    } else {
      _save();
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/role-selection');
    }
  }

  // ── Save ─────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_bgCheckAcknowledged) {
      _showSnack('Please acknowledge the background check declaration.');
      return;
    }
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
      availability: _availability,
      specializations: _specializations,
      languages: _languages,
      certifications: _qualifications
          .map((q) => CertificationItem(name: q))
          .toList(),
      workHistory: _workHistory,
      licenseNumber: _licenseController.text.trim().isEmpty
          ? null
          : _licenseController.text.trim(),
      backgroundCheckAcknowledged: _bgCheckAcknowledged,
      hourlyRate: _hourlyRate,
      dailyRate: _dailyRate,
      monthlyRate: _monthlyRate,
      isAvailableForHire: _isAvailableForHire,
      onboardingComplete: true,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(caregiverRepositoryProvider).saveProfile(profile);
      await ref.read(caregiverRepositoryProvider).syncToDiscoveryHub(profile);
      HapticFeedback.heavyImpact();
      if (mounted) context.go('/dashboard');
    } catch (e) {
      setState(() => _saving = false);
      _showSnack('Failed to save profile. Please try again.');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13.sp)),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }

  // ── Rate picker ──────────────────────────────────────────────────────────────

  Future<void> _pickRates() async {
    double tempHourly = _hourlyRate;
    double tempDaily = _dailyRate;
    double tempMonthly = _monthlyRate;

    final hourlyItems = List.generate(200, (i) => (i + 1).toDouble());
    final dailyItems = List.generate(500, (i) => (i + 20).toDouble());
    final monthlyItems = List.generate(240, (i) => ((i + 1) * 100).toDouble());

    await showCupertinoModalPopup(
      context: context,
      builder: (_) => Material(
        color: Colors.transparent,
        child: Container(
          height: 380.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: StatefulBuilder(
            builder: (_, setLocal) => Column(
              children: [
                // Handle
                Container(
                  margin: EdgeInsets.symmetric(vertical: 12.h),
                  height: 4,
                  width: 40.w,
                  decoration: BoxDecoration(
                    color: _kBorder,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                // Header row
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text('Cancel',
                            style: GoogleFonts.inter(
                                fontSize: 15.sp, color: _kMuted)),
                      ),
                      Text('Set Rates',
                          style: GoogleFonts.poppins(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: _kText)),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _hourlyRate = tempHourly;
                            _dailyRate = tempDaily;
                            _monthlyRate = tempMonthly;
                          });
                          Navigator.pop(context);
                        },
                        child: Text('Done',
                            style: GoogleFonts.inter(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: _kTeal)),
                      ),
                    ],
                  ),
                ),
                // Column headers
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text('Hourly (\$)',
                              style: GoogleFonts.inter(
                                  fontSize: 11.sp, color: _kMuted)),
                        ),
                      ),
                      Container(width: 1, height: 16.h, color: _kBorder),
                      Expanded(
                        child: Center(
                          child: Text('Daily (\$)',
                              style: GoogleFonts.inter(
                                  fontSize: 11.sp, color: _kMuted)),
                        ),
                      ),
                      Container(width: 1, height: 16.h, color: _kBorder),
                      Expanded(
                        child: Center(
                          child: Text('Monthly (\$)',
                              style: GoogleFonts.inter(
                                  fontSize: 11.sp, color: _kMuted)),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4.h),
                // Pickers
                Expanded(
                  child: Row(
                    children: [
                      _RatePicker(
                        items: hourlyItems,
                        initial: tempHourly,
                        suffix: '/hr',
                        onChanged: (v) => setLocal(() => tempHourly = v),
                      ),
                      Container(width: 1, color: _kBorder),
                      _RatePicker(
                        items: dailyItems,
                        initial: tempDaily,
                        suffix: '/day',
                        onChanged: (v) => setLocal(() => tempDaily = v),
                      ),
                      Container(width: 1, color: _kBorder),
                      _RatePicker(
                        items: monthlyItems,
                        initial: tempMonthly,
                        suffix: '/mo',
                        onChanged: (v) => setLocal(() => tempMonthly = v),
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

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      body: Stack(
        children: [
          // Ambient blob
          Positioned(
            top: -60.h,
            right: -40.w,
            child: Container(
              height: 240.w,
              width: 240.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _kAccent.withValues(alpha: 0.07),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top bar ─────────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                  child: Row(
                    children: [
                      _IconBtn(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: _goBack,
                      ),
                      const Spacer(),
                      // Pro badge
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: _kAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.badge_rounded,
                                size: 14.w, color: _kAccent),
                            SizedBox(width: 5.w),
                            Text('Pro Caregiver',
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: _kAccent,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // ── Progress indicator ───────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _StepProgressBar(
                    currentStep: _currentStep,
                    totalSteps: 4,
                  ),
                ),

                SizedBox(height: 4.h),

                // Step label
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step ${_currentStep + 1} of 4',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: _kMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _stepTitle(_currentStep),
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: _kAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 8.h),

                // ── Step pages ───────────────────────────────────────────────
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) =>
                        setState(() => _currentStep = i),
                    children: [
                      _Step1AboutYou(
                        bioController: _bioController,
                        yearsOfExperience: _yearsOfExperience,
                        onYearsChanged: (v) =>
                            setState(() => _yearsOfExperience = v),
                        availability: _availability,
                        onAvailabilityChanged: (v) =>
                            setState(() => _availability = v),
                        onNext: _goNext,
                      ),
                      _Step2SkillsLanguages(
                        specializations: _specializations,
                        onSpecToggle: (s) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (_specializations.contains(s)) {
                              _specializations.remove(s);
                            } else {
                              _specializations.add(s);
                            }
                          });
                        },
                        languages: _languages,
                        langController: _langController,
                        onAddLanguage: () {
                          final lang = _langController.text.trim();
                          if (lang.isNotEmpty &&
                              !_languages.contains(lang)) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _languages.add(lang);
                              _langController.clear();
                            });
                          }
                        },
                        onRemoveLanguage: (l) {
                          if (l != 'English') {
                            setState(() => _languages.remove(l));
                          }
                        },
                        onNext: _goNext,
                      ),
                      _Step3Credentials(
                        qualifications: _qualifications,
                        onQualToggle: (q) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (_qualifications.contains(q)) {
                              _qualifications.remove(q);
                            } else {
                              _qualifications.add(q);
                            }
                          });
                        },
                        workHistory: _workHistory,
                        onAddWorkHistory: (item) =>
                            setState(() => _workHistory.add(item)),
                        onRemoveWorkHistory: (i) =>
                            setState(() => _workHistory.removeAt(i)),
                        licenseController: _licenseController,
                        bgCheckAcknowledged: _bgCheckAcknowledged,
                        onBgCheckToggle: (v) =>
                            setState(() => _bgCheckAcknowledged = v),
                        onNext: _goNext,
                      ),
                      _Step4Rates(
                        hourlyRate: _hourlyRate,
                        dailyRate: _dailyRate,
                        monthlyRate: _monthlyRate,
                        isAvailableForHire: _isAvailableForHire,
                        onAvailableToggle: (v) =>
                            setState(() => _isAvailableForHire = v),
                        onPickRates: _pickRates,
                        onSave: _goNext,
                        saving: _saving,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _stepTitle(int step) => switch (step) {
        0 => 'Professional Profile',
        1 => 'Skills & Languages',
        2 => 'Credentials',
        _ => 'Service Rates',
      };
}

// ─── Progress Bar ─────────────────────────────────────────────────────────────

class _StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _StepProgressBar(
      {required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (i) {
        final active = i <= currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < totalSteps - 1 ? 6.w : 0),
            height: 4.h,
            decoration: BoxDecoration(
              color: active ? _kAccent : _kBorder,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Step 1 — About You ───────────────────────────────────────────────────────

class _Step1AboutYou extends StatelessWidget {
  final TextEditingController bioController;
  final int yearsOfExperience;
  final ValueChanged<int> onYearsChanged;
  final AvailabilityPreference availability;
  final ValueChanged<AvailabilityPreference> onAvailabilityChanged;
  final VoidCallback onNext;

  const _Step1AboutYou({
    required this.bioController,
    required this.yearsOfExperience,
    required this.onYearsChanged,
    required this.availability,
    required this.onAvailabilityChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
      children: [
        _StepHeader(
          title: 'Your Professional\nProfile',
          subtitle: 'Tell patients about yourself and your work style.',
        ),
        SizedBox(height: 24.h),

        // Bio
        _SectionLabel('About You'),
        SizedBox(height: 8.h),
        _OnboardingTextField(
          controller: bioController,
          hint:
              'e.g. Certified nurse with 5+ years in elderly care, specialising in dementia support and post-surgery recovery...',
          maxLines: 4,
          maxLength: 300,
        ),
        SizedBox(height: 20.h),

        // Years of experience
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionLabel('Years of Experience'),
            _StepperRow(
              value: yearsOfExperience,
              min: 0,
              max: 50,
              onChanged: onYearsChanged,
              label: yearsOfExperience == 1
                  ? '1 year'
                  : '$yearsOfExperience years',
            ),
          ],
        ),
        SizedBox(height: 20.h),

        // Availability
        _SectionLabel('Availability Preference'),
        SizedBox(height: 10.h),
        ...AvailabilityPreference.values.map((pref) {
          final selected = pref == availability;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onAvailabilityChanged(pref);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.symmetric(
                  horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: selected
                    ? _kAccent.withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: selected ? _kAccent : _kBorder,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18.w,
                    color: selected ? _kAccent : _kMuted,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    pref.label,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: selected ? _kText : _kSubtext,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        SizedBox(height: 32.h),

        _NextButton(label: 'Next  →', onTap: onNext),
      ],
    );
  }
}

// ─── Step 2 — Skills & Languages ─────────────────────────────────────────────

class _Step2SkillsLanguages extends StatelessWidget {
  final List<String> specializations;
  final ValueChanged<String> onSpecToggle;
  final List<String> languages;
  final TextEditingController langController;
  final VoidCallback onAddLanguage;
  final ValueChanged<String> onRemoveLanguage;
  final VoidCallback onNext;

  const _Step2SkillsLanguages({
    required this.specializations,
    required this.onSpecToggle,
    required this.languages,
    required this.langController,
    required this.onAddLanguage,
    required this.onRemoveLanguage,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
      children: [
        _StepHeader(
          title: 'Skills &\nLanguages',
          subtitle: 'Select your care specialisations and languages spoken.',
        ),
        SizedBox(height: 24.h),

        // Specializations
        _SectionLabel('Specializations'),
        SizedBox(height: 4.h),
        Text(
          'Select all that apply',
          style: GoogleFonts.inter(fontSize: 12.sp, color: _kMuted),
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _allSpecializations.map((s) {
            final sel = specializations.contains(s);
            return GestureDetector(
              onTap: () => onSpecToggle(s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                    horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: sel ? _kTeal : Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: sel ? _kTeal : _kBorder,
                  ),
                ),
                child: Text(
                  s,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : _kSubtext,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 24.h),

        // Languages
        _SectionLabel('Languages Spoken'),
        SizedBox(height: 10.h),
        // Language chips
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: languages.map((l) {
            final isEnglish = l == 'English';
            return Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: _kAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                    color: _kAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: _kAccent,
                      )),
                  if (!isEnglish) ...[
                    SizedBox(width: 6.w),
                    GestureDetector(
                      onTap: () => onRemoveLanguage(l),
                      child: Icon(Icons.close_rounded,
                          size: 13.w, color: _kAccent),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 10.h),
        // Add language input
        Row(
          children: [
            Expanded(
              child: _OnboardingTextField(
                controller: langController,
                hint: 'Add a language (e.g. Arabic)',
                maxLines: 1,
                onSubmitted: (_) => onAddLanguage(),
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: onAddLanguage,
              child: Container(
                height: 48.h,
                width: 48.h,
                decoration: BoxDecoration(
                  color: _kAccent,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.add_rounded,
                    size: 22.w, color: Colors.white),
              ),
            ),
          ],
        ),
        SizedBox(height: 32.h),

        _NextButton(label: 'Next  →', onTap: onNext),
      ],
    );
  }
}

// ─── Step 3 — Credentials & Work History ─────────────────────────────────────

class _Step3Credentials extends StatelessWidget {
  final List<String> qualifications;
  final ValueChanged<String> onQualToggle;
  final List<WorkHistoryItem> workHistory;
  final ValueChanged<WorkHistoryItem> onAddWorkHistory;
  final ValueChanged<int> onRemoveWorkHistory;
  final TextEditingController licenseController;
  final bool bgCheckAcknowledged;
  final ValueChanged<bool> onBgCheckToggle;
  final VoidCallback onNext;

  const _Step3Credentials({
    required this.qualifications,
    required this.onQualToggle,
    required this.workHistory,
    required this.onAddWorkHistory,
    required this.onRemoveWorkHistory,
    required this.licenseController,
    required this.bgCheckAcknowledged,
    required this.onBgCheckToggle,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
      children: [
        _StepHeader(
          title: 'Credentials &\nWork History',
          subtitle: 'Your qualifications help patients make informed decisions.',
        ),
        SizedBox(height: 24.h),

        // Qualifications
        _SectionLabel('Professional Qualifications'),
        SizedBox(height: 4.h),
        Text('Select all certifications you hold',
            style: GoogleFonts.inter(fontSize: 12.sp, color: _kMuted)),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _allQualifications.map((q) {
            final sel = qualifications.contains(q);
            return GestureDetector(
              onTap: () => onQualToggle(q),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                    horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: sel
                      ? _kAccent.withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: sel ? _kAccent : _kBorder,
                    width: sel ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (sel)
                      Padding(
                        padding: EdgeInsets.only(right: 5.w),
                        child: Icon(Icons.check_circle_rounded,
                            size: 13.w, color: _kAccent),
                      ),
                    Text(
                      q,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: sel ? _kAccent : _kSubtext,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 24.h),

        // Work History
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionLabel('Work History'),
            if (workHistory.length < 4)
              GestureDetector(
                onTap: () =>
                    _showAddWorkHistorySheet(context, onAddWorkHistory),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: _kTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 13.w, color: _kTeal),
                      SizedBox(width: 4.w),
                      Text('Add',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: _kTeal,
                          )),
                    ],
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 10.h),
        if (workHistory.isEmpty)
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                  color: _kBorder,
                  style: BorderStyle.solid),
            ),
            child: Row(
              children: [
                Icon(Icons.work_history_rounded, size: 20.w, color: _kMuted),
                SizedBox(width: 10.w),
                Text('No work history added yet',
                    style: GoogleFonts.inter(
                        fontSize: 13.sp, color: _kMuted)),
              ],
            ),
          )
        else
          ...workHistory.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: _kBorder),
              ),
              child: Row(
                children: [
                  Container(
                    height: 40.w,
                    width: 40.w,
                    decoration: BoxDecoration(
                      color: _kTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.local_hospital_rounded,
                        size: 18.w, color: _kTeal),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.organization,
                            style: GoogleFonts.poppins(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: _kText)),
                        Text(
                          '${item.role}  ·  ${item.yearsWorked} yr${item.yearsWorked == 1 ? '' : 's'}',
                          style: GoogleFonts.inter(
                              fontSize: 11.sp, color: _kSubtext),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onRemoveWorkHistory(i),
                    child: Icon(Icons.close_rounded,
                        size: 18.w, color: _kMuted),
                  ),
                ],
              ),
            );
          }),
        SizedBox(height: 20.h),

        // License number
        _SectionLabel('License / Registration No. (Optional)'),
        SizedBox(height: 8.h),
        _OnboardingTextField(
          controller: licenseController,
          hint: 'e.g. RN-123456',
          maxLines: 1,
        ),
        SizedBox(height: 20.h),

        // Background check
        _SectionLabel('Background Check Declaration'),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onBgCheckToggle(!bgCheckAcknowledged);
          },
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: bgCheckAcknowledged
                  ? const Color(0xFF16A34A).withValues(alpha: 0.06)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: bgCheckAcknowledged
                    ? const Color(0xFF16A34A).withValues(alpha: 0.4)
                    : _kBorder,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  bgCheckAcknowledged
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 20.w,
                  color: bgCheckAcknowledged
                      ? const Color(0xFF16A34A)
                      : _kMuted,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'I confirm that I am willing to undergo a background check and police clearance if required by a patient or manager. I declare that all information provided is accurate.',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: bgCheckAcknowledged ? _kText : _kSubtext,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 32.h),

        _NextButton(label: 'Next  →', onTap: onNext),
      ],
    );
  }

  void _showAddWorkHistorySheet(
      BuildContext context, ValueChanged<WorkHistoryItem> onAdd) {
    final orgCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    int years = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(
            20.w,
            20.h,
            20.w,
            MediaQuery.of(ctx).viewInsets.bottom + 24.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40.w,
                  decoration: BoxDecoration(
                      color: _kBorder,
                      borderRadius: BorderRadius.circular(2.r)),
                ),
              ),
              SizedBox(height: 16.h),
              Text('Add Work History',
                  style: GoogleFonts.poppins(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      color: _kText)),
              SizedBox(height: 16.h),
              Text('Organisation / Hospital',
                  style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: _kText)),
              SizedBox(height: 6.h),
              _OnboardingTextField(
                  controller: orgCtrl,
                  hint: 'e.g. City General Hospital',
                  maxLines: 1),
              SizedBox(height: 12.h),
              Text('Role / Position',
                  style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: _kText)),
              SizedBox(height: 6.h),
              _OnboardingTextField(
                  controller: roleCtrl,
                  hint: 'e.g. Senior Caregiver',
                  maxLines: 1),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Years Worked',
                      style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: _kText)),
                  _StepperRow(
                    value: years,
                    min: 1,
                    max: 40,
                    onChanged: (v) => setLocal(() => years = v),
                    label: '$years yr${years == 1 ? '' : 's'}',
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              GestureDetector(
                onTap: () {
                  if (orgCtrl.text.trim().isEmpty ||
                      roleCtrl.text.trim().isEmpty) {
                    return;
                  }
                  HapticFeedback.mediumImpact();
                  onAdd(WorkHistoryItem(
                    organization: orgCtrl.text.trim(),
                    role: roleCtrl.text.trim(),
                    yearsWorked: years,
                  ));
                  Navigator.pop(context);
                },
                child: Container(
                  height: 52.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_kTeal, _kAccent]),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Center(
                    child: Text('Add',
                        style: GoogleFonts.inter(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        )),
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

// ─── Step 4 — Service Rates ───────────────────────────────────────────────────

class _Step4Rates extends StatelessWidget {
  final double hourlyRate;
  final double dailyRate;
  final double monthlyRate;
  final bool isAvailableForHire;
  final ValueChanged<bool> onAvailableToggle;
  final VoidCallback onPickRates;
  final VoidCallback onSave;
  final bool saving;

  const _Step4Rates({
    required this.hourlyRate,
    required this.dailyRate,
    required this.monthlyRate,
    required this.isAvailableForHire,
    required this.onAvailableToggle,
    required this.onPickRates,
    required this.onSave,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
      children: [
        _StepHeader(
          title: 'Service Rates &\nAvailability',
          subtitle:
              'Set your rates so patients know what to expect. You can change these later.',
        ),
        SizedBox(height: 24.h),

        // Rates card
        _SectionLabel('Your Rates'),
        SizedBox(height: 10.h),
        GestureDetector(
          onTap: onPickRates,
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(color: _kBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _RateRow(
                  icon: Icons.schedule_rounded,
                  label: 'Hourly Rate',
                  value: '\$${hourlyRate.toStringAsFixed(0)}/hr',
                  color: _kAccent,
                ),
                Divider(height: 20.h, color: _kBorder),
                _RateRow(
                  icon: Icons.wb_sunny_rounded,
                  label: 'Full-Day Rate',
                  value: '\$${dailyRate.toStringAsFixed(0)}/day',
                  color: const Color(0xFFF59E0B),
                ),
                Divider(height: 20.h, color: _kBorder),
                _RateRow(
                  icon: Icons.calendar_month_rounded,
                  label: 'Monthly Rate',
                  value: '\$${monthlyRate.toStringAsFixed(0)}/mo',
                  color: _kTeal,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Center(
          child: Text(
            'Tap the card above to adjust rates',
            style: GoogleFonts.inter(fontSize: 11.sp, color: _kMuted),
          ),
        ),
        SizedBox(height: 24.h),

        // Available for hire
        _SectionLabel('Availability Status'),
        SizedBox(height: 10.h),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onAvailableToggle(!isAvailableForHire);
          },
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isAvailableForHire
                  ? const Color(0xFF16A34A).withValues(alpha: 0.06)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isAvailableForHire
                    ? const Color(0xFF16A34A).withValues(alpha: 0.35)
                    : _kBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isAvailableForHire
                      ? Icons.check_circle_rounded
                      : Icons.pause_circle_outline_rounded,
                  size: 22.w,
                  color: isAvailableForHire
                      ? const Color(0xFF16A34A)
                      : _kMuted,
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAvailableForHire
                            ? 'Open to New Patients'
                            : 'Not Available for Hire',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: isAvailableForHire
                              ? const Color(0xFF16A34A)
                              : _kSubtext,
                        ),
                      ),
                      Text(
                        isAvailableForHire
                            ? 'Your profile will appear in Discovery Hub'
                            : 'Your profile will be hidden from search',
                        style: GoogleFonts.inter(
                            fontSize: 11.sp, color: _kMuted),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: isAvailableForHire,
                  onChanged: onAvailableToggle,
                  activeTrackColor: const Color(0xFF16A34A),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),

        // Reminder info
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: _kAccent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 16.w, color: _kAccent),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Once your profile is live, patients and managers in the Discovery Hub can view your credentials, rates, and specialisations.',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: _kAccent,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 32.h),

        _NextButton(
          label: saving ? '' : 'Complete Setup  →',
          onTap: saving ? null : onSave,
          loading: saving,
        ),
      ],
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _StepHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 24.sp,
            fontWeight: FontWeight.w800,
            color: _kText,
            height: 1.2,
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(
            begin: 0.08, end: 0, duration: 300.ms),
        SizedBox(height: 6.h),
        Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 13.sp, color: _kMuted),
        ).animate().fadeIn(duration: 300.ms, delay: 60.ms),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: _kText,
      ),
    );
  }
}

class _OnboardingTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onSubmitted;

  const _OnboardingTextField({
    required this.controller,
    required this.hint,
    required this.maxLines,
    this.maxLength,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _kBorder),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        textInputAction: maxLines == 1
            ? TextInputAction.done
            : TextInputAction.newline,
        onSubmitted: onSubmitted,
        style: GoogleFonts.inter(fontSize: 14.sp, color: _kText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(fontSize: 13.sp, color: _kMuted),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(14.w),
          counterStyle:
              GoogleFonts.inter(fontSize: 11.sp, color: const Color(0xFFCBD5E1)),
        ),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String label;

  const _StepperRow({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconBtn(
          icon: Icons.remove_rounded,
          onTap: () {
            if (value > min) {
              HapticFeedback.selectionClick();
              onChanged(value - 1);
            }
          },
          size: 32,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: GoogleFonts.poppins(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: _kText,
            ),
          ),
        ),
        _IconBtn(
          icon: Icons.add_rounded,
          onTap: () {
            if (value < max) {
              HapticFeedback.selectionClick();
              onChanged(value + 1);
            }
          },
          size: 32,
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: size.w,
        width: size.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: _kBorder),
        ),
        child: Icon(icon, size: (size * 0.45).w, color: _kText),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const _NextButton({
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56.h,
        decoration: BoxDecoration(
          gradient: onTap != null
              ? const LinearGradient(
                  colors: [_kTeal, _kAccent])
              : null,
          color: onTap == null ? _kBorder : null,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: _kTeal.withValues(alpha: 0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _RateRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 38.w,
          width: 38.w,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, size: 18.w, color: color),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: _kSubtext)),
        ),
        Text(value,
            style: GoogleFonts.poppins(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: _kText,
            )),
        SizedBox(width: 6.w),
        Icon(Icons.edit_rounded, size: 14.w, color: _kMuted),
      ],
    );
  }
}

// ─── Rate Picker Column ───────────────────────────────────────────────────────

class _RatePicker extends StatelessWidget {
  final List<double> items;
  final double initial;
  final String suffix;
  final ValueChanged<double> onChanged;

  const _RatePicker({
    required this.items,
    required this.initial,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CupertinoPicker(
        itemExtent: 44,
        scrollController: FixedExtentScrollController(
          initialItem:
              items.indexWhere((v) => v == initial).clamp(0, items.length - 1),
        ),
        onSelectedItemChanged: (i) {
          HapticFeedback.selectionClick();
          SystemSound.play(SystemSoundType.click);
          onChanged(items[i]);
        },
        children: items
            .map((v) => Center(
                  child: Text(
                    '\$${v.toStringAsFixed(0)}$suffix',
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: _kText,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
