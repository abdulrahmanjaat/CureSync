import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Primary (Teal — trust, health, calm) ─────────────────────
  static const Color primary = Color(0xFF0D9488);
  static const Color primaryLight = Color(0xFF5EEAD4);
  static const Color primaryDark = Color(0xFF115E59);
  static const Color primaryContainer = Color(0xFFCCFBF1);

  // ─── Accent (Coral — warmth, energy, CTAs) ────────────────────
  static const Color accent = Color(0xFFFF6B6B);
  static const Color accentLight = Color(0xFFFCA5A5);
  static const Color accentDark = Color(0xFFDC2626);

  // ─── Semantic ─────────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0EA5E9);

  // ─── Neutrals ─────────────────────────────────────────────────
  static const Color scaffold = Color(0xFFF0FDFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color disabled = Color(0xFFCBD5E1);

  // ─── Medical Status ───────────────────────────────────────────
  static const Color critical = Color(0xFFEF4444);
  static const Color stable = Color(0xFF22C55E);
  static const Color monitoring = Color(0xFFF59E0B);

  // ─── Gradients ────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF0D9488), Color(0xFF0891B2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
