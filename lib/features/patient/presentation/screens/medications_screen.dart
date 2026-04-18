import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/snackbar_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/role_provider.dart';
import '../providers/patient_provider.dart';
import '../providers/medication_provider.dart';
import '../../data/models/medication_model.dart';
import '../../data/models/dose_log_model.dart';

class MedicationsScreen extends ConsumerWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(currentUserDataProvider).valueOrNull;
    final role = UserRoleX.fromString(userData?.role);
    final isPatient = role == UserRole.patient;

    if (isPatient) ref.watch(selfPatientInitProvider);

    final selfId = ref.watch(selfPatientIdProvider);
    final patientsAsync = ref.watch(patientsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFDFC),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          children: [
            Text(
              'Medications',
              style: GoogleFonts.poppins(
                fontSize: 26.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              isPatient
                  ? 'Your active medication schedule'
                  : 'All medication schedules across patients',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 24.h),

            if (isPatient) ...[
              if (selfId != null)
                _PatientMedsSection(
                  patientId: selfId,
                  patientName: 'My Medications',
                )
              else
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
            ] else ...[
              patientsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (_, _) => Text('Failed to load',
                    style: GoogleFonts.inter(
                        fontSize: 14.sp, color: AppColors.textHint)),
                data: (patients) {
                  if (patients.isEmpty) return const _EmptyMeds();
                  return Column(
                    children: patients
                        .map((p) => _PatientMedsSection(
                              patientId: p.patientId!,
                              patientName: p.name,
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Patient Section ──────────────────────────────────────────────────────────

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
    final todayLogs =
        ref.watch(todayDoseLogsProvider(patientId)).valueOrNull ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ─────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              patientName,
              style: GoogleFonts.poppins(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/patient/$patientId/add-med');
              },
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 16.w, color: Colors.white),
                    SizedBox(width: 4.w),
                    Text(
                      'Add',
                      style: GoogleFonts.inter(
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
        SizedBox(height: 14.h),

        // ── Medication list ────────────────────────────────────────────────
        medsAsync.when(
          loading: () => SizedBox(
            height: 80.h,
            child: const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            ),
          ),
          error: (_, _) => Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Text('Error loading medications',
                style: GoogleFonts.inter(
                    fontSize: 13.sp, color: AppColors.textHint)),
          ),
          data: (meds) {
            final active = meds.where((m) => m.isActive).toList();
            if (active.isEmpty) {
              return _NoMedsPlaceholder(
                patientId: patientId,
              );
            }
            return Column(
              children: active
                  .map((m) => _MedCard(
                        med: m,
                        todayLogs: todayLogs,
                        patientId: patientId,
                      ))
                  .toList(),
            );
          },
        ),

        SizedBox(height: 8.h),
      ],
    );
  }
}

// ─── Bento Medication Card ────────────────────────────────────────────────────

class _MedCard extends ConsumerWidget {
  final MedicationModel med;
  final List<DoseLogModel> todayLogs;
  final String patientId;

  const _MedCard({
    required this.med,
    required this.todayLogs,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final takenToday =
        todayLogs.where((l) => l.medId == med.id).length;
    final totalToday = med.reminderTimes.length;
    final progress =
        totalToday > 0 ? (takenToday / totalToday).clamp(0.0, 1.0) : 0.0;
    final allTaken = takenToday >= totalToday && totalToday > 0;

    final daysLeft = med.endDate.difference(DateTime.now()).inDays;
    final isExpired = med.isExpired;

    final mealColor = switch (med.mealTiming) {
      MealTiming.beforeMeal => const Color(0xFF0891B2),
      MealTiming.afterMeal => const Color(0xFF16A34A),
      MealTiming.withMeal => const Color(0xFFEA580C),
      MealTiming.noRestriction => const Color(0xFF64748B),
    };

    return GestureDetector(
      onTap: () => _showOptions(context, ref),
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: allTaken
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25), width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top: icon + name + menu ──────────────────────────────────
            Row(
              children: [
                Container(
                  height: 46.w,
                  width: 46.w,
                  decoration: BoxDecoration(
                    color: allTaken
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    Icons.medication_rounded,
                    size: 24.w,
                    color: allTaken
                        ? AppColors.primary
                        : const Color(0xFF64748B),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        '${med.dosage} · ${med.frequencyLabel}',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                // Options menu button
                GestureDetector(
                  onTap: () => _showOptions(context, ref),
                  child: Container(
                    height: 32.w,
                    width: 32.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.more_horiz_rounded,
                      size: 18.w,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 14.h),
            Divider(
                height: 1,
                color: const Color(0xFFF1F5F9)),
            SizedBox(height: 12.h),

            // ── Info chips: meal timing + days left ──────────────────────
            Row(
              children: [
                // Meal timing
                _InfoChip(
                  label: med.mealTiming.label,
                  prefix: med.mealTiming.emoji,
                  color: mealColor,
                ),
                SizedBox(width: 8.w),
                // Days left
                _InfoChip(
                  icon: Icons.calendar_today_rounded,
                  label: isExpired ? 'Expired' : '$daysLeft d left',
                  color: isExpired
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF0891B2),
                ),
                if (allTaken) ...[
                  SizedBox(width: 8.w),
                  _InfoChip(
                    icon: Icons.check_circle_rounded,
                    label: 'All done!',
                    color: AppColors.primary,
                  ),
                ],
              ],
            ),

            SizedBox(height: 14.h),

            // ── Today's progress ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's doses",
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  '$takenToday / $totalToday taken',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: allTaken
                        ? AppColors.primary
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7.h,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation(
                  allTaken
                      ? AppColors.primary
                      : const Color(0xFFF59E0B),
                ),
              ),
            ),

            // ── Reminder time chips ───────────────────────────────────────
            if (med.reminderTimes.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(Icons.alarm_rounded,
                      size: 12.w, color: const Color(0xFF94A3B8)),
                  SizedBox(width: 5.w),
                  Expanded(
                    child: Text(
                      med.reminderTimes.map(_fmtTime).join('  ·  '),
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: const Color(0xFF64748B),
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmtTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return hhmm;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final ampm = h < 12 ? 'AM' : 'PM';
    return '$hour:${m.toString().padLeft(2, '0')} $ampm';
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (sheetCtx) => _MedOptionsSheet(
        med: med,
        onEdit: () {
          Navigator.pop(sheetCtx);
          context.push('/patient/$patientId/add-med', extra: med);
        },
        onDelete: () {
          Navigator.pop(sheetCtx);
          _confirmDelete(context, ref);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'Delete ${med.name}?',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700, fontSize: 16.sp),
        ),
        content: Text(
          'This will permanently remove this medication and its tracking data.',
          style: GoogleFonts.inter(
              fontSize: 13.sp, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await ref
                  .read(medicationRepositoryProvider)
                  .deleteMedication(patientId, med.id!);
              SnackbarService.showSuccess('${med.name} deleted');
            },
            child: Text('Delete',
                style: GoogleFonts.inter(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── Info Chip ────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final String? prefix;
  final IconData? icon;
  final String label;
  final Color color;

  const _InfoChip({
    this.prefix,
    this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (prefix != null) ...[
            Text(prefix!, style: TextStyle(fontSize: 10.sp)),
            SizedBox(width: 4.w),
          ] else if (icon != null) ...[
            Icon(icon!, size: 11.w, color: color),
            SizedBox(width: 4.w),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Options Bottom Sheet ─────────────────────────────────────────────────────

class _MedOptionsSheet extends StatelessWidget {
  final MedicationModel med;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedOptionsSheet({
    required this.med,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 36.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
          SizedBox(height: 18.h),

          // Med info header
          Row(
            children: [
              Container(
                height: 44.w,
                width: 44.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14.r),
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
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${med.dosage} · ${med.frequencyLabel}',
                      style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 22.h),

          // Edit option
          _OptionTile(
            icon: Icons.edit_rounded,
            color: AppColors.primary,
            label: 'Edit Medication',
            onTap: onEdit,
          ),
          SizedBox(height: 10.h),

          // Delete option
          _OptionTile(
            icon: Icons.delete_outline_rounded,
            color: const Color(0xFFEF4444),
            label: 'Delete Medication',
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

// ─── Option Tile ──────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              height: 36.w,
              width: 36.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, size: 18.w, color: color),
            ),
            SizedBox(width: 14.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                size: 18.w, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ─── No Meds Placeholder ──────────────────────────────────────────────────────

class _NoMedsPlaceholder extends StatelessWidget {
  final String patientId;
  const _NoMedsPlaceholder({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.symmetric(vertical: 28.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
            color: const Color(0xFFE2E8F0).withValues(alpha: 0.8)),
      ),
      child: Column(
        children: [
          Container(
            height: 52.w,
            width: 52.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.medication_outlined,
                size: 26.w, color: AppColors.primary),
          ),
          SizedBox(height: 12.h),
          Text(
            'No active medications',
            style: GoogleFonts.poppins(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Tap Add to schedule your first medication.',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: const Color(0xFF94A3B8),
            ),
          ),
          SizedBox(height: 16.h),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/patient/$patientId/add-med');
            },
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '+ Add Medication',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State (no patients at all) ────────────────────────────────────────

class _EmptyMeds extends StatelessWidget {
  const _EmptyMeds();

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
            'No medications yet',
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Add a patient profile first to\nstart managing medications.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
