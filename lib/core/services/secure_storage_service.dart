import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Handles sensitive data: auth tokens, remembered credentials.
/// Uses AES encryption on Android (EncryptedSharedPreferences).
/// All methods are wrapped in try-catch to prevent crashes on
/// hot restart where the platform channel may not be registered.
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ─── Keys ─────────────────────────────────────────────────────
  static const _keyRememberEmail = 'remember_email';
  static const _keyRememberPassword = 'remember_password';
  static const _keyRememberMe = 'remember_me_enabled';

  // ─── Remember Me ──────────────────────────────────────────────
  static Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _keyRememberEmail, value: email),
        _storage.write(key: _keyRememberPassword, value: password),
        _storage.write(key: _keyRememberMe, value: 'true'),
      ]);
    } catch (e) {
      debugPrint('SecureStorage.saveCredentials failed: $e');
    }
  }

  static Future<({String? email, String? password})>
      getCredentials() async {
    try {
      final email = await _storage.read(key: _keyRememberEmail);
      final password = await _storage.read(key: _keyRememberPassword);
      return (email: email, password: password);
    } catch (e) {
      debugPrint('SecureStorage.getCredentials failed: $e');
      return (email: null, password: null);
    }
  }

  static Future<bool> isRememberMeEnabled() async {
    try {
      final val = await _storage.read(key: _keyRememberMe);
      return val == 'true';
    } catch (e) {
      debugPrint('SecureStorage.isRememberMeEnabled failed: $e');
      return false;
    }
  }

  static Future<void> clearCredentials() async {
    try {
      await Future.wait([
        _storage.delete(key: _keyRememberEmail),
        _storage.delete(key: _keyRememberPassword),
        _storage.delete(key: _keyRememberMe),
      ]);
    } catch (e) {
      debugPrint('SecureStorage.clearCredentials failed: $e');
    }
  }

  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('SecureStorage.clearAll failed: $e');
    }
  }
}
