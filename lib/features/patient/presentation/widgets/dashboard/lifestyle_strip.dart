import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/medication_provider.dart';
import '../../providers/water_tracker_provider.dart';
import '../../providers/sleep_provider.dart';
import '../../providers/diet_provider.dart';
import '../../../../../features/patient/data/models/water_log_model.dart';
import '../../../../../features/patient/data/models/sleep_log_model.dart';
import '../../../../../features/patient/data/models/diet_log_model.dart';
import 'bento_card.dart';
import 'status_tag.dart';

class LifestyleStrip extends ConsumerWidget {
  /// Explicit patientId to use. When provided the widget is bound to that
  /// patient and ignores [resolvedActivePatientIdProvider] entirely.
  final String? patientId;

  const LifestyleStrip({super.key, this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientId = this.patientId ?? ref.watch(resolvedActivePatientIdProvider);

    final waterAsync = patientId != null
        ? ref.watch(todayWaterLogProvider(patientId))
        : const AsyncValue<WaterLogModel?>.data(null);
    final sleepAsync = patientId != null
        ? ref.watch(todaySleepLogProvider(patientId))
        : const AsyncValue<SleepLogModel?>.data(null);
    final dietAsync = patientId != null
        ? ref.watch(todayDietLogProvider(patientId))
        : const AsyncValue<DietLogModel?>.data(null);

    final water = waterAsync.valueOrNull;
    final sleep = sleepAsync.valueOrNull;
    final diet  = dietAsync.valueOrNull;

    return Row(
      children: [
        // ── Water Tile (live + interactive) ─────────────────────────────
        Expanded(
          child: _WaterTile(
            log: water,
            onAdd: patientId == null
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(waterTrackerRepositoryProvider)
                        .logGlass(patientId, currentGoal: water?.dailyGoal ?? 8);
                  },
            onRemove:
                patientId == null || (water?.glassesConsumed ?? 0) == 0
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        ref
                            .read(waterTrackerRepositoryProvider)
                            .removeGlass(patientId);
                      },
            onGoalTap: patientId == null
                ? null
                : () => _showGoalSheet(context, ref, patientId,
                    water?.dailyGoal ?? 8),
          ),
        ),
        SizedBox(width: 10.w),

        // ── Sleep Tile (live + interactive) ─────────────────────────────
        Expanded(
          child: _SleepTile(
            log: sleep,
            onTap: patientId == null
                ? null
                : () => _showSleepSheet(context, ref, patientId, sleep),
          ),
        ),
        SizedBox(width: 10.w),

        // ── Diet Tile (live + interactive) ──────────────────────────────
        Expanded(
          child: _DietTile(
            log: diet,
            onTap: patientId == null
                ? null
                : () => _showDietSheet(context, ref, patientId, diet),
          ),
        ),
      ],
    );
  }

  void _showGoalSheet(
      BuildContext context, WidgetRef ref, String patientId, int currentGoal) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _GoalSheet(
        currentGoal: currentGoal,
        onSave: (goal) =>
            ref.read(waterTrackerRepositoryProvider).updateGoal(patientId, goal),
      ),
    );
  }

  void _showSleepSheet(BuildContext context, WidgetRef ref, String patientId,
      SleepLogModel? existing) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SleepEntrySheet(
        existing: existing,
        onSave: (hours, minutes) => ref.read(sleepRepositoryProvider).logSleep(
              patientId: patientId,
              hours: hours,
              minutes: minutes,
            ),
      ),
    );
  }

  void _showDietSheet(BuildContext context, WidgetRef ref, String patientId,
      DietLogModel? existing) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DietEntrySheet(
        existing: existing,
        onSave: (calories, goal) => ref.read(dietRepositoryProvider).logDiet(
              patientId: patientId,
              calories: calories,
              calorieGoal: goal,
            ),
      ),
    );
  }
}

// ── Interactive Water Tile ─────────────────────────────────────────────────────

class _WaterTile extends StatelessWidget {
  final WaterLogModel? log;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  final VoidCallback? onGoalTap;

  const _WaterTile({
    required this.log,
    this.onAdd,
    this.onRemove,
    this.onGoalTap,
  });

  @override
  Widget build(BuildContext context) {
    final consumed = log?.glassesConsumed ?? 0;
    final goal = log?.dailyGoal ?? 8;
    final progress = log?.progress ?? 0.0;
    final goalMet = log?.goalMet ?? false;

    return BentoCard(
      padding: EdgeInsets.all(12.w),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('💧', style: TextStyle(fontSize: 18.sp)),
              if (goalMet)
                const StatusTag(type: TagType.taken)
              else
                const StatusTag(type: TagType.ongoing),
            ],
          ),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: onGoalTap,
            child: Row(
              children: [
                Text('Water',
                    style: GoogleFonts.inter(
                        fontSize: 11.sp, color: const Color(0xFF94A3B8))),
                SizedBox(width: 4.w),
                Icon(Icons.edit_rounded,
                    size: 10.w, color: const Color(0xFFCBD5E1)),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$consumed',
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  )),
              Padding(
                padding: EdgeInsets.only(left: 2.w, bottom: 2.h),
                child: Text('/$goal',
                    style: GoogleFonts.inter(
                        fontSize: 10.sp, color: const Color(0xFF94A3B8))),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4.h,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation(
                goalMet ? const Color(0xFF16A34A) : const Color(0xFF0EA5E9),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniBtn(
                  icon: Icons.remove_rounded,
                  onTap: onRemove,
                  color: const Color(0xFF94A3B8)),
              _MiniBtn(
                  icon: Icons.add_rounded,
                  onTap: onAdd,
                  color: const Color(0xFF0EA5E9),
                  filled: true),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sleep Tile ─────────────────────────────────────────────────────────────────

class _SleepTile extends StatelessWidget {
  final SleepLogModel? log;
  final VoidCallback? onTap;

  const _SleepTile({this.log, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasLog = log != null;
    final quality = hasLog ? log!.qualityLabel : null;
    final qualityColor = quality == 'Great'
        ? const Color(0xFF16A34A)
        : quality == 'Fair'
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return GestureDetector(
      onTap: onTap,
      child: BentoCard(
        padding: EdgeInsets.all(12.w),
        borderRadius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🌙', style: TextStyle(fontSize: 18.sp)),
                if (hasLog)
                  _QualityChip(label: quality!, color: qualityColor)
                else
                  Icon(Icons.add_circle_outline_rounded,
                      size: 16.w, color: const Color(0xFFCBD5E1)),
              ],
            ),
            SizedBox(height: 8.h),
            Text('Sleep',
                style: GoogleFonts.inter(
                    fontSize: 11.sp, color: const Color(0xFF94A3B8))),
            SizedBox(height: 2.h),
            Text(
              hasLog ? log!.label : '--',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding:
                  EdgeInsets.symmetric(vertical: 5.h),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(7.r),
              ),
              child: Center(
                child: Text(
                  hasLog ? 'Edit' : 'Log Sleep',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF7C3AED),
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

// ── Diet Tile ──────────────────────────────────────────────────────────────────

class _DietTile extends StatelessWidget {
  final DietLogModel? log;
  final VoidCallback? onTap;

  const _DietTile({this.log, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasLog = log != null && log!.calories > 0;
    final statusLabel = log?.statusLabel ?? 'Log';
    final statusColor = statusLabel == 'On track'
        ? const Color(0xFF16A34A)
        : statusLabel == 'Over'
            ? const Color(0xFFEF4444)
            : const Color(0xFFF59E0B);

    return GestureDetector(
      onTap: onTap,
      child: BentoCard(
        padding: EdgeInsets.all(12.w),
        borderRadius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🥗', style: TextStyle(fontSize: 18.sp)),
                if (hasLog)
                  _QualityChip(label: statusLabel, color: statusColor)
                else
                  Icon(Icons.add_circle_outline_rounded,
                      size: 16.w, color: const Color(0xFFCBD5E1)),
              ],
            ),
            SizedBox(height: 8.h),
            Text('Diet',
                style: GoogleFonts.inter(
                    fontSize: 11.sp, color: const Color(0xFF94A3B8))),
            SizedBox(height: 2.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hasLog ? log!.label : '--',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                if (hasLog)
                  Padding(
                    padding: EdgeInsets.only(left: 2.w, bottom: 1.h),
                    child: Text('cal',
                        style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: const Color(0xFF94A3B8))),
                  ),
              ],
            ),
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 5.h),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(7.r),
              ),
              child: Center(
                child: Text(
                  hasLog ? 'Edit' : 'Log Diet',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF22C55E),
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

// ── Quality chip ──────────────────────────────────────────────────────────────

class _QualityChip extends StatelessWidget {
  final String label;
  final Color color;
  const _QualityChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
            fontSize: 9.sp,
            fontWeight: FontWeight.w700,
            color: color,
          )),
    );
  }
}

// ── Mini Button ───────────────────────────────────────────────────────────────

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final bool filled;

  const _MiniBtn({
    required this.icon,
    this.onTap,
    required this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 24.w,
        width: 24.w,
        decoration: BoxDecoration(
          color: filled
              ? (enabled ? color : const Color(0xFFE2E8F0))
              : Colors.transparent,
          border: filled
              ? null
              : Border.all(
                  color: enabled ? color : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(7.r),
        ),
        child: Icon(icon,
            size: 14.w,
            color: filled
                ? Colors.white
                : (enabled ? color : const Color(0xFFCBD5E1))),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ENTRY SHEETS
// ══════════════════════════════════════════════════════════════════════════════

// ── Sleep Entry Sheet ─────────────────────────────────────────────────────────

class _SleepEntrySheet extends StatefulWidget {
  final SleepLogModel? existing;
  final void Function(int hours, int minutes) onSave;

  const _SleepEntrySheet({this.existing, required this.onSave});

  @override
  State<_SleepEntrySheet> createState() => _SleepEntrySheetState();
}

class _SleepEntrySheetState extends State<_SleepEntrySheet> {
  late int _hours;
  late int _minutes;
  bool _saving = false;

  static const _minuteOptions = [0, 15, 30, 45];

  @override
  void initState() {
    super.initState();
    _hours   = widget.existing?.hoursSlept ?? 7;
    _minutes = widget.existing?.minutesSlept ?? 0;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    widget.onSave(_hours, _minutes);
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      HapticFeedback.heavyImpact();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 36.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Handle(),
            SizedBox(height: 20.h),
            _SheetTitle(
              icon: Icons.bedtime_rounded,
              iconColor: const Color(0xFF7C3AED),
              title: 'Log Sleep',
              subtitle: "How long did you sleep?",
            ),
            SizedBox(height: 28.h),

            // ── Hours stepper ──
            _StepperRow(
              label: 'Hours',
              value: '$_hours',
              unit: 'h',
              color: const Color(0xFF7C3AED),
              canDecrement: _hours > 0,
              canIncrement: _hours < 12,
              onDecrement: () {
                HapticFeedback.selectionClick();
                setState(() => _hours--);
              },
              onIncrement: () {
                HapticFeedback.selectionClick();
                setState(() => _hours++);
              },
            ),
            SizedBox(height: 16.h),

            // ── Minutes selector ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Minutes',
                    style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B))),
                SizedBox(height: 10.h),
                Row(
                  children: _minuteOptions.map((m) {
                    final selected = _minutes == m;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _minutes = m);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: EdgeInsets.only(
                              right: m != 45 ? 8.w : 0),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF7C3AED)
                                : const Color(0xFFF8FBFA),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF7C3AED)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Center(
                            child: Text('${m}m',
                                style: GoogleFonts.poppins(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                )),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            SizedBox(height: 28.h),
            _SaveButton(
              label: 'Save Sleep',
              color: const Color(0xFF7C3AED),
              saving: _saving,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Diet Entry Sheet ──────────────────────────────────────────────────────────

class _DietEntrySheet extends StatefulWidget {
  final DietLogModel? existing;
  final void Function(int calories, int goal) onSave;

  const _DietEntrySheet({this.existing, required this.onSave});

  @override
  State<_DietEntrySheet> createState() => _DietEntrySheetState();
}

class _DietEntrySheetState extends State<_DietEntrySheet> {
  late int _calories;
  late int _goal;
  bool _saving = false;

  static const _quickAdd = [100, 200, 300, 500];

  @override
  void initState() {
    super.initState();
    _calories = widget.existing?.calories ?? 0;
    _goal     = widget.existing?.calorieGoal ?? 2000;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    widget.onSave(_calories, _goal);
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      HapticFeedback.heavyImpact();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_calories / _goal).clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 36.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Handle(),
            SizedBox(height: 20.h),
            _SheetTitle(
              icon: Icons.local_dining_rounded,
              iconColor: const Color(0xFF22C55E),
              title: 'Log Diet',
              subtitle: 'Track your calorie intake today',
            ),
            SizedBox(height: 24.h),

            // ── Progress bar ──
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6.r),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8.h,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation(
                        progress >= 1.0
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF22C55E),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  '$_calories / $_goal cal',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // ── Calorie stepper ──
            _StepperRow(
              label: 'Calories',
              value: '$_calories',
              unit: 'cal',
              color: const Color(0xFF22C55E),
              canDecrement: _calories >= 50,
              canIncrement: true,
              onDecrement: () {
                HapticFeedback.selectionClick();
                setState(() => _calories = (_calories - 50).clamp(0, 9999));
              },
              onIncrement: () {
                HapticFeedback.selectionClick();
                setState(() => _calories = (_calories + 50).clamp(0, 9999));
              },
            ),
            SizedBox(height: 12.h),

            // ── Quick-add chips ──
            Row(
              children: _quickAdd.map((v) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _calories =
                          (_calories + v).clamp(0, 9999));
                    },
                    child: Container(
                      margin: EdgeInsets.only(
                          right: v != _quickAdd.last ? 6.w : 0),
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                            color: const Color(0xFF22C55E)
                                .withValues(alpha: 0.2)),
                      ),
                      child: Center(
                        child: Text('+$v',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF22C55E),
                            )),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16.h),

            // ── Goal stepper ──
            _StepperRow(
              label: 'Daily Goal',
              value: '$_goal',
              unit: 'cal',
              color: const Color(0xFF64748B),
              canDecrement: _goal > 500,
              canIncrement: _goal < 5000,
              onDecrement: () {
                HapticFeedback.selectionClick();
                setState(() => _goal -= 100);
              },
              onIncrement: () {
                HapticFeedback.selectionClick();
                setState(() => _goal += 100);
              },
            ),

            SizedBox(height: 28.h),
            _SaveButton(
              label: 'Save Diet',
              color: const Color(0xFF22C55E),
              saving: _saving,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Water Goal Sheet ──────────────────────────────────────────────────────────

class _GoalSheet extends StatefulWidget {
  final int currentGoal;
  final ValueChanged<int> onSave;

  const _GoalSheet({required this.currentGoal, required this.onSave});

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  late int _goal;

  @override
  void initState() {
    super.initState();
    _goal = widget.currentGoal;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 36.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Handle(),
            SizedBox(height: 20.h),
            Text('Daily Water Goal',
                style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A))),
            SizedBox(height: 6.h),
            Text('How many glasses per day?',
                style: GoogleFonts.inter(
                    fontSize: 12.sp, color: const Color(0xFF94A3B8))),
            SizedBox(height: 28.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GoalBtn(
                  icon: Icons.remove_rounded,
                  onTap: _goal > 1
                      ? () {
                          HapticFeedback.selectionClick();
                          setState(() => _goal--);
                        }
                      : null,
                ),
                SizedBox(width: 24.w),
                Column(
                  children: [
                    Text('$_goal',
                        style: GoogleFonts.poppins(
                            fontSize: 42.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0EA5E9))),
                    Text('glasses',
                        style: GoogleFonts.inter(
                            fontSize: 12.sp, color: const Color(0xFF94A3B8))),
                  ],
                ),
                SizedBox(width: 24.w),
                _GoalBtn(
                  icon: Icons.add_rounded,
                  onTap: _goal < 20
                      ? () {
                          HapticFeedback.selectionClick();
                          setState(() => _goal++);
                        }
                      : null,
                ),
              ],
            ),
            SizedBox(height: 28.h),
            _SaveButton(
              label: 'Save Goal',
              color: const Color(0xFF0EA5E9),
              saving: false,
              onTap: () {
                HapticFeedback.heavyImpact();
                widget.onSave(_goal);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared sheet components ───────────────────────────────────────────────────

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40.w,
        height: 4.h,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(2.r),
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _SheetTitle({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 40.w,
          width: 40.w,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, size: 22.w, color: iconColor),
        ),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A))),
            Text(subtitle,
                style: GoogleFonts.inter(
                    fontSize: 12.sp, color: const Color(0xFF94A3B8))),
          ],
        ),
      ],
    );
  }
}

class _StepperRow extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool canDecrement;
  final bool canIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _StepperRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.canDecrement,
    required this.canIncrement,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFA),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B))),
          const Spacer(),
          _StepBtn(
              icon: Icons.remove_rounded,
              onTap: canDecrement ? onDecrement : null,
              color: color),
          SizedBox(width: 14.w),
          Text(
            '$value $unit',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(width: 14.w),
          _StepBtn(
              icon: Icons.add_rounded,
              onTap: canIncrement ? onIncrement : null,
              color: color),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _StepBtn({required this.icon, this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32.w,
        width: 32.w,
        decoration: BoxDecoration(
          color: enabled ? color.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon,
            size: 18.w,
            color: enabled ? color : const Color(0xFFCBD5E1)),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool saving;
  final VoidCallback onTap;

  const _SaveButton({
    required this.label,
    required this.color,
    required this.saving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed: saving ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          elevation: 0,
        ),
        child: saving
            ? SizedBox(
                height: 20.w,
                width: 20.w,
                child: const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 15.sp, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _GoalBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _GoalBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48.w,
        width: 48.w,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFF0EA5E9).withValues(alpha: 0.1)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Icon(icon,
            size: 24.w,
            color: enabled
                ? const Color(0xFF0EA5E9)
                : const Color(0xFFCBD5E1)),
      ),
    );
  }
}
