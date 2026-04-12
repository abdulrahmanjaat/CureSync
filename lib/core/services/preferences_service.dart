import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles non-sensitive UI settings: onboarding seen, theme mode, etc.
class PreferencesService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('PreferencesService.init failed: $e');
    }
  }

  /// Ensure prefs is ready before reading. Falls back gracefully.
  static Future<void> _ensureInit() async {
    if (_prefs != null) return;
    await init();
  }

  // ─── Onboarding ───────────────────────────────────────────────
  static bool get hasSeenOnboarding =>
      _prefs?.getBool('has_seen_onboarding') ?? false;

  static Future<void> setOnboardingSeen() async {
    await _ensureInit();
    await _prefs?.setBool('has_seen_onboarding', true);
  }

  // ─── Theme ────────────────────────────────────────────────────
  static bool get isDarkMode => _prefs?.getBool('is_dark_mode') ?? false;

  static Future<void> setDarkMode(bool value) async {
    await _ensureInit();
    await _prefs?.setBool('is_dark_mode', value);
  }

  // ─── Avatar ───────────────────────────────────────────────────
  static int get avatarIndex => _prefs?.getInt('avatar_index') ?? 0;

  static Future<void> setAvatarIndex(int index) async {
    await _ensureInit();
    await _prefs?.setInt('avatar_index', index);
  }

  // ─── Clear ────────────────────────────────────────────────────
  static Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
