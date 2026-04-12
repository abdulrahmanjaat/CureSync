import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/snackbar_service.dart';
import '../providers/patient_provider.dart';
import '../providers/medication_provider.dart';
import '../../data/models/medication_model.dart';
class PatientDetailsScreen extends ConsumerWidget {
  final String patientId;
  final bool readOnly;

  const PatientDetailsScreen({
    super.key,
    required this.patientId,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(patientsStreamProvider);
    final medsAsync = ref.watch(medicationsStreamProvider(patientId));

    // Find patient from stream
    final patient = patientsAsync.valueOrNull
        ?.where((p) => p.patientId == patientId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFDFC),
      body: SafeArea(
        child: patient == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding:
                    EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                children: [
                  /// ═══ BACK + NAME ═══
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.name,
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${patient.relation} · ${patient.age} years',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!readOnly)
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: patient.accessCode));
                            SnackbarService.showSuccess('Code copied');
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              patient.accessCode,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  /// ═══ HEALTH SUMMARY ═══
                  Text(
                    'Health Summary',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _VitalsGrid(),
                  SizedBox(height: 28.h),

                  /// ═══ MEDICATIONS ═══
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Medications',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (!readOnly)
                        GestureDetector(
                          onTap: () =>
                              context.push('/patient/$patientId/add-med'),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(100.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded,
                                    size: 16.w, color: Colors.white),
                                SizedBox(width: 4.w),
                                Text(
                                  'Add Med',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  medsAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary, strokeWidth: 2)),
                    error: (_, _) => Text('Error loading medications',
                        style: TextStyle(
                            fontSize: 13.sp, color: AppColors.textHint)),
                    data: (meds) {
                      final active =
                          meds.where((m) => m.isActive).toList();
                      if (active.isEmpty) {
                        return _EmptyMeds(
                          onAdd: () => context
                              .push('/patient/$patientId/add-med'),
                        );
                      }
                      return Column(
                        children: active
                            .map((m) => Padding(
                                  padding: EdgeInsets.only(bottom: 10.h),
                                  child: _DetailMedCard(med: m),
                                ))
                            .toList(),
                      );
                    },
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
      ),
    );
  }
}

class _VitalsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _VitalMini(
                icon: Icons.monitor_heart_outlined,
                label: 'Heart',
                value: '--',
                color: AppColors.accent)),
        SizedBox(width: 10.w),
        Expanded(
            child: _VitalMini(
                icon: Icons.bloodtype_outlined,
                label: 'BP',
                value: '--/--',
                color: AppColors.info)),
        SizedBox(width: 10.w),
        Expanded(
            child: _VitalMini(
                icon: Icons.air_rounded,
                label: 'SpO₂',
                value: '--%',
                color: AppColors.primary)),
        SizedBox(width: 10.w),
        Expanded(
            child: _VitalMini(
                icon: Icons.thermostat_outlined,
                label: 'Temp',
                value: '--°',
                color: AppColors.warning)),
      ],
    );
  }
}

class _VitalMini extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _VitalMini({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border:
            Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20.w, color: color),
          SizedBox(height: 6.h),
          Text(value,
              style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textHint)),
          Text(label,
              style: TextStyle(
                  fontSize: 10.sp, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _DetailMedCard extends StatelessWidget {
  final MedicationModel med;

  const _DetailMedCard({required this.med});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
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
          Row(
            children: [
              Container(
                height: 40.w,
                width: 40.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.medication_rounded,
                    size: 20.w, color: AppColors.primary),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(med.name,
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text('${med.dosage} · ${med.frequencyLabel}',
                        style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Text('${med.durationDays} days',
                  style: TextStyle(
                      fontSize: 12.sp, color: AppColors.textHint)),
            ],
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 6.w,
            children: med.reminderTimes
                .map((t) => Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.alarm_rounded,
                              size: 12.w, color: AppColors.warning),
                          SizedBox(width: 4.w),
                          Text(t,
                              style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _EmptyMeds extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyMeds({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 28.h),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Icon(Icons.medication_outlined,
                size: 36.w, color: AppColors.textHint),
            SizedBox(height: 10.h),
            Text('Add First Medication',
                style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
            SizedBox(height: 4.h),
            Text('Set up reminders and dosage schedules',
                style: TextStyle(
                    fontSize: 12.sp, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
