import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/snackbar_service.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../data/models/medication_model.dart';
import '../providers/medication_provider.dart';

class AddMedicationScreen extends ConsumerStatefulWidget {
  final String patientId;

  const AddMedicationScreen({super.key, required this.patientId});

  @override
  ConsumerState<AddMedicationScreen> createState() =>
      _AddMedicationScreenState();
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  final List<TimeOfDay> _reminderTimes = [];
  MealTiming _mealTiming = MealTiming.noRestriction;
  bool _isLoading = false;

  // ── All 4 options shown as a segmented selector ────────────────────────────
  static const _mealOptions = MealTiming.values;

  Future<void> _pickTime() async {
    TimeOfDay selected = TimeOfDay.now();

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
              // Handle + toolbar
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 16.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text('Cancel',
                          style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              color: AppColors.primary)),
                    ),
                    Text('Select Time',
                        style: GoogleFonts.poppins(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _reminderTimes.add(selected));
                        Navigator.pop(context);
                      },
                      child: Text('Done',
                          style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime.now(),
                  onDateTimeChanged: (dt) {
                    HapticFeedback.selectionClick();
                    selected = TimeOfDay.fromDateTime(dt);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_reminderTimes.isEmpty) {
      SnackbarService.showInfo('Add at least one reminder time');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final times = _reminderTimes.map(_formatTime).toList();

      final med = await ref.read(medicationRepositoryProvider).addMedication(
            patientId: widget.patientId,
            name: _nameController.text.trim(),
            dosage: _dosageController.text.trim(),
            durationDays: int.parse(_durationController.text.trim()),
            reminderTimes: times,
            mealTiming: _mealTiming,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );

      NotificationService.scheduleMedicationReminders(
        medId: med.id!,
        medName: med.name,
        dosage: med.dosage,
        times: times,
      ).catchError((_) {});

      if (mounted) {
        SnackbarService.showSuccess(
            '${med.name} added · ${_mealTiming.label}');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarService.showError('Failed to add medication: $e');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFA),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          children: [
            // ── Header ──
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    height: 40.w,
                    width: 40.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 16.w, color: AppColors.textPrimary),
                  ),
                ),
                SizedBox(width: 14.w),
                Text(
                  'Add Medication',
                  style: GoogleFonts.poppins(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 28.h),

            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Name ──
                  CustomTextField(
                    controller: _nameController,
                    label: 'Medicine Name',
                    hint: 'e.g. Metformin',
                    textInputAction: TextInputAction.next,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  SizedBox(height: 16.h),

                  // ── Dosage + Duration ──
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _dosageController,
                          label: 'Dosage',
                          hint: 'e.g. 500mg',
                          textInputAction: TextInputAction.next,
                          autovalidateMode:
                              AutovalidateMode.onUserInteraction,
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: CustomTextField(
                          controller: _durationController,
                          label: 'Duration (days)',
                          hint: 'e.g. 30',
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          autovalidateMode:
                              AutovalidateMode.onUserInteraction,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // ── Meal Timing ──────────────────────────────────────────
                  _SectionLabel(label: 'Meal Timing'),
                  SizedBox(height: 10.h),
                  _MealTimingSelector(
                    selected: _mealTiming,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _mealTiming = v);
                    },
                    options: _mealOptions,
                  ),
                  SizedBox(height: 8.h),
                  // Context hint
                  _MealTimingHint(timing: _mealTiming),
                  SizedBox(height: 24.h),

                  // ── Reminder Times ────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionLabel(label: 'Reminder Times'),
                      GestureDetector(
                        onTap: _pickTime,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_alarm_rounded,
                                  size: 16.w,
                                  color: AppColors.primaryDark),
                              SizedBox(width: 4.w),
                              Text(
                                'Add Time',
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  if (_reminderTimes.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                            color: AppColors.divider
                                .withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.alarm_outlined,
                              size: 28.w, color: AppColors.textHint),
                          SizedBox(height: 6.h),
                          Text(
                            'No reminders yet',
                            style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: AppColors.textHint),
                          ),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children:
                          _reminderTimes.asMap().entries.map((e) {
                        final i = e.key;
                        final t = e.value;
                        return Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: AppColors.warning
                                .withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(12.r),
                            border: Border.all(
                                color: AppColors.warning
                                    .withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.alarm_rounded,
                                  size: 16.w,
                                  color: AppColors.warning),
                              SizedBox(width: 6.w),
                              Text(
                                _formatTime(t),
                                style: GoogleFonts.poppins(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              GestureDetector(
                                onTap: () => setState(() =>
                                    _reminderTimes.removeAt(i)),
                                child: Icon(Icons.close_rounded,
                                    size: 16.w,
                                    color: AppColors.textHint),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  SizedBox(height: 24.h),

                  // ── Notes (optional) ──────────────────────────────────────
                  _SectionLabel(label: 'Notes (optional)'),
                  SizedBox(height: 10.h),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: TextField(
                      controller: _notesController,
                      maxLines: 2,
                      maxLength: 200,
                      style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText:
                            'e.g. Take with a full glass of water…',
                        hintStyle: GoogleFonts.inter(
                            fontSize: 13.sp,
                            color: AppColors.textHint),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(14.w),
                        counterStyle: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: const Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
                  SizedBox(height: 36.h),

                  CustomButton(
                    text: 'Save Medication',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _handleSave,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Meal Timing Selector ─────────────────────────────────────────────────────

class _MealTimingSelector extends StatelessWidget {
  final MealTiming selected;
  final ValueChanged<MealTiming> onChanged;
  final List<MealTiming> options;

  const _MealTimingSelector({
    required this.selected,
    required this.onChanged,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: options.map((opt) {
        final isSelected = selected == opt;
        final color = switch (opt) {
          MealTiming.beforeMeal => const Color(0xFF0891B2),
          MealTiming.afterMeal => const Color(0xFF16A34A),
          MealTiming.withMeal => const Color(0xFFEA580C),
          MealTiming.noRestriction => const Color(0xFF64748B),
        };

        return GestureDetector(
          onTap: () => onChanged(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: EdgeInsets.symmetric(
                horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isSelected
                    ? color
                    : const Color(0xFFE2E8F0),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(opt.emoji,
                    style: TextStyle(fontSize: 14.sp)),
                SizedBox(width: 6.w),
                Text(
                  opt.label,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: isSelected
                        ? color
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Clinical context hint ────────────────────────────────────────────────────

class _MealTimingHint extends StatelessWidget {
  final MealTiming timing;
  const _MealTimingHint({required this.timing});

  @override
  Widget build(BuildContext context) {
    final (hint, color) = switch (timing) {
      MealTiming.beforeMeal => (
          'Take 30–60 min before eating to maximise absorption.',
          const Color(0xFF0891B2),
        ),
      MealTiming.afterMeal => (
          'Take immediately after meals to reduce stomach irritation.',
          const Color(0xFF16A34A),
        ),
      MealTiming.withMeal => (
          'Take during your meal — food aids dissolution or absorption.',
          const Color(0xFFEA580C),
        ),
      MealTiming.noRestriction => (
          'No meal restriction for this medication.',
          const Color(0xFF64748B),
        ),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 14.w, color: color),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              hint,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A),
      ),
    );
  }
}
