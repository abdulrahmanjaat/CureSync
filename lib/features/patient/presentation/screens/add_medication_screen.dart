import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/snackbar_service.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
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
  final List<TimeOfDay> _reminderTimes = [];
  bool _isLoading = false;

  Future<void> _pickTime() async {
    TimeOfDay selected = TimeOfDay.now();

    await showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 280.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: TextStyle(
                            fontSize: 16.sp, color: AppColors.textSecondary)),
                  ),
                  Text('Select Time',
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _reminderTimes.add(selected));
                      Navigator.pop(context);
                    },
                    child: Text('Done',
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
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
          );

      // Schedule notifications
      await NotificationService.scheduleMedicationReminders(
        medId: med.id!,
        medName: med.name,
        dosage: med.dosage,
        times: times,
      );

      if (mounted) {
        SnackbarService.showSuccess(
            '${med.name} added with ${times.length} reminder(s)');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarService.showError('Failed to add medication');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFDFC),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          children: [
            /// Header
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    height: 40.w,
                    width: 40.w,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
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
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 28.h),

            /// Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: _nameController,
                    label: 'Medicine Name',
                    hint: 'e.g. Metformin',
                    textInputAction: TextInputAction.next,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  SizedBox(height: 16.h),

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

                  /// Reminder times
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reminder Times',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
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
                                style: TextStyle(
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
                        color: AppColors.scaffold,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                            color: AppColors.divider.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.alarm_outlined,
                              size: 28.w, color: AppColors.textHint),
                          SizedBox(height: 6.h),
                          Text(
                            'No reminders yet',
                            style: TextStyle(
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
                      children: _reminderTimes.asMap().entries.map((e) {
                        final i = e.key;
                        final t = e.value;
                        return Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: AppColors.warning
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                                color: AppColors.warning
                                    .withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.alarm_rounded,
                                  size: 16.w, color: AppColors.warning),
                              SizedBox(width: 6.w),
                              Text(
                                _formatTime(t),
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              GestureDetector(
                                onTap: () => setState(
                                    () => _reminderTimes.removeAt(i)),
                                child: Icon(Icons.close_rounded,
                                    size: 16.w,
                                    color: AppColors.textHint),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
