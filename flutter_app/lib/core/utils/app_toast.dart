import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Global key attached to [MaterialApp.scaffoldMessengerKey] so that any layer
/// (including [ApiClient], [AuthService], or Riverpod Notifiers) can display
/// immediate toast/snackbar feedback without requiring a [BuildContext].
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class AppToast {
  AppToast._();

  static String? _lastErrorKey;
  static DateTime? _lastErrorTime;

  /// Displays a prominent red error toast whenever an API call or business rule fails.
  /// Automatically clears any existing snackbar so fake "success" toasts never mask errors.
  static void showError(
    String message, {
    String? endpoint,
    int? statusCode,
  }) {
    final cleanMsg = message.replaceFirst('ApiException: ', '').trim();
    final prefix = statusCode != null
        ? 'API Error ($statusCode)${endpoint != null ? ' [$endpoint]' : ''}'
        : (endpoint != null ? 'API Error [$endpoint]' : 'Error');
    final fullText = '$prefix: $cleanMsg';

    final now = DateTime.now();
    if (_lastErrorKey == fullText &&
        _lastErrorTime != null &&
        now.difference(_lastErrorTime!) < const Duration(milliseconds: 1200)) {
      return;
    }
    _lastErrorKey = fullText;
    _lastErrorTime = now;

    _dispatchSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                fullText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Displays a green success toast only after an operation has succeeded.
  static void showSuccess(String message) {
    _dispatchSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Displays an informational toast (e.g. for background sync, offline events).
  static void showInfo(String message) {
    _dispatchSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Displays an amber warning toast.
  static void showWarning(String message) {
    _dispatchSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.black87, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void _dispatchSnackBar(SnackBar snackBar) {
    void show() {
      final messenger = rootScaffoldMessengerKey.currentState;
      if (messenger != null) {
        messenger.clearSnackBars();
        messenger.showSnackBar(snackBar);
      }
    }

    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger != null) {
      show();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => show());
    }
  }
}

