// lib/core/network/http_logger.dart
// ============================================================
// Comprehensive HTTP Network Call Logger for SitePyoe
// Reproduces clear, structured console and logcat traces for API calls.
// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';

class HttpLogger {
  HttpLogger._();

  static const bool enabled = true;

  static String _statusName(int statusCode) {
    return switch (statusCode) {
      200 => '200 OK',
      201 => '201 CREATED',
      204 => '204 NO CONTENT',
      400 => '400 BAD REQUEST',
      401 => '401 UNAUTHORIZED',
      403 => '403 FORBIDDEN',
      404 => '404 NOT FOUND',
      409 => '409 CONFLICT',
      422 => '422 UNPROCESSABLE ENTITY',
      500 => '500 INTERNAL SERVER ERROR',
      502 => '502 BAD GATEWAY',
      503 => '503 SERVICE UNAVAILABLE',
      _ => '$statusCode',
    };
  }

  /// Log an outgoing HTTP request
  static void logRequest({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    dynamic body,
  }) {
    if (!enabled) return;

    final buffer = StringBuffer();
    buffer.writeln('┌──────────────────────────────────────────────────────────────────────────────');
    buffer.writeln('│ 🌐 [HTTP REQUEST] ${method.toUpperCase()} $uri');

    if (headers != null && headers.isNotEmpty) {
      final sanitizedHeaders = Map<String, String>.from(headers);
      if (sanitizedHeaders.containsKey('Authorization')) {
        final auth = sanitizedHeaders['Authorization']!;
        if (auth.startsWith('Bearer ') && auth.length > 20) {
          sanitizedHeaders['Authorization'] = 'Bearer ${auth.substring(7, 15)}...${auth.substring(auth.length - 6)}';
        }
      }
      buffer.writeln('│ 📋 Headers: ${jsonEncode(sanitizedHeaders)}');
    }

    if (body != null) {
      final sanitizedBody = _sanitizeAndFormat(body);
      final lines = sanitizedBody.split('\n');
      if (lines.length == 1) {
        buffer.writeln('│ 📦 Payload: $sanitizedBody');
      } else {
        buffer.writeln('│ 📦 Payload:');
        for (final l in lines) {
          buffer.writeln('│    $l');
        }
      }
    }

    buffer.writeln('└──────────────────────────────────────────────────────────────────────────────');
    debugPrint(buffer.toString());
  }

  /// Log an incoming HTTP response with formatted body and business status
  static void logResponse({
    required String method,
    required Uri uri,
    required int statusCode,
    required Duration duration,
    dynamic body,
  }) {
    if (!enabled) return;

    final isSuccess = statusCode >= 200 && statusCode < 300;
    final isClientError = statusCode >= 400 && statusCode < 500;
    final icon = isSuccess ? '🟢' : (isClientError ? '🟡' : '🔴');

    final businessOutcome = switch (statusCode) {
      200 || 201 => '✅ Operation Succeeded',
      401 => '🚫 Authentication Rejected: Invalid Credentials or Expired Session',
      403 => '⛔ Access Denied: User role does not have permission or account deactivated',
      400 => '⚠️ Bad Request: Validation failed',
      404 => '🔍 Not Found: Requested resource does not exist',
      409 => '⚠️ Conflict: Data conflict detected',
      _ when statusCode >= 500 => '💥 Server Error: Backend encountered an internal issue',
      _ => 'HTTP $statusCode',
    };

    final buffer = StringBuffer();
    buffer.writeln('┌──────────────────────────────────────────────────────────────────────────────');
    buffer.writeln('│ $icon [HTTP RESPONSE ${_statusName(statusCode)}] ${method.toUpperCase()} $uri (⏱️ ${duration.inMilliseconds}ms)');
    buffer.writeln('│ 📌 Business Status: $businessOutcome');

    if (body != null) {
      final formattedBody = _sanitizeAndFormat(body);
      final lines = formattedBody.split('\n');
      if (lines.length == 1) {
        buffer.writeln('│ 📦 Response: $formattedBody');
      } else {
        buffer.writeln('│ 📦 Response:');
        for (final l in lines) {
          buffer.writeln('│    $l');
        }
      }
    }

    buffer.writeln('└──────────────────────────────────────────────────────────────────────────────');
    debugPrint(buffer.toString());
  }

  /// Log a failed network call (e.g. SocketException, TimeoutException)
  static void logError({
    required String method,
    required Uri uri,
    required Object error,
    required Duration duration,
    StackTrace? stackTrace,
  }) {
    if (!enabled) return;

    final buffer = StringBuffer();
    buffer.writeln('┌──────────────────────────────────────────────────────────────────────────────');
    buffer.writeln('│ ❌ [HTTP NETWORK ERROR] ${method.toUpperCase()} $uri (⏱️ ${duration.inMilliseconds}ms)');
    buffer.writeln('│ 💥 Error: $error');
    if (error.toString().contains('Cleartext HTTP traffic')) {
      buffer.writeln('│ 💡 HINT: Cleartext HTTP blocked by Android. Ensure android:usesCleartextTraffic="true"');
    } else if (error.toString().contains('Connection refused')) {
      buffer.writeln('│ 💡 HINT: Cannot connect to server. Check if backend is running on port 5001.');
    }
    buffer.writeln('└──────────────────────────────────────────────────────────────────────────────');
    debugPrint(buffer.toString());
  }

  static String _sanitizeAndFormat(dynamic body) {
    try {
      dynamic parsed = body;
      if (body is String) {
        try {
          parsed = jsonDecode(body);
        } catch (_) {
          return body;
        }
      }

      final sanitized = _maskSensitive(parsed);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(sanitized);
    } catch (_) {
      return body.toString();
    }
  }

  static dynamic _maskSensitive(dynamic obj) {
    if (obj is Map) {
      final copy = <String, dynamic>{};
      const sensitiveKeys = ['password', 'refreshToken', 'secret'];
      for (final entry in obj.entries) {
        final key = entry.key.toString();
        if (sensitiveKeys.any((s) => key.toLowerCase().contains(s.toLowerCase()))) {
          copy[key] = '••••••••';
        } else if (key == 'accessToken' && entry.value is String) {
          final tok = entry.value as String;
          copy[key] = tok.length > 20 ? '${tok.substring(0, 10)}...${tok.substring(tok.length - 6)}' : '••••••••';
        } else {
          copy[key] = _maskSensitive(entry.value);
        }
      }
      return copy;
    } else if (obj is List) {
      return obj.map(_maskSensitive).toList();
    }
    return obj;
  }
}
