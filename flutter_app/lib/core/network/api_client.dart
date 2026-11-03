// lib/core/network/api_client.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import '../utils/app_toast.dart';
import 'api_exception.dart';
import 'http_logger.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final authService = ref.watch(authServiceProvider);
  return ApiClient(authService: authService);
});

class ApiClient {
  final AuthService _authService;
  final http.Client _client;

  ApiClient({
    required AuthService authService,
    http.Client? client,
  })  : _authService = authService,
        _client = client ?? http.Client();

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final fullUrl = '${AppConstants.apiBaseUrl}$cleanEndpoint';

    if (queryParams == null || queryParams.isEmpty) {
      return Uri.parse(fullUrl);
    }

    final sanitizedParams = <String, String>{};
    queryParams.forEach((key, value) {
      if (value != null) {
        sanitizedParams[key] = value.toString();
      }
    });

    return Uri.parse(fullUrl).replace(queryParameters: sanitizedParams);
  }

  Map<String, String> _buildHeaders([Map<String, String>? customHeaders]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = _authService.accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  Uri? _getFallbackUri(Uri original) {
    if (original.host == 'sntm.addtotechmm.com') {
      return original.replace(scheme: 'http', host: '206.189.43.23', port: 80);
    } else if (original.host == '206.189.43.23') {
      return original.replace(scheme: 'https', host: 'sntm.addtotechmm.com', port: 443);
    } else if (original.host == '10.0.2.2') {
      return original.replace(host: 'localhost');
    } else if (original.host == 'localhost' || original.host == '127.0.0.1') {
      return original.replace(host: '10.0.2.2');
    }
    return null;
  }

  /// Central request executor with HttpLogger, proactive token validation, silent 401 refresh, and Android fallback
  Future<dynamic> _executeRequest({
    required String method,
    required String endpoint,
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    bool isRetry = false,
    bool suppressErrorToast = false,
  }) async {
    await _authService.ensureValidToken();
    Uri uri = _buildUri(endpoint, queryParams);
    final reqHeaders = _buildHeaders(headers);
    final sw = Stopwatch()..start();

    HttpLogger.logRequest(method: method, uri: uri, headers: reqHeaders, body: body);

    http.Response response;
    try {
      response = await _dispatchHttp(method, uri, reqHeaders, body);
    } catch (e, st) {
      HttpLogger.logError(method: method, uri: uri, error: e, duration: sw.elapsed, stackTrace: st);

      // On Android, if connection failed, retry with fallback host (10.0.2.2 <-> localhost)
      if (!kIsWeb && Platform.isAndroid && (e is SocketException || e is http.ClientException)) {
        final fallbackUri = _getFallbackUri(uri);
        if (fallbackUri != null) {
          debugPrint('[ApiClient] 🔄 Retrying $method with fallback host: $fallbackUri');
          final retrySw = Stopwatch()..start();
          HttpLogger.logRequest(method: method, uri: fallbackUri, headers: reqHeaders, body: body);
          try {
            response = await _dispatchHttp(method, fallbackUri, reqHeaders, body);
            // Succeeded with fallback, remember this base URL
            final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
            final newBase = fallbackUri.toString().replaceAll(cleanEndpoint, '');
            AppConstants.setResolvedApiBaseUrl(newBase);
            debugPrint('[ApiClient] ✅ Fallback host succeeded! Saved base URL: $newBase');
          } catch (retryErr, retrySt) {
            HttpLogger.logError(method: method, uri: fallbackUri, error: retryErr, duration: retrySw.elapsed, stackTrace: retrySt);
            final errMsg = 'ဆာဗာချိတ်ဆက်၍ မရပါ (Host unreachable: $uri, $fallbackUri): $retryErr';
            if (!suppressErrorToast) {
              AppToast.showError(errMsg, endpoint: '$method $endpoint');
            }
            throw NetworkException(
              message: errMsg,
              details: retryErr.toString(),
            );
          }
        } else {
          final errMsg = 'ဆာဗာချိတ်ဆက်၍ မရပါ ($uri): $e';
          if (!suppressErrorToast) {
            AppToast.showError(errMsg, endpoint: '$method $endpoint');
          }
          throw NetworkException(
            message: errMsg,
            details: e.toString(),
          );
        }
      } else if (e is TimeoutException) {
        const timeoutEx = RequestTimeoutException();
        if (!suppressErrorToast) {
          AppToast.showError(timeoutEx.message, endpoint: '$method $endpoint');
        }
        throw timeoutEx;
      } else {
        final errMsg = 'ဆာဗာချိတ်ဆက်၍ မရပါ ($uri): $e';
        if (!suppressErrorToast) {
          AppToast.showError(errMsg, endpoint: '$method $endpoint');
        }
        throw NetworkException(
          message: errMsg,
          details: e.toString(),
        );
      }
    }

    HttpLogger.logResponse(
      method: method,
      uri: uri,
      statusCode: response.statusCode,
      duration: sw.elapsed,
      body: response.body,
    );

    // Silent 401 refresh
    if (response.statusCode == 401 && !isRetry) {
      final refreshed = await _authService.refreshTokens(forceRefresh: true);
      if (refreshed) {
        return _executeRequest(
          method: method,
          endpoint: endpoint,
          body: body,
          queryParams: queryParams,
          headers: headers,
          isRetry: true,
          suppressErrorToast: suppressErrorToast,
        );
      } else {
        const unauthEx = UnauthorizedException();
        if (!suppressErrorToast) {
          AppToast.showError(
            unauthEx.message,
            endpoint: '$method $endpoint',
            statusCode: 401,
          );
        }
        throw unauthEx;
      }
    }

    return _handleResponse(
      response,
      endpoint: '$method $endpoint',
      suppressErrorToast: suppressErrorToast,
    );
  }

  Future<http.Response> _dispatchHttp(
    String method,
    Uri uri,
    Map<String, String> headers,
    dynamic body,
  ) {
    final payload = body != null ? jsonEncode(body) : null;
    switch (method.toUpperCase()) {
      case 'GET':
        return _client.get(uri, headers: headers).timeout(AppConstants.apiTimeout);
      case 'POST':
        return _client.post(uri, headers: headers, body: payload).timeout(AppConstants.apiTimeout);
      case 'PATCH':
        return _client.patch(uri, headers: headers, body: payload).timeout(AppConstants.apiTimeout);
      case 'DELETE':
        return _client.delete(uri, headers: headers).timeout(AppConstants.apiTimeout);
      default:
        throw UnimplementedError('HTTP method $method not supported');
    }
  }

  dynamic _handleResponse(
    http.Response response, {
    String? endpoint,
    bool suppressErrorToast = false,
  }) {
    dynamic body;
    try {
      if (response.body.isNotEmpty) {
        body = jsonDecode(response.body);
      }
    } catch (_) {
      body = null;
    }

    final statusCode = response.statusCode;
    final message = (body is Map && body['message'] != null)
        ? body['message'].toString()
        : 'HTTP Error $statusCode';

    if (statusCode >= 200 && statusCode < 300) {
      if (body is Map && body.containsKey('data')) {
        return body['data'];
      }
      return body;
    }

    if (!suppressErrorToast) {
      AppToast.showError(
        message,
        endpoint: endpoint,
        statusCode: statusCode,
      );
    }

    switch (statusCode) {
      case 400:
        throw ValidationException(message: message, details: body);
      case 401:
        throw UnauthorizedException(message: message, details: body);
      case 403:
        throw ForbiddenException(message: message, details: body);
      case 404:
        throw NotFoundException(message: message, details: body);
      case 409:
        throw ConflictException(message: message, details: body);
      case 500:
      case 502:
      case 503:
        throw ServerException(message: message, details: body);
      default:
        throw ApiException(message: message, statusCode: statusCode, details: body);
    }
  }

  /// GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    bool suppressErrorToast = false,
  }) {
    return _executeRequest(
      method: 'GET',
      endpoint: endpoint,
      queryParams: queryParams,
      headers: headers,
      suppressErrorToast: suppressErrorToast,
    );
  }

  /// POST request
  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    bool suppressErrorToast = false,
  }) {
    return _executeRequest(
      method: 'POST',
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
      suppressErrorToast: suppressErrorToast,
    );
  }

  /// PATCH request
  Future<dynamic> patch(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    bool suppressErrorToast = false,
  }) {
    return _executeRequest(
      method: 'PATCH',
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
      suppressErrorToast: suppressErrorToast,
    );
  }

  /// DELETE request
  Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    bool suppressErrorToast = false,
  }) {
    return _executeRequest(
      method: 'DELETE',
      endpoint: endpoint,
      queryParams: queryParams,
      headers: headers,
      suppressErrorToast: suppressErrorToast,
    );
  }

  /// Multipart image / file upload
  Future<dynamic> multipartPost(
    String endpoint, {
    required String fileFieldName,
    required String filePath,
    Map<String, String>? fields,
    Map<String, dynamic>? queryParams,
    bool isRetry = false,
  }) async {
    await _authService.ensureValidToken();
    final uri = _buildUri(endpoint, queryParams);
    final sw = Stopwatch()..start();
    HttpLogger.logRequest(
      method: 'MULTIPART POST',
      uri: uri,
      body: {'file': filePath, 'fields': fields},
    );

    try {
      final request = http.MultipartRequest('POST', uri);

      final token = _authService.accessToken;
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      if (fields != null) {
        request.fields.addAll(fields);
      }

      final file = await http.MultipartFile.fromPath(fileFieldName, filePath);
      request.files.add(file);

      final streamedResponse = await request.send().timeout(AppConstants.apiTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      HttpLogger.logResponse(
        method: 'MULTIPART POST',
        uri: uri,
        statusCode: response.statusCode,
        duration: sw.elapsed,
        body: response.body,
      );

      if (response.statusCode == 401 && !isRetry) {
        final refreshed = await _authService.refreshTokens(forceRefresh: true);
        if (refreshed) {
          return multipartPost(
            endpoint,
            fileFieldName: fileFieldName,
            filePath: filePath,
            fields: fields,
            queryParams: queryParams,
            isRetry: true,
          );
        }
      }

      return _handleResponse(response, endpoint: 'POST $endpoint');
    } catch (e, st) {
      HttpLogger.logError(
        method: 'MULTIPART POST',
        uri: uri,
        error: e,
        duration: sw.elapsed,
        stackTrace: st,
      );
      if (e is SocketException || e is http.ClientException) {
        final msg = 'ပုံတင်၍ မရပါ (File upload network error): $e';
        AppToast.showError(msg, endpoint: 'POST $endpoint');
        throw NetworkException(message: msg);
      } else if (e is TimeoutException) {
        const timeoutEx = RequestTimeoutException();
        AppToast.showError(timeoutEx.message, endpoint: 'POST $endpoint');
        throw timeoutEx;
      }
      rethrow;
    }
  }
}
