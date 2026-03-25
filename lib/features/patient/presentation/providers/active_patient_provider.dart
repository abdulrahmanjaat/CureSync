import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks which patient profile is currently being viewed on the dashboard.
/// null = show the user's own profile / overview.
final activePatientIdProvider = StateProvider<String?>((ref) => null);
