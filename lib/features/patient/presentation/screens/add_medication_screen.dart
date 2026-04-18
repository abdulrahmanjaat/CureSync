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

  /// When non-null, the screen runs in edit mode — fields are pre-filled and
  /// saving calls [updateMedication] instead of [addMedication].
  final MedicationModel? existing;

  const AddMedicationScreen({
    super.key,
    required this.patientId,
    this.existing,
  });

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

  late List<TimeOfDay> _reminderTimes;
  MealTiming _mealTiming = MealTiming.noRestriction;
  int _timesPerDay = 1;
  bool _isLoading = false;

  static const _mealOptions = MealTiming.values;

  /// Default reminder times indexed by slot position
  static const _defaultTimes = [
    TimeOfDay(hour: 8, minute: 0),
    TimeOfDay(hour: 14, minute: 0),
    TimeOfDay(hour: 20, minute: 0),
    TimeOfDay(hour: 22, minute: 0),
  ];

  bool get _isEditMode => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final med = widget.existing;
    if (med != null) {
      _nameController.text = med.name;
      _dosageController.text = med.dosage;
      _durationController.text = med.durationDays.toString();
      _notesController.text = med.notes ?? '';
      _mealTiming = med.mealTiming;
      _timesPerDay = med.reminderTimes.length.clamp(1, 4);
      _reminderTimes = med.reminderTimes.map((t) {
        final parts = t.split(':');
        return TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 8,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }).toList();
    } else {
      _timesPerDay = 1;
      _reminderTimes = [_defaultTimes[0]];
    }
  }

  void _onFrequencyChanged(int newCount) {
    HapticFeedback.selectionClick();
    setState(() {
      _timesPerDay = newCount;
      while (_reminderTimes.length < newCount) {
        _reminderTimes.add(_defaultTimes[_reminderTimes.length]);
      }
      if (_reminderTimes.length > newCount) {
        _reminderTimes = _reminderTimes.take(newCount).toList();
      }
    });
  }

  Future<void> _pickTimeAt(int index) async {
    TimeOfDay selected = _reminderTimes[index];

    await showCupertinoModalPopup(
      context: context,
      builder: (_) => Material(
        color: Colors.transparent,
        child: Container(
          height: 280.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text('Cancel',
                          style: GoogleFonts.inter(
                              fontSize: 16.sp, color: AppColors.primary)),
                    ),
                    Text('Reminder Time',
                        style: GoogleFonts.poppins(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _reminderTimes[index] = selected);
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
                  initialDateTime: DateTime(
                    2024,
                    1,
                    1,
                    _reminderTimes[index].hour,
                    _reminderTimes[index].minute,
                  ),
                  onDateTimeChanged: (dt) {
                    HapticFeedback.selectionClick();
                    SystemSound.play(SystemSoundType.click);
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

  String _displayTime(TimeOfDay t) {
    final h = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
    final ampm = t.hour < 12 ? 'AM' : 'PM';
    return '$h:${t.minute.toString().padLeft(2, '0')} $ampm';
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final durationDays = int.tryParse(_durationController.text.trim());
    if (durationDays == null || durationDays <= 0) {
      SnackbarService.showError('Duration must be a whole number of days');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final times = _reminderTimes.map(_formatTime).toList();
      final name = _nameController.text.trim();
      final dosage = _dosageController.text.trim();
      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();

      if (_isEditMode) {
        final old = widget.existing!;

        // 1. Cancel every alert (legacy at-time + early-warning + stable
        //    overdue + SOS) for the OLD reminder times before overwriting.
        await NotificationService.cancelMedicationReminders(
          medId:        old.id!,
          timeCount:    old.reminderTimes.length,
          reminderTimes: old.reminderTimes,
        );

        // 2. Persist the updated medication to Firestore.
        await ref.read(medicationRepositoryProvider).updateMedication(
              patientId:    widget.patientId,
              medId:        old.id!,
              name:         name,
              dosage:       dosage,
              durationDays: durationDays,
              reminderTimes: times,
              mealTiming:   _mealTiming,
              notes:        notes,
            );

        // 3. Schedule fresh 4-level alerts for each NEW reminder time.
        for (final t in times) {
          NotificationService.scheduleDoseAlerts(
            medId:        old.id!,
            medName:      name,
            dosage:       dosage,
            reminderTime: t,
          ).catchError((_) {});
        }

        if (mounted) {
          SnackbarService.showSuccess('$name updated');
          context.pop();
        }
      } else {
        // Add path: save to Firestore first to get the real document ID.
        final med = await ref.read(medicationRepositoryProvider).addMedication(
              patientId:    widget.patientId,
              name:         name,
              dosage:       dosage,
              durationDays: durationDays,
              reminderTimes: times,
              mealTiming:   _mealTiming,
              notes:        notes,
            );

        // Schedule full 4-level escalation (early-warning, at-time, overdue,
        // SOS) for every reminder time using stable hash IDs.
        for (final t in times) {
          NotificationService.scheduleDoseAlerts(
            medId:        med.id!,
            medName:      med.name,
            dosage:       med.dosage,
            reminderTime: t,
          ).catchError((_) {});
        }

        if (mounted) {
          SnackbarService.showSuccess('${med.name} added · ${_mealTiming.label}');
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarService.showError(
            '${_isEditMode ? 'Update' : 'Add'} failed: $e');
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
            // ── Header ───────────────────────────────────────────────────────
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
                  _isEditMode ? 'Edit Medication' : 'Add Medication',
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
                  // ── Medicine Name ─────────────────────────────────────────
                  CustomTextField(
                    controller: _nameController,
                    label: 'Medicine Name',
                    hint: 'e.g. Metformin',
                    textInputAction: TextInputAction.next,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  SizedBox(height: 16.h),

                  // ── Dosage + Duration ─────────────────────────────────────
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
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textInputAction: TextInputAction.done,
                          autovalidateMode:
                              AutovalidateMode.onUserInteraction,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // ── Frequency (times per day) ─────────────────────────────
                  _SectionLabel(label: 'How many times per day?'),
                  SizedBox(height: 10.h),
                  Row(
                    children: List.generate(4, (i) {
                      final count = i + 1;
                      final isSelected = _timesPerDay == count;
                      final label = count == 1
                          ? '1×'
                          : count == 2
                              ? '2×'
                              : count == 3
                                  ? '3×'
                                  : '4×';
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: i < 3 ? 8.w : 0),
                          child: GestureDetector(
                            onTap: () => _onFrequencyChanged(count),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 44.h,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.white,
                                borderRadius:
                                    BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : const Color(0xFFE2E8F0),
                                  width: isSelected ? 1.5 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        )
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: Text(
                                  label,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    _timesPerDay == 1
                        ? 'Once daily'
                        : _timesPerDay == 2
                            ? 'Twice daily'
                            : '$_timesPerDay times daily',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: AppColors.textHint,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // ── Reminder Times ────────────────────────────────────────
                  _SectionLabel(label: 'Reminder Times'),
                  SizedBox(height: 4.h),
                  Text(
                    'Tap a time to change it',
                    style: GoogleFonts.inter(
                        fontSize: 11.sp, color: AppColors.textHint),
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 10.w,
                    runSpacing: 10.h,
                    children: List.generate(_timesPerDay, (i) {
                      final t = _reminderTimes[i];
                      return GestureDetector(
                        onTap: () => _pickTimeAt(i),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color: AppColors.warning
                                .withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(14.r),
                            border: Border.all(
                                color: AppColors.warning
                                    .withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.alarm_rounded,
                                  size: 16.w,
                                  color: AppColors.warning),
                              SizedBox(width: 6.w),
                              Text(
                                _displayTime(t),
                                style: GoogleFonts.poppins(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(Icons.edit_rounded,
                                  size: 12.w,
                                  color: AppColors.textHint),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 24.h),

                  // ── Meal Timing ───────────────────────────────────────────
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
                  _MealTimingHint(timing: _mealTiming),
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
                    text: _isEditMode
                        ? 'Save Changes'
                        : 'Save Medication',
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
            padding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isSelected ? color : const Color(0xFFE2E8F0),
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
                Text(opt.emoji, style: TextStyle(fontSize: 14.sp)),
                SizedBox(width: 6.w),
                Text(
                  opt.label,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? color : const Color(0xFF64748B),
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

// ─── Meal Timing Hint ─────────────────────────────────────────────────────────

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
          Icon(Icons.info_outline_rounded, size: 14.w, color: color),
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

// ─── Section Label ────────────────────────────────────────────────────────────

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
