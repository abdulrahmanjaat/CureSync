import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/medication_provider.dart';
import '../../providers/water_tracker_provider.dart';
import '../../../../../features/patient/data/models/water_log_model.dart';
import 'bento_card.dart';
import 'status_tag.dart';

class LifestyleStrip extends ConsumerWidget {
  const LifestyleStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientId = ref.watch(resolvedActivePatientIdProvider);
    final waterAsync = patientId != null
        ? ref.watch(todayWaterLogProvider(patientId))
        : const AsyncValue<WaterLogModel?>.data(null);

    final water = waterAsync.valueOrNull;

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
                        .logGlass(patientId,
                            currentGoal: water?.dailyGoal ?? 8);
                  },
            onRemove: patientId == null || (water?.glassesConsumed ?? 0) == 0
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

        // ── Sleep Tile (static) ─────────────────────────────────────────
        Expanded(
          child: _StaticTile(
            emoji: '🌙',
            label: 'Sleep',
            value: '7h 15m',
            unit: '',
            streak: '3 day streak',
            color: const Color(0xFF7C3AED),
            tagType: TagType.active,
          ),
        ),
        SizedBox(width: 10.w),

        // ── Diet Tile (static) ──────────────────────────────────────────
        Expanded(
          child: _StaticTile(
            emoji: '🥗',
            label: 'Diet',
            value: '1,840',
            unit: 'cal',
            streak: '',
            color: const Color(0xFF22C55E),
            tagType: TagType.taken,
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
        onSave: (goal) {
          ref.read(waterTrackerRepositoryProvider).updateGoal(patientId, goal);
        },
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
          // Header row
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

          // Label + goal edit
          GestureDetector(
            onTap: onGoalTap,
            child: Row(
              children: [
                Text(
                  'Water',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(Icons.edit_rounded,
                    size: 10.w, color: const Color(0xFFCBD5E1)),
              ],
            ),
          ),
          SizedBox(height: 2.h),

          // Count
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$consumed',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 2.w, bottom: 2.h),
                child: Text(
                  '/$goal',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),

          // Progress bar
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4.h,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation(
                goalMet
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF0EA5E9),
              ),
            ),
          ),
          SizedBox(height: 8.h),

          // +/- buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniBtn(
                icon: Icons.remove_rounded,
                onTap: onRemove,
                color: const Color(0xFF94A3B8),
              ),
              _MiniBtn(
                icon: Icons.add_rounded,
                onTap: onAdd,
                color: const Color(0xFF0EA5E9),
                filled: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
        child: Icon(
          icon,
          size: 14.w,
          color: filled
              ? Colors.white
              : (enabled ? color : const Color(0xFFCBD5E1)),
        ),
      ),
    );
  }
}

// ── Static Lifestyle Tile ─────────────────────────────────────────────────────

class _StaticTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final String unit;
  final String streak;
  final Color color;
  final TagType tagType;

  const _StaticTile({
    required this.emoji,
    required this.label,
    required this.value,
    required this.unit,
    required this.streak,
    required this.color,
    required this.tagType,
  });

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: EdgeInsets.all(12.w),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(emoji, style: TextStyle(fontSize: 18.sp)),
              Flexible(child: StatusTag(type: tagType)),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: const Color(0xFF94A3B8),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              if (unit.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(left: 2.w, bottom: 1.h),
                  child: Text(
                    unit,
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ),
            ],
          ),
          if (streak.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              streak,
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Goal Setter Sheet ─────────────────────────────────────────────────────────

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
            SizedBox(height: 20.h),
            Text(
              'Daily Water Goal',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'How many glasses per day?',
              style: GoogleFonts.inter(
                  fontSize: 12.sp, color: const Color(0xFF94A3B8)),
            ),
            SizedBox(height: 28.h),

            // Stepper
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
                    Text(
                      '$_goal',
                      style: GoogleFonts.poppins(
                        fontSize: 42.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0EA5E9),
                      ),
                    ),
                    Text(
                      'glasses',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
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

            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  widget.onSave(_goal);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r)),
                  elevation: 0,
                ),
                child: Text(
                  'Save Goal',
                  style: GoogleFonts.poppins(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
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
