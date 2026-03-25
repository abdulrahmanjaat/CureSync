import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  MediaQueryData get mq => MediaQuery.of(this);
  double get screenWidth => mq.size.width;
  double get screenHeight => mq.size.height;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

extension StringExtensions on String {
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  String get initials => trim()
      .split(' ')
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();
}

extension DateTimeExtensions on DateTime {
  String get formatted =>
      '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';

  String get timeFormatted =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
