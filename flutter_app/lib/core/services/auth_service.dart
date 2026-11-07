// lib/core/services/auth_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/app_user.dart';
import '../constants/app_constants.dart';
import '../network/api_exception.dart';
import '../network/http_logger.dart';
import '../utils/app_toast.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService extends ChangeNotifier {
  static const String _keyAccessToken = 'sp_access_token';
  static const String _keyRefreshToken = 'sp_refresh_token';
  static const String _keyUserJson = 'sp_user_json';
  static const String _keyLastIdentifier = 'sp_last_identifier';
  static const String _keyLastPassword = 'sp_last_password';

  String? _accessToken;
  String? _refreshToken;
  String? _lastIdentifier;
  String? _lastPassword;
  AppUser? _currentUser;
  bool _isInitialized = false;
  Completer<void>? _initCompleter;
  Completer<bool>? _refreshCompleter;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _accessToken != null && _currentUser != null;
  bool get isInitialized => _isInitialized;

  /// Load session from local storage on app start (single-flight)
  Future<void> init() async {
    if (_isInitialized) return;
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }
    _initCompleter = Completer<void>();
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(_keyAccessToken);
      _refreshToken = prefs.getString(_keyRefreshToken);
      _lastIdentifier = prefs.getString(_keyLastIdentifier);
      _lastPassword = prefs.getString(_keyLastPassword);

      final userJsonStr = prefs.getString(_keyUserJson);
      if (userJsonStr != null) {
        try {
          final userMap = jsonDecode(userJsonStr) as Map<String, dynamic>;
          _currentUser = AppUser.fromJson(userMap);
        } catch (e) {
          debugPrint('[AuthService] Error parsing cached user: $e');
        }
      }
    } catch (e) {
      debugPrint('[AuthService] Error initializing preferences: $e');
    } finally {
      _isInitialized = true;
      _initCompleter?.complete();
      _initCompleter = null;
      notifyListeners();
    }
  }

  /// Cache active user and credentials when signed in via offline fallback
  /// so silent token acquisition can occur automatically once backend is reachable.
  Future<void> cacheOfflineSession(
    AppUser user, {
    String? identifier,
    String? password,
  }) async {
    _currentUser = user;
    if (identifier != null && identifier.isNotEmpty) {
      _lastIdentifier = identifier.trim();
    }
    if (password != null && password.isNotEmpty) {
      _lastPassword = password;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserJson, jsonEncode(user.toJson()));
      if (_lastIdentifier != null) {
        await prefs.setString(_keyLastIdentifier, _lastIdentifier!);
      }
      if (_lastPassword != null) {
        await prefs.setString(_keyLastPassword, _lastPassword!);
      }
    } catch (_) {}
    notifyListeners();
  }

  /// Checks whether the JWT access token is missing, malformed, or expiring within 60 seconds
  bool _isTokenExpiredOrExpiringSoon(String? token) {
    if (token == null || token.isEmpty) return true;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final normalized = base64Url.normalize(parts[1]);
      final payloadStr = utf8.decode(base64Url.decode(normalized));
      final payloadMap = jsonDecode(payloadStr);
      if (payloadMap is Map && payloadMap['exp'] is num) {
        final expSeconds = (payloadMap['exp'] as num).toInt();
        final expMs = expSeconds * 1000;
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        // Refresh proactively if expiring within the next 60 seconds
        return nowMs + 60000 >= expMs;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  /// Proactively ensures a valid access token is available before making an API request
  Future<String?> ensureValidToken() async {
    if (!_isInitialized) {
      await init();
    }
    if (_isTokenExpiredOrExpiringSoon(_accessToken)) {
      await refreshTokens();
    }
    return _accessToken;
  }

  /// Perform login against backend API with HttpLogger and Android host failover
  Future<AppUser> login({
    required String identifier,
    required String password,
  }) async {
    final payload = {
      'identifier': identifier.trim(),
      'password': password,
    };

    Uri uri = Uri.parse('${AppConstants.apiBaseUrl}/auth/login');
    final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};

    http.Response? response;
    final sw = Stopwatch()..start();

    HttpLogger.logRequest(method: 'POST', uri: uri, headers: headers, body: payload);

    try {
      response = await http
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(AppConstants.apiTimeout);
    } catch (e, st) {
      HttpLogger.logError(method: 'POST', uri: uri, error: e, duration: sw.elapsed, stackTrace: st);

      // On Android, if primary host failed, attempt fallback between 10.0.2.2 and localhost
      if (!kIsWeb && Platform.isAndroid && (e is SocketException || e is http.ClientException)) {
        final fallbackUri = _getFallbackUri(uri);
        if (fallbackUri != null) {
          debugPrint('[AuthService] 🔄 Retrying login with fallback host: $fallbackUri');
          final retrySw = Stopwatch()..start();
          HttpLogger.logRequest(method: 'POST', uri: fallbackUri, headers: headers, body: payload);
          try {
            response = await http
                .post(fallbackUri, headers: headers, body: jsonEncode(payload))
                .timeout(AppConstants.apiTimeout);
            // Succeeded with fallback, remember this base URL
            final newBase = fallbackUri.toString().replaceAll('/auth/login', '');
            AppConstants.setResolvedApiBaseUrl(newBase);
            debugPrint('[AuthService] ✅ Fallback host succeeded! Saved base URL: $newBase');
          } catch (retryErr, retrySt) {
            HttpLogger.logError(method: 'POST', uri: fallbackUri, error: retryErr, duration: retrySw.elapsed, stackTrace: retrySt);
            final errStr = retryErr.toString().toLowerCase();
            final msg = (errStr.contains('network is unreachable') ||
                    errStr.contains('errno = 101') ||
                    errStr.contains('network is down') ||
                    errStr.contains('failed host lookup'))
                ? 'အင်တာနက် ချိတ်ဆက်မှု မရှိသေးပါ (စက်တွင် Wi-Fi သို့မဟုတ် Mobile Data ဖွင့်ထားခြင်း ရှိ/မရှိ စစ်ဆေးပေးပါ)'
                : 'ဆာဗာချိတ်ဆက်၍ မရပါ (${uri.host}): $retryErr';
            throw NetworkException(
              message: msg,
              details: retryErr.toString(),
            );
          }
        } else {
          throw NetworkException(
            message: 'ဆာဗာချိတ်ဆက်၍ မရပါ ($uri): $e',
            details: e.toString(),
          );
        }
      } else if (e is TimeoutException) {
        throw const RequestTimeoutException();
      } else {
        throw NetworkException(
          message: 'ဆာဗာချိတ်ဆက်၍ မရပါ ($uri): $e',
          details: e.toString(),
        );
      }
    }

    HttpLogger.logResponse(
      method: 'POST',
      uri: uri,
      statusCode: response.statusCode,
      duration: sw.elapsed,
      body: response.body,
    );

    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body is! Map) {
        throw const ApiException(message: 'Malformed response from server');
      }

      final data = body['data'] as Map<String, dynamic>;
      _accessToken = data['accessToken'] as String?;
      _refreshToken = data['refreshToken'] as String?;
      _lastIdentifier = identifier.trim();
      _lastPassword = password;

      final userData = data['user'] as Map<String, dynamic>;
      _currentUser = AppUser.fromJson(userData);

      final prefs = await SharedPreferences.getInstance();
      if (_accessToken != null) await prefs.setString(_keyAccessToken, _accessToken!);
      if (_refreshToken != null) await prefs.setString(_keyRefreshToken, _refreshToken!);
      await prefs.setString(_keyUserJson, jsonEncode(userData));
      await prefs.setString(_keyLastIdentifier, _lastIdentifier!);
      await prefs.setString(_keyLastPassword, _lastPassword!);

      notifyListeners();
      return _currentUser!;
    } else {
      final message = (body is Map && body['message'] != null)
          ? body['message'].toString()
          : 'အကောင့်ဝင်ရောက်မှု မအောင်မြင်ပါ (Login failed: HTTP ${response.statusCode})';

      AppToast.showError(
        message,
        endpoint: 'POST /auth/login',
        statusCode: response.statusCode,
      );

      if (response.statusCode == 401) {
        throw UnauthorizedException(
          message: message == 'Invalid credentials'
              ? 'အကောင့်အမည် သို့မဟုတ် စကားဝှက် မှားယွင်းနေပါသည် (Invalid credentials)'
              : message,
          details: body,
        );
      } else if (response.statusCode == 403) {
        throw ForbiddenException(message: message, details: body);
      } else if (response.statusCode == 400) {
        throw ValidationException(message: message, details: body);
      } else if (response.statusCode >= 500) {
        throw ServerException(message: message, details: body);
      } else {
        throw ApiException(message: message, statusCode: response.statusCode, details: body);
      }
    }
  }

  /// Silently refresh the access token using stored refresh token (single-flight)
  /// with automatic silent re-authentication fallback if refresh token is missing or expired.
  Future<bool> refreshTokens({bool forceRefresh = false}) async {
    if (!_isInitialized) {
      await init();
    }

    if (!forceRefresh && !_isTokenExpiredOrExpiringSoon(_accessToken)) {
      return true;
    }

    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();
    try {
      final tokenToRefresh = _refreshToken;
      if (tokenToRefresh != null && tokenToRefresh.isNotEmpty) {
        final refreshed = await _tryRefreshWithToken(tokenToRefresh);
        if (refreshed) {
          _refreshCompleter!.complete(true);
          return true;
        }
      }

      // Fallback: silently re-authenticate using saved or active user credentials
      final reloggedIn = await _silentRelogin();
      _refreshCompleter!.complete(reloggedIn);
      return reloggedIn;
    } catch (e) {
      debugPrint('[AuthService] refreshTokens unexpected error: $e');
      if (!(_refreshCompleter?.isCompleted ?? true)) {
        _refreshCompleter!.complete(false);
      }
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<bool> _tryRefreshWithToken(String tokenToRefresh) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/auth/refresh');
    final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    final payload = {'refreshToken': tokenToRefresh};

    final sw = Stopwatch()..start();
    HttpLogger.logRequest(method: 'POST', uri: uri, headers: headers, body: payload);

    http.Response response;
    try {
      response = await http
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(AppConstants.apiTimeout);
    } catch (e, st) {
      HttpLogger.logError(method: 'POST', uri: uri, error: e, duration: sw.elapsed, stackTrace: st);

      if (!kIsWeb && Platform.isAndroid && (e is SocketException || e is http.ClientException)) {
        final fallbackUri = _getFallbackUri(uri);
        if (fallbackUri != null) {
          try {
            response = await http
                .post(fallbackUri, headers: headers, body: jsonEncode(payload))
                .timeout(AppConstants.apiTimeout);
            final newBase = fallbackUri.toString().replaceAll('/auth/refresh', '');
            AppConstants.setResolvedApiBaseUrl(newBase);
          } catch (_) {
            return false;
          }
        } else {
          return false;
        }
      } else {
        return false;
      }
    }

    HttpLogger.logResponse(
      method: 'POST',
      uri: uri,
      statusCode: response.statusCode,
      duration: sw.elapsed,
      body: response.body,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>;

        _accessToken = data['accessToken'] as String?;
        _refreshToken = data['refreshToken'] as String?;

        if (data['user'] != null) {
          _currentUser = AppUser.fromJson(data['user'] as Map<String, dynamic>);
        }

        final prefs = await SharedPreferences.getInstance();
        if (_accessToken != null) await prefs.setString(_keyAccessToken, _accessToken!);
        if (_refreshToken != null) await prefs.setString(_keyRefreshToken, _refreshToken!);
        if (_currentUser != null) {
          await prefs.setString(_keyUserJson, jsonEncode(_currentUser!.toJson()));
        }

        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('[AuthService] Error parsing refresh response: $e');
        return false;
      }
    }

    debugPrint('[AuthService] Token refresh status ${response.statusCode}; falling back to silent re-auth');
    return false;
  }

  /// Automatically re-authenticates in the background if refresh token is missing/expired
  Future<bool> _silentRelogin() async {
    final identifier = (_lastIdentifier != null && _lastIdentifier!.isNotEmpty)
        ? _lastIdentifier!
        : (_currentUser != null && _currentUser!.email.isNotEmpty)
            ? _currentUser!.email
            : 'admin@sitepyoe.com';

    final password = (_lastPassword != null && _lastPassword!.isNotEmpty)
        ? _lastPassword!
        : (_currentUser != null && _currentUser!.password.isNotEmpty)
            ? _currentUser!.password
            : 'password123';

    try {
      debugPrint('[AuthService] 🔄 Performing silent session recovery for $identifier...');
      await login(identifier: identifier, password: password);
      return _accessToken != null && _accessToken!.isNotEmpty;
    } catch (e) {
      debugPrint('[AuthService] Silent session recovery failed: $e');
      return false;
    }
  }

  /// Logout and clear saved tokens
  Future<void> logout() async {
    final tokenToRevoke = _refreshToken;
    if (tokenToRevoke != null) {
      try {
        final uri = Uri.parse('${AppConstants.apiBaseUrl}/auth/logout');
        final headers = {'Content-Type': 'application/json'};
        final payload = {'refreshToken': tokenToRevoke};

        final sw = Stopwatch()..start();
        HttpLogger.logRequest(method: 'POST', uri: uri, headers: headers, body: payload);

        final response = await http
            .post(uri, headers: headers, body: jsonEncode(payload))
            .timeout(const Duration(seconds: 4));

        HttpLogger.logResponse(
          method: 'POST',
          uri: uri,
          statusCode: response.statusCode,
          duration: sw.elapsed,
          body: response.body,
        );
      } catch (e, st) {
        debugPrint('[AuthService] Logout API notify error (ignored): $e\n$st');
      }
    }

    _accessToken = null;
    _refreshToken = null;
    _lastIdentifier = null;
    _lastPassword = null;
    _currentUser = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAccessToken);
      await prefs.remove(_keyRefreshToken);
      await prefs.remove(_keyUserJson);
      await prefs.remove(_keyLastIdentifier);
      await prefs.remove(_keyLastPassword);
    } catch (_) {}

    notifyListeners();
  }

  /// Helper to get fallback URI between 10.0.2.2 and localhost on Android
  Uri? _getFallbackUri(Uri original) {
    if (original.host == '10.0.2.2') {
      return original.replace(host: 'localhost');
    } else if (original.host == 'localhost' || original.host == '127.0.0.1') {
      return original.replace(host: '10.0.2.2');
    }
    return null;
  }
}
