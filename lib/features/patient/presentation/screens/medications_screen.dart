import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/patient_provider.dart';
import '../providers/medication_provider.dart';
import '../../data/models/medication_model.dart';

class MedicationsScreen extends ConsumerWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(patientsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFDFC),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          children: [
            Text(
              'Medications',
              style: TextStyle(
                fontSize: 26.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'All medication schedules across patients',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 24.h),

            patientsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (_, _) => Text('Failed to load',
                  style: TextStyle(
                      fontSize: 14.sp, color: AppColors.textHint)),
              data: (patients) {
                if (patients.isEmpty) {
                  return _EmptyMeds();
                }
                return Column(
                  children: patients.map((p) {
                    return _PatientMedsSection(
                      patientId: p.patientId!,
                      patientName: p.name,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientMedsSection extends ConsumerWidget {
  final String patientId;
  final String patientName;

  const _PatientMedsSection({
    required this.patientId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(medicationsStreamProvider(patientId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              patientName,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/patient/$patientId/add-med'),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '+ Add',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),

        medsAsync.when(
          loading: () => SizedBox(
            height: 60.h,
            child: const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            ),
          ),
          error: (_, _) => Text('Error loading meds',
              style:
                  TextStyle(fontSize: 12.sp, color: AppColors.textHint)),
          data: (meds) {
            final active = meds.where((m) => m.isActive).toList();
            if (active.isEmpty) {
              return Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: Text(
                  'No active medications',
                  style: TextStyle(
                      fontSize: 13.sp, color: AppColors.textHint),
                ),
              );
            }
            return Column(
              children: active
                  .map((m) => Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: _MedCard(med: m),
                      ))
                  .toList(),
            );
          },
        ),
        SizedBox(height: 16.h),
      ],
    );
  }
}

class _MedCard extends StatelessWidget {
  final MedicationModel med;

  const _MedCard({required this.med});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            height: 42.w,
            width: 42.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.medication_rounded,
                size: 22.w, color: AppColors.primary),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${med.dosage} · ${med.frequencyLabel}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  med.reminderTimes.isNotEmpty
                      ? med.reminderTimes.first
                      : '--:--',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '${med.durationDays}d left',
                style: TextStyle(
                    fontSize: 10.sp, color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyMeds extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 40.h),
      child: Column(
        children: [
          Icon(Icons.medication_outlined,
              size: 48.w, color: AppColors.textHint),
          SizedBox(height: 14.h),
          Text(
            'No patients yet',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Add a patient profile first to\nmanage their medications.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
