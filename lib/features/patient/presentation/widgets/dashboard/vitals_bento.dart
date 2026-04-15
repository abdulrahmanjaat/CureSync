import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/medication_provider.dart';
import '../../providers/vitals_provider.dart';
import '../../../../../features/patient/data/models/vitals_model.dart';
import 'bento_card.dart';

class VitalsBento extends ConsumerWidget {
  /// Explicit patientId to use. When provided the widget is bound to that
  /// patient and ignores [resolvedActivePatientIdProvider] entirely.
  /// Pass [selfPatientIdProvider] from the Patient dashboard,
  /// pass the tracking patientId from the Manager view.
  final String? patientId;

  const VitalsBento({super.key, this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientId = this.patientId ?? ref.watch(resolvedActivePatientIdProvider);
    final vitalsAsync = patientId != null
        ? ref.watch(latestVitalsProvider(patientId))
        : const AsyncValue<VitalsModel?>.data(null);

    final vitals = vitalsAsync.valueOrNull;

    void openSheet() {
      if (patientId == null) return;
      HapticFeedback.lightImpact();
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _VitalsEntrySheet(
          patientId: patientId,
          existing: vitals,
        ),
      );
    }

    return Row(
      children: [
        // ── Heart Rate Card ──────────────────────────────────────────────
        Expanded(
          child: GestureDetector(
            onTap: openSheet,
            child: BentoCard(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 36.w,
                        width: 36.w,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFF6B6B).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(Icons.monitor_heart_rounded,
                            size: 20.w, color: const Color(0xFFFF6B6B)),
                      ),
                      if (vitals != null)
                        _VitalChip(
                          label: vitals.pulseStatus,
                          color: vitals.pulseNormal
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFEF4444),
                        )
                      else
                        Icon(Icons.add_circle_outline_rounded,
                            size: 18.w, color: const Color(0xFFCBD5E1)),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    'Heart Rate',
                    style: GoogleFonts.inter(
                        fontSize: 12.sp, color: const Color(0xFF94A3B8)),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        vitals != null ? '${vitals.pulse}' : '--',
                        style: GoogleFonts.poppins(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 5.h, left: 3.w),
                        child: Text(
                          'bpm',
                          style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: const Color(0xFF94A3B8)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  CustomPaint(
                    size: Size(double.infinity, 24.h),
                    painter: _EcgPainter(
                      color: vitals != null
                          ? const Color(0xFFFF6B6B)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),

        // ── Blood Pressure Card ──────────────────────────────────────────
        Expanded(
          child: GestureDetector(
            onTap: openSheet,
            child: BentoCard(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 36.w,
                        width: 36.w,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF0D9488).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(Icons.bloodtype_rounded,
                            size: 20.w, color: const Color(0xFF0D9488)),
                      ),
                      if (vitals != null)
                        _VitalChip(
                          label: vitals.bpStatus,
                          color: vitals.bpNormal
                              ? const Color(0xFF16A34A)
                              : vitals.bpElevated
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFEF4444),
                        )
                      else
                        Icon(Icons.add_circle_outline_rounded,
                            size: 18.w, color: const Color(0xFFCBD5E1)),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    'Blood Pressure',
                    style: GoogleFonts.inter(
                        fontSize: 12.sp, color: const Color(0xFF94A3B8)),
                  ),
                  SizedBox(height: 2.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          vitals != null ? vitals.bpLabel : '--/--',
                          style: GoogleFonts.poppins(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 4.h, left: 3.w),
                          child: Text(
                            'mmHg',
                            style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                color: const Color(0xFF94A3B8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 6.h),
                  if (vitals != null)
                    Row(
                      children: [
                        Icon(Icons.air_rounded,
                            size: 12.w,
                            color: const Color(0xFF0D9488)
                                .withValues(alpha: 0.6)),
                        SizedBox(width: 4.w),
                        Text(
                          'SpO₂ ${vitals.oxygenSaturation}%  •  ${vitals.spo2Status}',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Tap to record',
                      style: GoogleFonts.inter(
                          fontSize: 11.sp, color: const Color(0xFFCBD5E1)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Vital Status Chip ─────────────────────────────────────────────────────────

class _VitalChip extends StatelessWidget {
  final String label;
  final Color color;
  const _VitalChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── ECG Painter ───────────────────────────────────────────────────────────────

class _EcgPainter extends CustomPainter {
  final Color color;
  const _EcgPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final w = size.width;
    final mid = size.height / 2;

    path.moveTo(0, mid);
    path.lineTo(w * 0.2, mid);
    path.lineTo(w * 0.28, mid - size.height * 0.3);
    path.lineTo(w * 0.34, mid + size.height * 0.5);
    path.lineTo(w * 0.40, mid - size.height * 0.6);
    path.lineTo(w * 0.46, mid + size.height * 0.3);
    path.lineTo(w * 0.52, mid);
    path.lineTo(w, mid);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_EcgPainter old) => old.color != color;
}

// ── Vitals Entry Bottom Sheet ─────────────────────────────────────────────────

class _VitalsEntrySheet extends ConsumerStatefulWidget {
  final String patientId;
  final VitalsModel? existing;

  const _VitalsEntrySheet({required this.patientId, this.existing});

  @override
  ConsumerState<_VitalsEntrySheet> createState() => _VitalsEntrySheetState();
}

class _VitalsEntrySheetState extends ConsumerState<_VitalsEntrySheet> {
  late int _systolic;
  late int _diastolic;
  late int _pulse;
  late int _spo2;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _systolic = widget.existing?.systolic ?? 120;
    _diastolic = widget.existing?.diastolic ?? 80;
    _pulse = widget.existing?.pulse ?? 72;
    _spo2 = widget.existing?.oxygenSaturation ?? 98;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(vitalsRepositoryProvider).addVitals(
            patientId: widget.patientId,
            systolic: _systolic,
            diastolic: _diastolic,
            pulse: _pulse,
            oxygenSaturation: _spo2,
          );
      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vitals recorded',
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: const Color(0xFF0D9488),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r)),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
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
        padding: EdgeInsets.fromLTRB(
            20.w, 12.h, 20.w, MediaQuery.of(context).viewInsets.bottom + 32.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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

            // Title
            Row(
              children: [
                Container(
                  height: 38.w,
                  width: 38.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Icons.favorite_rounded,
                      size: 20.w, color: const Color(0xFF0D9488)),
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Record Vitals',
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Enter your current measurements',
                      style: GoogleFonts.inter(
                          fontSize: 12.sp, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Blood Pressure row
            _SheetSection(
              icon: Icons.bloodtype_rounded,
              iconColor: const Color(0xFF0D9488),
              label: 'Blood Pressure',
              hint: 'mmHg',
              children: [
                _VitalStepper(
                  label: 'Systolic',
                  value: _systolic,
                  min: 60,
                  max: 250,
                  onChanged: (v) => setState(() => _systolic = v),
                ),
                SizedBox(width: 16.w),
                _VitalStepper(
                  label: 'Diastolic',
                  value: _diastolic,
                  min: 40,
                  max: 150,
                  onChanged: (v) => setState(() => _diastolic = v),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Pulse + SpO2 row
            _SheetSection(
              icon: Icons.monitor_heart_rounded,
              iconColor: const Color(0xFFFF6B6B),
              label: 'Heart Rate & Oxygen',
              hint: '',
              children: [
                _VitalStepper(
                  label: 'Pulse (bpm)',
                  value: _pulse,
                  min: 30,
                  max: 220,
                  onChanged: (v) => setState(() => _pulse = v),
                ),
                SizedBox(width: 16.w),
                _VitalStepper(
                  label: 'SpO₂ (%)',
                  value: _spo2,
                  min: 70,
                  max: 100,
                  onChanged: (v) => setState(() => _spo2 = v),
                ),
              ],
            ),
            SizedBox(height: 28.h),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFF0D9488).withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r)),
                  elevation: 0,
                ),
                child: _saving
                    ? SizedBox(
                        height: 20.w,
                        width: 20.w,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Save Vitals',
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

// ── Sheet Section ─────────────────────────────────────────────────────────────

class _SheetSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String hint;
  final List<Widget> children;

  const _SheetSection({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.hint,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFA),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14.w, color: iconColor),
              SizedBox(width: 6.w),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              if (hint.isNotEmpty) ...[
                SizedBox(width: 4.w),
                Text(
                  hint,
                  style: GoogleFonts.inter(
                      fontSize: 11.sp, color: const Color(0xFF94A3B8)),
                ),
              ],
            ],
          ),
          SizedBox(height: 14.h),
          Row(children: children),
        ],
      ),
    );
  }
}

// ── Vital Stepper ─────────────────────────────────────────────────────────────

class _VitalStepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _VitalStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepBtn(
                icon: Icons.remove_rounded,
                onTap: value > min
                    ? () {
                        HapticFeedback.selectionClick();
                        onChanged(value - 1);
                      }
                    : null,
              ),
              SizedBox(width: 10.w),
              SizedBox(
                width: 48.w,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              _StepBtn(
                icon: Icons.add_rounded,
                onTap: value < max
                    ? () {
                        HapticFeedback.selectionClick();
                        onChanged(value + 1);
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32.w,
        width: 32.w,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFF0D9488).withValues(alpha: 0.1)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(
          icon,
          size: 18.w,
          color: enabled
              ? const Color(0xFF0D9488)
              : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }
}
