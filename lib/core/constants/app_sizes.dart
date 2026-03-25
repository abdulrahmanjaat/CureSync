import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppSizes {
  AppSizes._();

  // ─── Padding / Margin ─────────────────────────────────────────
  static double get xs => 4.w;
  static double get sm => 8.w;
  static double get md => 16.w;
  static double get lg => 24.w;
  static double get xl => 32.w;
  static double get xxl => 48.w;

  // ─── Border Radius ────────────────────────────────────────────
  static double get radiusSm => 8.r;
  static double get radiusMd => 12.r;
  static double get radiusLg => 16.r;
  static double get radiusXl => 24.r;
  static double get radiusFull => 100.r;

  // ─── Icon Sizes ───────────────────────────────────────────────
  static double get iconSm => 16.w;
  static double get iconMd => 24.w;
  static double get iconLg => 32.w;

  // ─── Convenience EdgeInsets ───────────────────────────────────
  static EdgeInsets get paddingAllSm => EdgeInsets.all(sm);
  static EdgeInsets get paddingAllMd => EdgeInsets.all(md);
  static EdgeInsets get paddingAllLg => EdgeInsets.all(lg);
  static EdgeInsets get paddingHorizontalMd =>
      EdgeInsets.symmetric(horizontal: md);
  static EdgeInsets get paddingHorizontalLg =>
      EdgeInsets.symmetric(horizontal: lg);
}
