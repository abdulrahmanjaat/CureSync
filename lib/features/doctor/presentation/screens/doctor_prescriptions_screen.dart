import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/prescription_model.dart';
import '../providers/doctor_provider.dart';

// ── Brand palette ─────────────────────────────────────────────────────────────
const Color _indigo  = Color(0xFF4338CA);
const Color _indigoL = Color(0xFF6366F1);
const Color _bg      = Color(0xFFF5F5FF);

Color _rxStatusColor(PrescriptionStatus s) => switch (s) {
      PrescriptionStatus.active    => _indigo,
      PrescriptionStatus.dispensed => const Color(0xFF16A34A),
      PrescriptionStatus.expired   => const Color(0xFF94A3B8),
      PrescriptionStatus.cancelled => const Color(0xFFEF4444),
    };

String _formatDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

// ════════════════════════════════════════════════════════════════════════════
// Screen
// ════════════════════════════════════════════════════════════════════════════
class DoctorPrescriptionsScreen extends ConsumerWidget {
  const DoctorPrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rxs = ref.watch(doctorPrescriptionsProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140.h,
            pinned: true,
            backgroundColor: _indigo,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_indigo, _indigoL],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 50.h, 20.w, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prescriptions',
                          style: GoogleFonts.poppins(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${rxs.length} issued',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showWriteSheet(context, ref);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded,
                            size: 15.w, color: Colors.white),
                        SizedBox(width: 4.w),
                        Text(
                          'Write Rx',
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
              ),
            ],
          ),

          // ── List ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(child: SizedBox(height: 12.h)),

          if (rxs.isEmpty)
            SliverToBoxAdapter(
              child: _EmptyState()
                  .animate()
                  .fadeIn(duration: 300.ms),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                  child: _RxCard(rx: rxs[i])
                      .animate()
                      .fadeIn(duration: 260.ms, delay: (i * 50).ms)
                      .slideY(
                          begin: 0.04,
                          end: 0,
                          duration: 260.ms,
                          delay: (i * 50).ms),
                ),
                childCount: rxs.length,
              ),
            ),

          SliverToBoxAdapter(child: SizedBox(height: 120.h)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showWriteSheet(context, ref);
        },
        backgroundColor: _indigo,
        icon: const Icon(Icons.edit_document, color: Colors.white),
        label: Text(
          'Write Prescription',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showWriteSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WritePrescriptionSheet(ref: ref),
    );
  }
}

// ─── Rx Card ──────────────────────────────────────────────────────────────────

class _RxCard extends StatelessWidget {
  final PrescriptionModel rx;
  const _RxCard({required this.rx});

  @override
  Widget build(BuildContext context) {
    final color = _rxStatusColor(rx.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: _indigo.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 4.h,
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      height: 40.w,
                      width: 40.w,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.receipt_long_rounded,
                          size: 20.w, color: color),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rx.patientName,
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${rx.patientAge} yrs · Issued ${_formatDate(rx.issuedAt)}',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        rx.status.label,
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),

                if (rx.diagnosis != null && rx.diagnosis!.isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  _InfoRow(
                    icon: Icons.medical_information_rounded,
                    label: rx.diagnosis!,
                    color: _indigo,
                  ),
                ],

                SizedBox(height: 10.h),

                // Medications chips
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: rx.medications.map((m) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: _indigo.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: _indigo.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        '${m.name} ${m.dosage}',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: _indigo,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                SizedBox(height: 10.h),
                _InfoRow(
                  icon: Icons.schedule_rounded,
                  label:
                      'Expires ${_formatDate(rx.expiresAt)}',
                  color: const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13.w, color: color),
        SizedBox(width: 5.w),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Write Prescription Sheet ─────────────────────────────────────────────────

class _WritePrescriptionSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _WritePrescriptionSheet({required this.ref});

  @override
  ConsumerState<_WritePrescriptionSheet> createState() =>
      _WritePrescriptionSheetState();
}

class _WritePrescriptionSheetState
    extends ConsumerState<_WritePrescriptionSheet> {
  final _patientNameCtrl = TextEditingController();
  final _patientAgeCtrl  = TextEditingController();
  final _diagnosisCtrl   = TextEditingController();
  final _notesCtrl       = TextEditingController();

  // Medicine fields
  final _medNameCtrl  = TextEditingController();
  final _dosageCtrl   = TextEditingController();
  final _freqCtrl     = TextEditingController();
  final _durationCtrl = TextEditingController();

  final List<PrescribedMedication> _meds = [];
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _patientNameCtrl, _patientAgeCtrl, _diagnosisCtrl, _notesCtrl,
      _medNameCtrl, _dosageCtrl, _freqCtrl, _durationCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  void _addMed() {
    final name = _medNameCtrl.text.trim();
    final dosage = _dosageCtrl.text.trim();
    final freq = _freqCtrl.text.trim();
    final dur = int.tryParse(_durationCtrl.text.trim()) ?? 7;
    if (name.isEmpty || dosage.isEmpty || freq.isEmpty) return;
    setState(() {
      _meds.add(PrescribedMedication(
        name: name, dosage: dosage, frequency: freq, durationDays: dur,
      ));
      _medNameCtrl.clear();
      _dosageCtrl.clear();
      _freqCtrl.clear();
      _durationCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (_meds.isEmpty || _patientNameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final authUser = ref.read(authStateProvider).valueOrNull;
    final userData = ref.read(currentUserDataProvider).valueOrNull;
    final doctorName = authUser?.displayName ?? userData?.name ?? '';

    final rx = PrescriptionModel(
      doctorId:    authUser?.uid ?? '',
      doctorName:  doctorName.isEmpty ? 'Doctor' : doctorName,
      patientId:   '',
      patientName: _patientNameCtrl.text.trim(),
      patientAge:  int.tryParse(_patientAgeCtrl.text.trim()) ?? 0,
      medications: _meds,
      diagnosis:   _diagnosisCtrl.text.trim().isEmpty
          ? null
          : _diagnosisCtrl.text.trim(),
      notes:       _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim(),
      status:      PrescriptionStatus.active,
      issuedAt:    DateTime.now(),
      expiresAt:   DateTime.now().add(const Duration(days: 30)),
    );

    await createPrescription(rx);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: EdgeInsets.only(top: 60.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 12.h),
              height: 4.h,
              width: 40.w,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
            child: Row(
              children: [
                Container(
                  height: 36.w,
                  width: 36.w,
                  decoration: BoxDecoration(
                    color: _indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.edit_document, size: 18.w, color: _indigo),
                ),
                SizedBox(width: 10.w),
                Text(
                  'Write Prescription',
                  style: GoogleFonts.poppins(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, bottom + 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Patient Information'),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _Field(
                            ctrl: _patientNameCtrl,
                            label: 'Patient Name'),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _Field(
                          ctrl: _patientAgeCtrl,
                          label: 'Age',
                          inputType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  _Field(ctrl: _diagnosisCtrl, label: 'Diagnosis (optional)'),

                  SizedBox(height: 20.h),
                  _sectionLabel('Medications'),
                  SizedBox(height: 8.h),

                  // Medicine entry row
                  _MedEntryRow(
                    nameCtrl:     _medNameCtrl,
                    dosageCtrl:   _dosageCtrl,
                    freqCtrl:     _freqCtrl,
                    durationCtrl: _durationCtrl,
                    onAdd:        _addMed,
                  ),

                  // Added meds
                  if (_meds.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    ..._meds.asMap().entries.map((e) => _MedChip(
                          med: e.value,
                          onRemove: () =>
                              setState(() => _meds.removeAt(e.key)),
                        )),
                  ],

                  SizedBox(height: 16.h),
                  _Field(
                    ctrl: _notesCtrl,
                    label: 'Notes (optional)',
                    maxLines: 3,
                  ),

                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Issue Prescription',
                              style: GoogleFonts.inter(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
        ),
      );
}

// ─── Reusable form field ───────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputType inputType;
  final int maxLines;

  const _Field({
    required this.ctrl,
    required this.label,
    this.inputType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      maxLines: maxLines,
      style: GoogleFonts.inter(
        fontSize: 13.sp,
        color: const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 12.sp,
          color: const Color(0xFF94A3B8),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: _indigoL, width: 1.5),
        ),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      ),
    );
  }
}

// ─── Med entry row ────────────────────────────────────────────────────────────

class _MedEntryRow extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController dosageCtrl;
  final TextEditingController freqCtrl;
  final TextEditingController durationCtrl;
  final VoidCallback onAdd;

  const _MedEntryRow({
    required this.nameCtrl,
    required this.dosageCtrl,
    required this.freqCtrl,
    required this.durationCtrl,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: _indigo.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _indigo.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _Field(ctrl: nameCtrl, label: 'Drug name'),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _Field(ctrl: dosageCtrl, label: 'Dosage'),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _Field(ctrl: freqCtrl, label: 'Frequency'),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _Field(
                  ctrl: durationCtrl,
                  label: 'Days',
                  inputType: TextInputType.number,
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onAdd();
                },
                child: Container(
                  height: 48.h,
                  width: 48.h,
                  decoration: BoxDecoration(
                    color: _indigo,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(Icons.add_rounded,
                      size: 22.w, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Med chip ────────────────────────────────────────────────────────────────

class _MedChip extends StatelessWidget {
  final PrescribedMedication med;
  final VoidCallback onRemove;

  const _MedChip({required this.med, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _indigo.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.medication_rounded, size: 16.w, color: _indigo),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${med.name} — ${med.dosage}',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '${med.frequency} · ${med.durationDays} days',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded,
                size: 16.w, color: const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 60.h, horizontal: 20.w),
      child: Column(
        children: [
          Container(
            height: 72.w,
            width: 72.w,
            decoration: BoxDecoration(
              color: _indigo.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_rounded,
                size: 34.w, color: _indigo),
          ),
          SizedBox(height: 14.h),
          Text(
            'No prescriptions issued',
            style: GoogleFonts.poppins(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Tap "Write Rx" to issue a new prescription.',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
