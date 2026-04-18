import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../providers/medication_provider.dart';
import '../providers/vitals_provider.dart';
import '../../data/models/medication_model.dart';
import '../../data/models/vitals_model.dart';
import '../widgets/dashboard/pill_timeline.dart';

// ─── Brand constants ──────────────────────────────────────────────────────────
const _teal  = Color(0xFF0D9488);
const _tealD = Color(0xFF115E59);
const _slate = Color(0xFF0F172A);
const _muted   = Color(0xFF94A3B8);
const _border  = Color(0xFFE2E8F0);

// ─── Report Screen ────────────────────────────────────────────────────────────

class ReportScreen extends ConsumerWidget {
  final String patientId;
  final String patientName;

  const ReportScreen({
    required this.patientId,
    required this.patientName,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync  = ref.watch(medicationsStreamProvider(patientId));
    final adherence  = ref.watch(todayAdherenceProvider(patientId));
    final timeline   = ref.watch(todayPillTimelineProvider(patientId));
    final vitalsAsync = ref.watch(latestVitalsProvider(patientId));

    final meds   = medsAsync.valueOrNull ?? [];
    final vitals = vitalsAsync.valueOrNull;

    final activeMeds   = meds.where((m) => m.isActive && !m.isExpired).toList();
    final expiredMeds  = meds.where((m) => m.isExpired).toList();
    final inactiveMeds = meds.where((m) => !m.isActive && !m.isExpired).toList();

    final adherencePct =
        adherence.total == 0 ? 0.0 : adherence.taken / adherence.total;

    final todayStr = DateFormat('MMMM d, yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFA),
      body: Stack(
        children: [
          // ── Ambient blob ──
          Positioned(
            top: -60.h,
            right: -40.w,
            child: Container(
              height: 240.w,
              width: 240.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _teal.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── App Bar ───────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).maybePop();
                          },
                          child: Container(
                            height: 40.w,
                            width: 40.w,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(13.r),
                              border: Border.all(color: _border),
                            ),
                            child: Icon(Icons.arrow_back_ios_new_rounded,
                                size: 16.w, color: _slate),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Health Report',
                                style: GoogleFonts.poppins(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w800,
                                  color: _slate,
                                ),
                              ),
                              Text(
                                todayStr,
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  color: _muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Download PDF button
                        GestureDetector(
                          onTap: () => _exportPdf(
                            context,
                            patientName: patientName,
                            meds: meds,
                            adherence: adherence,
                            timeline: timeline,
                            vitals: vitals,
                          ),
                          child: Container(
                            height: 40.h,
                            padding: EdgeInsets.symmetric(horizontal: 14.w),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_tealD, _teal],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: _teal.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.download_rounded,
                                    size: 16.w, color: Colors.white),
                                SizedBox(width: 6.w),
                                Text(
                                  'Export PDF',
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
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 20.h)),

                // ── Patient Identity Card ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: _IdentityCard(
                        patientName: patientName, todayStr: todayStr),
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 16.h)),

                // ── Adherence Summary ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: _AdherenceSummaryCard(
                      adherencePct: adherencePct,
                      taken: adherence.taken,
                      total: adherence.total,
                    ),
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 20.h)),

                // ── Today's Dose Log ──────────────────────────────────────────
                if (timeline.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      icon: Icons.schedule_rounded,
                      title: "Today's Doses",
                      subtitle: '${adherence.taken} taken · ${adherence.total - adherence.taken} pending',
                      color: _teal,
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _DoseLogCard(entry: timeline[i]),
                        childCount: timeline.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 20.h)),
                ],

                // ── Active Medications ────────────────────────────────────────
                if (activeMeds.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      icon: Icons.medication_rounded,
                      title: 'Active Medications',
                      subtitle: '${activeMeds.length} medication${activeMeds.length == 1 ? '' : 's'}',
                      color: const Color(0xFF0891B2),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _MedCard(med: activeMeds[i], isActive: true),
                        childCount: activeMeds.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 20.h)),
                ],

                // ── Expired / Inactive Medications ────────────────────────────
                if (expiredMeds.isNotEmpty || inactiveMeds.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      icon: Icons.history_rounded,
                      title: 'Past Medications',
                      subtitle: '${expiredMeds.length + inactiveMeds.length} completed',
                      color: _muted,
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final all = [...expiredMeds, ...inactiveMeds];
                          return _MedCard(med: all[i], isActive: false);
                        },
                        childCount: expiredMeds.length + inactiveMeds.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 20.h)),
                ],

                // ── Vitals ────────────────────────────────────────────────────
                if (vitals != null) ...[
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      icon: Icons.monitor_heart_rounded,
                      title: 'Latest Vitals',
                      subtitle: DateFormat('MMM d, h:mm a').format(vitals.recordedAt),
                      color: const Color(0xFFDB2777),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: _VitalsCard(vitals: vitals),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 20.h)),
                ],

                // ── Empty state ───────────────────────────────────────────────
                if (meds.isEmpty && vitals == null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 40.w, vertical: 40.h),
                      child: Column(
                        children: [
                          Container(
                            height: 72.w,
                            width: 72.w,
                            decoration: BoxDecoration(
                              color: _teal.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.assignment_outlined,
                                size: 36.w, color: _teal),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No report data yet',
                            style: GoogleFonts.poppins(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: _slate),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'Add medications and record vitals\nto generate your health report.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: _muted,
                                height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Footer ────────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: _teal.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14.r),
                        border:
                            Border.all(color: _teal.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_rounded,
                              size: 14.w, color: _teal),
                          SizedBox(width: 6.w),
                          Text(
                            'Generated by CureSync · $todayStr',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: _teal,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(child: SizedBox(height: 32.h)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── PDF Export ────────────────────────────────────────────────────────────────

  Future<void> _exportPdf(
    BuildContext context, {
    required String patientName,
    required List<MedicationModel> meds,
    required ({int taken, int total}) adherence,
    required List<PillTimelineEntry> timeline,
    required VitalsModel? vitals,
  }) async {
    HapticFeedback.lightImpact();

    final pdf  = pw.Document();
    final now  = DateTime.now();
    final date = DateFormat('MMMM d, yyyy').format(now);
    final time = DateFormat('h:mm a').format(now);

    final tealPdf  = PdfColor.fromInt(0xFF0D9488);
    final tealDark = PdfColor.fromInt(0xFF115E59);
    final mutedPdf = PdfColor.fromInt(0xFF64748B);
    final borderPdf = PdfColor.fromInt(0xFFE2E8F0);
    final greenPdf  = PdfColor.fromInt(0xFF16A34A);
    final redPdf    = PdfColor.fromInt(0xFFDC2626);
    final bgLight   = PdfColor.fromInt(0xFFF0FDFA);

    final activeMeds  = meds.where((m) => m.isActive && !m.isExpired).toList();
    final pastMeds    = meds.where((m) => m.isExpired || !m.isActive).toList();
    final adherencePct = adherence.total == 0
        ? 0.0
        : adherence.taken / adherence.total;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context ctx) => [
          // ── Header ──────────────────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [tealDark, tealPdf],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
              borderRadius: pw.BorderRadius.circular(14),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'CureSync Health Report',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Patient: $patientName',
                          style: pw.TextStyle(
                            fontSize: 13,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          date,
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Generated at $time',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColor.fromInt(0xCCFFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ── Adherence Summary ────────────────────────────────────────────────
          _pdfSectionTitle('ADHERENCE SUMMARY', tealPdf),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: bgLight,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: PdfColor.fromInt(0xFFB2F5EA)),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: _pdfStatBox(
                    'Doses Taken',
                    '${adherence.taken}',
                    greenPdf,
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: _pdfStatBox(
                    'Total Doses',
                    '${adherence.total}',
                    tealPdf,
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: _pdfStatBox(
                    'Adherence Rate',
                    '${(adherencePct * 100).toStringAsFixed(0)}%',
                    adherencePct >= 0.8
                        ? greenPdf
                        : adherencePct >= 0.5
                            ? PdfColor.fromInt(0xFFD97706)
                            : redPdf,
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: _pdfStatBox(
                    'Missed',
                    '${adherence.total - adherence.taken}',
                    adherence.total - adherence.taken > 0 ? redPdf : greenPdf,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ── Today's Dose Log ─────────────────────────────────────────────────
          if (timeline.isNotEmpty) ...[
            _pdfSectionTitle("TODAY'S DOSE LOG", tealPdf),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(
                  color: borderPdf, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(1.5),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: tealPdf),
                  children: [
                    _pdfTableHeader('Time'),
                    _pdfTableHeader('Medication'),
                    _pdfTableHeader('Status'),
                  ],
                ),
                // Data rows
                ...timeline.map(
                  (e) => pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: timeline.indexOf(e) % 2 == 0
                          ? PdfColors.white
                          : PdfColor.fromInt(0xFFF8FBFA),
                    ),
                    children: [
                      _pdfTableCell(e.time),
                      _pdfTableCell(e.medName),
                      _pdfTableCellColored(
                        e.isTaken ? 'Taken' : 'Pending',
                        e.isTaken ? greenPdf : PdfColor.fromInt(0xFFD97706),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // ── Active Medications ───────────────────────────────────────────────
          if (activeMeds.isNotEmpty) ...[
            _pdfSectionTitle('ACTIVE MEDICATIONS (${activeMeds.length})', tealPdf),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: borderPdf, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(1.2),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: tealPdf),
                  children: [
                    _pdfTableHeader('Medication'),
                    _pdfTableHeader('Dosage'),
                    _pdfTableHeader('Frequency'),
                    _pdfTableHeader('Meal Timing'),
                    _pdfTableHeader('Days Left'),
                  ],
                ),
                ...activeMeds.map((m) {
                  final daysLeft =
                      m.endDate.difference(DateTime.now()).inDays.clamp(0, 9999);
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: activeMeds.indexOf(m) % 2 == 0
                          ? PdfColors.white
                          : bgLight,
                    ),
                    children: [
                      _pdfTableCell(m.name),
                      _pdfTableCell(m.dosage),
                      _pdfTableCell(m.frequencyLabel),
                      _pdfTableCell(m.mealTiming.label),
                      _pdfTableCellColored(
                        '$daysLeft d',
                        daysLeft <= 3 ? redPdf : tealPdf,
                      ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // ── Past Medications ─────────────────────────────────────────────────
          if (pastMeds.isNotEmpty) ...[
            _pdfSectionTitle('PAST MEDICATIONS (${pastMeds.length})', mutedPdf),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: borderPdf, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF64748B)),
                  children: [
                    _pdfTableHeader('Medication'),
                    _pdfTableHeader('Dosage'),
                    _pdfTableHeader('Frequency'),
                    _pdfTableHeader('Status'),
                  ],
                ),
                ...pastMeds.map((m) => pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: pastMeds.indexOf(m) % 2 == 0
                            ? PdfColors.white
                            : PdfColor.fromInt(0xFFF8FAFC),
                      ),
                      children: [
                        _pdfTableCell(m.name),
                        _pdfTableCell(m.dosage),
                        _pdfTableCell(m.frequencyLabel),
                        _pdfTableCellColored(
                          m.isExpired ? 'Completed' : 'Paused',
                          mutedPdf,
                        ),
                      ],
                    )),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // ── Vitals ───────────────────────────────────────────────────────────
          if (vitals != null) ...[
            _pdfSectionTitle('LATEST VITALS', PdfColor.fromInt(0xFFDB2777)),
            pw.SizedBox(height: 4),
            pw.Text(
              'Recorded: ${DateFormat('MMM d, yyyy · h:mm a').format(vitals.recordedAt)}',
              style: pw.TextStyle(fontSize: 10, color: mutedPdf),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _pdfVitalsBox(
                    'Blood Pressure',
                    vitals.bpLabel,
                    'mmHg',
                    vitals.bpStatus,
                    vitals.bpNormal ? greenPdf : redPdf,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _pdfVitalsBox(
                    'Pulse',
                    '${vitals.pulse}',
                    'bpm',
                    vitals.pulseStatus,
                    vitals.pulseNormal ? greenPdf : redPdf,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _pdfVitalsBox(
                    'Oxygen Saturation',
                    '${vitals.oxygenSaturation}',
                    '% SpO₂',
                    vitals.spo2Status,
                    vitals.oxygenSaturation >= 95 ? greenPdf : redPdf,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
          ],

          // ── Footer ───────────────────────────────────────────────────────────
          pw.Divider(color: borderPdf),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'CureSync · Confidential Health Record',
                style: pw.TextStyle(fontSize: 9, color: mutedPdf),
              ),
              pw.Text(
                'Generated $date',
                style: pw.TextStyle(fontSize: 9, color: mutedPdf),
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'CureSync_Report_${patientName.replaceAll(' ', '_')}_${DateFormat('yyyy-MM-dd').format(now)}.pdf',
    );
  }

  // ── PDF helpers ───────────────────────────────────────────────────────────────

  static pw.Widget _pdfSectionTitle(String title, PdfColor color) =>
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      );

  static pw.Widget _pdfStatBox(String label, String value, PdfColor color) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: color),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              label,
              style:
                  pw.TextStyle(fontSize: 9, color: PdfColor.fromInt(0xFF64748B)),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      );

  static pw.Widget _pdfTableHeader(String label) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      );

  static pw.Widget _pdfTableCell(String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Text(value,
            style: pw.TextStyle(
                fontSize: 10, color: PdfColor.fromInt(0xFF0F172A))),
      );

  static pw.Widget _pdfTableCellColored(String value, PdfColor color) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Text(value,
            style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: color)),
      );

  static pw.Widget _pdfVitalsBox(
    String label,
    String value,
    String unit,
    String status,
    PdfColor statusColor,
  ) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                  fontSize: 9, color: PdfColor.fromInt(0xFF64748B)),
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  value,
                  style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF0F172A)),
                ),
                pw.SizedBox(width: 4),
                pw.Text(
                  unit,
                  style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColor.fromInt(0xFF64748B)),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: pw.BoxDecoration(
                color: statusColor,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                status,
                style:
                    pw.TextStyle(fontSize: 8, color: PdfColors.white),
              ),
            ),
          ],
        ),
      );
}

// ─── Identity Card ─────────────────────────────────────────────────────────────

class _IdentityCard extends StatelessWidget {
  final String patientName;
  final String todayStr;
  const _IdentityCard({required this.patientName, required this.todayStr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_tealD, _teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: _teal.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 52.w,
            width: 52.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                style: GoogleFonts.poppins(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Health Report · $todayStr',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'PATIENT',
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Adherence Summary Card ────────────────────────────────────────────────────

class _AdherenceSummaryCard extends StatelessWidget {
  final double adherencePct;
  final int taken;
  final int total;

  const _AdherenceSummaryCard({
    required this.adherencePct,
    required this.taken,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pctLabel = '${(adherencePct * 100).toStringAsFixed(0)}%';
    final ringColor = adherencePct >= 0.8
        ? const Color(0xFF16A34A)
        : adherencePct >= 0.5
            ? const Color(0xFFD97706)
            : const Color(0xFFDC2626);

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Adherence ring
          SizedBox(
            height: 80.w,
            width: 80.w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(80.w, 80.w),
                  painter: _RingPainter(
                    percentage: adherencePct,
                    color: ringColor,
                  ),
                ),
                Text(
                  pctLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: ringColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 20.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Adherence",
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: _slate,
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: _StatChip(
                        label: 'Taken',
                        value: '$taken',
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _StatChip(
                        label: 'Total',
                        value: '$total',
                        color: _teal,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _StatChip(
                        label: 'Missed',
                        value: '${total - taken}',
                        color: total - taken > 0
                            ? const Color(0xFFDC2626)
                            : _muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ring Painter ──────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double percentage;
  final Color color;
  const _RingPainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width - 10) / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Track
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Progress
    if (percentage > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * percentage,
        false,
        Paint()
          ..color = color
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.percentage != percentage || old.color != color;
}

// ─── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
      child: Row(
        children: [
          Container(
            height: 32.w,
            width: 32.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 16.w, color: color),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: _slate,
                  ),
                ),
                Text(
                  subtitle,
                  style:
                      GoogleFonts.inter(fontSize: 11.sp, color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dose Log Card ─────────────────────────────────────────────────────────────

class _DoseLogCard extends StatelessWidget {
  final PillTimelineEntry entry;
  const _DoseLogCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isTaken = entry.isTaken;
    final color = isTaken ? const Color(0xFF16A34A) : const Color(0xFFD97706);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isTaken
              ? const Color(0xFF16A34A).withValues(alpha: 0.2)
              : _border,
        ),
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
            child: Icon(
              isTaken
                  ? Icons.check_circle_rounded
                  : Icons.schedule_rounded,
              size: 18.w,
              color: color,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.medName,
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: _slate,
                  ),
                ),
                Text(
                  entry.time,
                  style:
                      GoogleFonts.inter(fontSize: 11.sp, color: _muted),
                ),
              ],
            ),
          ),
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              isTaken ? 'Taken' : 'Pending',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Medication Card ───────────────────────────────────────────────────────────

class _MedCard extends StatelessWidget {
  final MedicationModel med;
  final bool isActive;
  const _MedCard({required this.med, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final daysLeft = isActive && !med.isExpired
        ? med.endDate.difference(DateTime.now()).inDays.clamp(0, 9999)
        : 0;
    final daysColor = daysLeft <= 3 && isActive
        ? const Color(0xFFDC2626)
        : isActive
            ? _teal
            : _muted;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isActive ? _teal.withValues(alpha: 0.15) : _border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40.w,
            width: 40.w,
            decoration: BoxDecoration(
              color: isActive
                  ? _teal.withValues(alpha: 0.1)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.medication_rounded,
              size: 20.w,
              color: isActive ? _teal : _muted,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        med.name,
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: _slate,
                        ),
                      ),
                    ),
                    if (isActive && !med.isExpired)
                      Text(
                        '$daysLeft days left',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: daysColor,
                        ),
                      )
                    else
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: _muted.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          med.isExpired ? 'Completed' : 'Paused',
                          style: GoogleFonts.inter(
                              fontSize: 10.sp, color: _muted),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 4.h,
                  children: [
                    _InfoBadge(label: med.dosage, color: _teal),
                    _InfoBadge(
                        label: med.frequencyLabel,
                        color: const Color(0xFF0891B2)),
                    _InfoBadge(
                        label: med.mealTiming.label,
                        color: const Color(0xFF7C3AED)),
                  ],
                ),
                if (med.notes != null && med.notes!.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(
                    med.notes!,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: _muted,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─── Vitals Card ───────────────────────────────────────────────────────────────

class _VitalsCard extends StatelessWidget {
  final VitalsModel vitals;
  const _VitalsCard({required this.vitals});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _VitalTile(
              icon: Icons.bloodtype_rounded,
              color: const Color(0xFFDB2777),
              label: 'Blood Pressure',
              value: vitals.bpLabel,
              unit: 'mmHg',
              status: vitals.bpStatus,
              isNormal: vitals.bpNormal,
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _VitalTile(
              icon: Icons.favorite_rounded,
              color: const Color(0xFFEF4444),
              label: 'Pulse',
              value: '${vitals.pulse}',
              unit: 'bpm',
              status: vitals.pulseStatus,
              isNormal: vitals.pulseNormal,
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _VitalTile(
              icon: Icons.air_rounded,
              color: const Color(0xFF0891B2),
              label: 'SpO₂',
              value: '${vitals.oxygenSaturation}',
              unit: '%',
              status: vitals.spo2Status,
              isNormal: vitals.oxygenSaturation >= 95,
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String unit;
  final String status;
  final bool isNormal;

  const _VitalTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.unit,
    required this.status,
    required this.isNormal,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor =
        isNormal ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Column(
      children: [
        Icon(icon, size: 22.w, color: color),
        SizedBox(height: 6.h),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: _slate,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: GoogleFonts.inter(
                    fontSize: 10.sp, color: _muted),
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10.sp, color: _muted),
        ),
        SizedBox(height: 4.h),
        Container(
          padding:
              EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Text(
            status,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
      width: 1,
      color: _border,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
    );
  }
}
