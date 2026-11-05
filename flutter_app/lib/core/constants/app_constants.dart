// lib/core/constants/app_constants.dart
// ============================================================
// Global application constants for SitePyoe
// ============================================================

import 'package:shared_preferences/shared_preferences.dart';

class AppConstants {
  AppConstants._();

  // ── App Info ────────────────────────────────────────────
  static const String appName    = 'ရွှေနံ့သာမြိုင်';
  static const String appVersion = '1.5.0';

  // ── API ─────────────────────────────────────────────────
  /// Permanent Production Cloud Server URL for ShweNantTarMyaing
  static const String productionApiBaseUrl = 'https://sntm.addtotechmm.com/api/v1';

  static const String keyApiBaseUrl = 'sp_custom_api_base_url';
  static String? _resolvedApiBaseUrl;

  static String get defaultApiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return sanitizeApiUrl(fromEnv);
    return productionApiBaseUrl;
  }

  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return sanitizeApiUrl(fromEnv);

    if (_resolvedApiBaseUrl != null && _resolvedApiBaseUrl!.isNotEmpty) {
      return _resolvedApiBaseUrl!;
    }

    return productionApiBaseUrl;
  }

  static void setResolvedApiBaseUrl(String url) {
    _resolvedApiBaseUrl = sanitizeApiUrl(url);
  }

  /// Sanitizes any user or cloud input (e.g., '192.168.1.5:5001' or 'https://api.com') into standard 'http(s)://.../api/v1'
  static String sanitizeApiUrl(String input) {
    var url = input.trim();
    if (url.isEmpty) return defaultApiBaseUrl;

    // Remove trailing slashes
    url = url.replaceAll(RegExp(r'/+$'), '');

    // Add protocol if missing
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }

    // Ensure /api/v1 suffix
    if (!url.endsWith('/api/v1')) {
      if (url.endsWith('/api')) {
        url = '$url/v1';
      } else if (url.endsWith('/v1')) {
        // e.g. http://host:5001/v1 -> replace trailing with /api/v1 if needed or keep
        if (!url.contains('/api/')) {
          url = url.replaceFirst(RegExp(r'/v1$'), '/api/v1');
        }
      } else {
        url = '$url/api/v1';
      }
    }
    return url;
  }

  /// Loads persisted Cloud Server API URL from SharedPreferences
  static Future<void> loadSavedBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(keyApiBaseUrl);
      if (saved != null && saved.trim().isNotEmpty) {
        _resolvedApiBaseUrl = sanitizeApiUrl(saved);
      }
    } catch (_) {}
  }

  /// Persists a custom Cloud Server API URL
  static Future<void> persistBaseUrl(String url) async {
    final clean = sanitizeApiUrl(url);
    _resolvedApiBaseUrl = clean;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyApiBaseUrl, clean);
    } catch (_) {}
  }

  /// Resets to default API URL
  static Future<void> resetBaseUrl() async {
    _resolvedApiBaseUrl = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(keyApiBaseUrl);
    } catch (_) {}
  }

  static const Duration apiTimeout = Duration(seconds: 20);

  // ── Local DB ─────────────────────────────────────────────
  static const String localDbName     = 'sitepyoe_local.db';
  static const int    localDbVersion  = 1;

  // ── Sync ─────────────────────────────────────────────────
  /// How often the background sync service polls the server (in minutes).
  static const int syncIntervalMinutes = 5;

  // ── POS ──────────────────────────────────────────────────
  static const String receiptPrefix   = 'SP';  // SP-BRA-20261013-0001
  static const String transferPrefix  = 'TRF';

  // ── Pagination ───────────────────────────────────────────
  static const int defaultPageSize = 50;

  // ── UI ───────────────────────────────────────────────────
  static const double tabletBreakpoint = 768.0;
  static const double cardBorderRadius = 16.0;
  static const double inputBorderRadius = 12.0;
}
