import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/snackbar_service.dart';
import '../../data/models/caregiver_profile_model.dart';
import '../providers/caregiver_provider.dart';

class CaregiverWorkProfileScreen extends ConsumerStatefulWidget {
  const CaregiverWorkProfileScreen({super.key});

  @override
  ConsumerState<CaregiverWorkProfileScreen> createState() =>
      _CaregiverWorkProfileScreenState();
}

class _CaregiverWorkProfileScreenState
    extends ConsumerState<CaregiverWorkProfileScreen> {
  double _hourlyRate = 0;
  double _dailyRate = 0;
  int _workStart = 8;
  int _workEnd = 18;
  List<String> _specializations = [];
  List<CertificationItem> _certifications = [];
  bool _loading = false;
  bool _initialized = false;
  bool _isAvailableForHire = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final profile = ref.read(caregiverProfileProvider).valueOrNull;
      if (profile != null) _loadFromProfile(profile);
      _initialized = true;
    }
  }

  void _loadFromProfile(CaregiverProfileModel p) {
    _hourlyRate = p.hourlyRate;
    _dailyRate = p.dailyRate;
    _workStart = p.workHoursStart;
    _workEnd = p.workHoursEnd;
    _isAvailableForHire = p.isAvailableForHire;
    _specializations = List.from(p.specializations);
    _certifications = List.from(p.certifications);
  }

  // ─── Cupertino Rate Picker ────────────────────────────────────────────────

  Future<void> _pickRate({required bool isHourly}) async {
    double selected = isHourly ? _hourlyRate : _dailyRate;
    final items = List.generate(
        201, (i) => i * 5.0); // 0, 5, 10 … 1000

    await showCupertinoModalPopup(
      context: context,
      builder: (_) => Material(
        color: Colors.transparent,
        child: Container(
          height: 280.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 20.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text('Cancel',
                          style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              color: const Color(0xFF0D9488))),
                    ),
                    Text(
                      isHourly ? 'Hourly Rate' : 'Daily Rate',
                      style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A)),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          if (isHourly) {
                            _hourlyRate = selected;
                          } else {
                            _dailyRate = selected;
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: Text('Done',
                          style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0D9488))),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 44,
                  onSelectedItemChanged: (i) {
                    HapticFeedback.selectionClick();
                    selected = items[i];
                  },
                  scrollController: FixedExtentScrollController(
                    initialItem:
                        items.indexWhere((v) => v == selected).clamp(0, items.length - 1),
                  ),
                  children: items
                      .map((v) => Center(
                            child: Text(
                              '\$${v.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A)),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Cupertino Hour Picker ────────────────────────────────────────────────

  Future<void> _pickWorkHours() async {
    int start = _workStart;
    int end = _workEnd;

    await showCupertinoModalPopup(
      context: context,
      builder: (_) => Material(
        color: Colors.transparent,
        child: Container(
          height: 300.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: StatefulBuilder(
            builder: (_, setLocal) => Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 20.w, vertical: 12.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text('Cancel',
                            style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                color: const Color(0xFF0D9488))),
                      ),
                      Text('Work Hours',
                          style: GoogleFonts.poppins(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A))),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _workStart = start;
                            _workEnd = end;
                          });
                          Navigator.pop(context);
                        },
                        child: Text('Done',
                            style: GoogleFonts.inter(
                                fontSize: 16.sp,
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
                            Text('From',
                                style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    color: const Color(0xFF94A3B8))),
                            Expanded(
                              child: CupertinoPicker(
                                itemExtent: 44,
                                scrollController:
                                    FixedExtentScrollController(
                                        initialItem: start),
                                onSelectedItemChanged: (i) {
                                  HapticFeedback.selectionClick();
                                  setLocal(() => start = i);
                                },
                                children: List.generate(
                                  24,
                                  (h) => Center(
                                    child: Text(
                                      _formatHour(h),
                                      style: GoogleFonts.poppins(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              const Color(0xFF0F172A)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(':',
                          style: GoogleFonts.poppins(
                              fontSize: 22.sp,
                              color: const Color(0xFF94A3B8))),
                      Expanded(
                        child: Column(
                          children: [
                            Text('To',
                                style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    color: const Color(0xFF94A3B8))),
                            Expanded(
                              child: CupertinoPicker(
                                itemExtent: 44,
                                scrollController:
                                    FixedExtentScrollController(
                                        initialItem: end),
                                onSelectedItemChanged: (i) {
                                  HapticFeedback.selectionClick();
                                  setLocal(() => end = i);
                                },
                                children: List.generate(
                                  24,
                                  (h) => Center(
                                    child: Text(
                                      _formatHour(h),
                                      style: GoogleFonts.poppins(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              const Color(0xFF0F172A)),
                                    ),
                                  ),
                                ),
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

  String _formatHour(int h) {
    final ampm = h < 12 ? 'AM' : 'PM';
    final display = h == 0
        ? 12
        : h > 12
            ? h - 12
            : h;
    return '$display:00 $ampm';
  }

  // ─── Add Certification ────────────────────────────────────────────────────

  void _addCertification() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r)),
        title: Text('Add Certification',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A))),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. BLS, ACLS, RN License',
            hintStyle: GoogleFonts.inter(
                color: const Color(0xFF94A3B8)),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(
                  color: Color(0xFF0D9488), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8))),
          ),
          TextButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                setState(() => _certifications.add(
                    CertificationItem(name: name)));
              }
              Navigator.pop(context);
            },
            child: Text('Add',
                style: GoogleFonts.inter(
                    color: const Color(0xFF0D9488),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ─── Save ─────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    final displayName = ref.read(authStateProvider).valueOrNull?.displayName ?? '';
    if (uid == null) return;

    setState(() => _loading = true);
    try {
      final existing = ref.read(caregiverProfileProvider).valueOrNull;
      final profile = (existing ?? CaregiverProfileModel(
        uid: uid,
        name: displayName,
        createdAt: DateTime.now(),
      )).copyWith(
        name: displayName,
        hourlyRate: _hourlyRate,
        dailyRate: _dailyRate,
        specializations: _specializations,
        certifications: _certifications,
        workHoursStart: _workStart,
        workHoursEnd: _workEnd,
        isAvailableForHire: _isAvailableForHire,
      );
      await ref.read(caregiverRepositoryProvider).saveProfile(profile);
      SnackbarService.showSuccess('Work profile saved');
    } catch (e) {
      SnackbarService.showError('Failed to save: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sync profile on first load
    ref.listen(caregiverProfileProvider, (_, next) {
      if (!_initialized) {
        final p = next.valueOrNull;
        if (p != null) {
          setState(() => _loadFromProfile(p));
          _initialized = true;
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFA),
      body: SafeArea(
        child: ListView(
          padding:
              EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Text('Work Profile',
                style: GoogleFonts.poppins(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A))),
            Text('Set your rates, hours & credentials',
                style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: const Color(0xFF94A3B8))),
            SizedBox(height: 20.h),

            // ── Available for Hire toggle ─────────────────────────────────────
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: _isAvailableForHire
                    ? const Color(0xFF0D9488).withValues(alpha: 0.06)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: _isAvailableForHire
                      ? const Color(0xFF0D9488).withValues(alpha: 0.3)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    height: 40.w,
                    width: 40.w,
                    decoration: BoxDecoration(
                      color: _isAvailableForHire
                          ? const Color(0xFF0D9488)
                              .withValues(alpha: 0.12)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      _isAvailableForHire
                          ? Icons.work_rounded
                          : Icons.work_off_rounded,
                      size: 20.w,
                      color: _isAvailableForHire
                          ? const Color(0xFF0D9488)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available for Hire',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          _isAvailableForHire
                              ? 'Visible to patients in Discovery'
                              : 'Hidden from patient searches',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: _isAvailableForHire
                                ? const Color(0xFF0D9488)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _isAvailableForHire,
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFF0D9488),
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _isAvailableForHire = v);
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // ── Rates ────────────────────────────────────────────────────────
            _SectionLabel(
                icon: Icons.payments_rounded,
                label: 'Rates',
                color: const Color(0xFF0D9488)),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _RateTile(
                    label: 'Hourly Rate',
                    value: '\$${_hourlyRate.toStringAsFixed(0)}/hr',
                    onTap: () => _pickRate(isHourly: true),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _RateTile(
                    label: 'Daily Rate',
                    value: '\$${_dailyRate.toStringAsFixed(0)}/day',
                    onTap: () => _pickRate(isHourly: false),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // ── Work Hours ───────────────────────────────────────────────────
            _SectionLabel(
                icon: Icons.schedule_rounded,
                label: 'Work Hours',
                color: const Color(0xFF0891B2)),
            SizedBox(height: 12.h),
            GestureDetector(
              onTap: _pickWorkHours,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                      color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 22.w,
                        color: const Color(0xFF0891B2)),
                    SizedBox(width: 12.w),
                    Text(
                      '${_formatHour(_workStart)}  →  ${_formatHour(_workEnd)}',
                      style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A)),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded,
                        size: 20.w,
                        color: const Color(0xFFCBD5E1)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24.h),

            // ── Specializations ──────────────────────────────────────────────
            _SectionLabel(
                icon: Icons.local_hospital_rounded,
                label: 'Specializations',
                color: const Color(0xFF7C3AED)),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: _allSpecializations.map((spec) {
                final active = _specializations.contains(spec);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (active) {
                        _specializations.remove(spec);
                      } else {
                        _specializations.add(spec);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      spec,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? Colors.white
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 24.h),

            // ── Certifications ───────────────────────────────────────────────
            Row(
              children: [
                _SectionLabel(
                    icon: Icons.verified_rounded,
                    label: 'Certifications',
                    color: const Color(0xFF0D9488)),
                const Spacer(),
                GestureDetector(
                  onTap: _addCertification,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488)
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded,
                            size: 16.w,
                            color: const Color(0xFF0D9488)),
                        SizedBox(width: 4.w),
                        Text('Add',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0D9488),
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (_certifications.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Text(
                    'No certifications added yet',
                    style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: const Color(0xFF94A3B8)),
                  ),
                ),
              )
            else
              ..._certifications.asMap().entries.map((e) {
                final i = e.key;
                final cert = e.value;
                return Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                        color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        cert.isVerified
                            ? Icons.verified_rounded
                            : Icons.pending_rounded,
                        size: 20.w,
                        color: cert.isVerified
                            ? const Color(0xFF0D9488)
                            : const Color(0xFF94A3B8),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(cert.name,
                                style: GoogleFonts.inter(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0F172A))),
                            Text(
                              cert.isVerified
                                  ? 'Verified'
                                  : 'Pending verification',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: cert.isVerified
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(
                            () => _certifications.removeAt(i)),
                        child: Icon(Icons.close_rounded,
                            size: 18.w,
                            color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                );
              }),
            SizedBox(height: 36.h),

            // ── Save Button ──────────────────────────────────────────────────
            GestureDetector(
              onTap: _loading ? null : _save,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  color: _loading
                      ? const Color(0xFF0D9488).withValues(alpha: 0.5)
                      : const Color(0xFF0D9488),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488)
                          .withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: _loading
                      ? SizedBox(
                          height: 20.w,
                          width: 20.w,
                          child: const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Save Profile',
                          style: GoogleFonts.inter(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionLabel(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18.w, color: color),
        SizedBox(width: 8.w),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

// ─── Rate Tile ────────────────────────────────────────────────────────────────

class _RateTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _RateTile(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border:
              Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: const Color(0xFF94A3B8),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0D9488),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Tap to change',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: const Color(0xFFCBD5E1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
