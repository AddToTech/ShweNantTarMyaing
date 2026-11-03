// lib/ui/shared/dialogs/server_connection_dialog.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../features/auth/view_models/auth_notifier.dart';
import '../../../data/repositories/branch_repository.dart';

class ServerConnectionDialog extends ConsumerStatefulWidget {
  const ServerConnectionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const ServerConnectionDialog(),
    );
  }

  @override
  ConsumerState<ServerConnectionDialog> createState() => _ServerConnectionDialogState();
}

class _ServerConnectionDialogState extends ConsumerState<ServerConnectionDialog> {
  late TextEditingController _urlCtrl;
  bool _isTesting = false;
  bool? _testSuccess;
  String? _testMessage;
  int? _latencyMs;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: AppConstants.apiBaseUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final rawInput = _urlCtrl.text.trim();
    if (rawInput.isEmpty) {
      setState(() {
        _testSuccess = false;
        _testMessage = 'ကျေးဇူးပြု၍ ဆာဗာ URL လိပ်စာ ရိုက်ထည့်ပါ';
      });
      return;
    }

    final sanitized = AppConstants.sanitizeApiUrl(rawInput);
    final healthUrl = sanitized.endsWith('/api/v1')
        ? sanitized.replaceAll('/api/v1', '/health')
        : '$sanitized/health';

    setState(() {
      _isTesting = true;
      _testSuccess = null;
      _testMessage = null;
      _latencyMs = null;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final uri = Uri.parse(healthUrl);
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 6));
      stopwatch.stop();

      if (response.statusCode == 200) {
        String dbStatus = 'connected';
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          dbStatus = body['database']?.toString() ?? 'connected';
        } catch (_) {}

        if (mounted) {
          setState(() {
            _isTesting = false;
            _testSuccess = true;
            _latencyMs = stopwatch.elapsedMilliseconds;
            _testMessage = 'ဆာဗာနှင့် အောင်မြင်စွာ ချိတ်ဆက်မိပါပြီ (PostgreSQL: $dbStatus)';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isTesting = false;
            _testSuccess = false;
            _latencyMs = stopwatch.elapsedMilliseconds;
            _testMessage = 'Server returned HTTP ${response.statusCode}: ${response.reasonPhrase}';
          });
        }
      }
    } catch (e) {
      stopwatch.stop();
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _latencyMs = stopwatch.elapsedMilliseconds;
          _testMessage = 'ချိတ်ဆက်မှု မအောင်မြင်ပါ: ${e.toString().replaceAll('Exception:', '').trim()}';
        });
      }
    }
  }

  Future<void> _handleSave() async {
    final rawInput = _urlCtrl.text.trim();
    if (rawInput.isEmpty) return;

    final sanitized = AppConstants.sanitizeApiUrl(rawInput);
    await AppConstants.persistBaseUrl(sanitized);

    // Refresh user list and branch cache from new server
    try {
      ref.read(branchListNotifierProvider.notifier).loadBranches();
      ref.read(authProvider.notifier).loadRemoteUsers();
    } catch (_) {}

    AppToast.showSuccess('Cloud ဆာဗာ လိပ်စာ သိမ်းဆည်းပြီးပါပြီ: $sanitized');

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleReset() async {
    await AppConstants.resetBaseUrl();
    setState(() {
      _urlCtrl.text = AppConstants.defaultApiBaseUrl;
      _testSuccess = null;
      _testMessage = null;
      _latencyMs = null;
    });

    try {
      ref.read(branchListNotifierProvider.notifier).loadBranches();
      ref.read(authProvider.notifier).loadRemoteUsers();
    } catch (_) {}

    AppToast.showSuccess('မူလ ဆာဗာ လိပ်စာသို့ ပြန်လည်သတ်မှတ်ပြီးပါပြီ');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 580,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cloud_sync_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cloud Server & API Settings',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ဗဟို Cloud PostgreSQL API ဆာဗာလိပ်စာ ချိတ်ဆက်မှု ဆက်တင်များ',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Current Active Server Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.dns_rounded, size: 18, color: AppColors.textMuted),
                  const SizedBox(width: 10),
                  Text(
                    'လက်ရှိအသုံးပြုနေသော URL:',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppConstants.apiBaseUrl,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Input Field
            Text(
              'Cloud Server API URL (Domain သို့မဟုတ် Public IP)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlCtrl,
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. https://sitepyoe-api.cloud.com/api/v1',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.link_rounded, size: 20, color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () => _urlCtrl.clear(),
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 10),

            Text(
              '💡 ဥပမာ: https://api.yourdomain.com/api/v1 သို့မဟုတ် http://192.168.1.100:5001/api/v1\n(Cloud Server ပေါ်တွင် Docker, PM2 သို့မဟုတ် Railway/Render ဖြင့် လွှင့်တင်ထားသော URL)',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 16),

            // Test Result Banner
            if (_isTesting)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'ဆာဗာသို့ ချိတ်ဆက် စစ်ဆေးနေပါသည်...',
                      style: TextStyle(fontSize: 12.5, color: AppColors.primary),
                    ),
                  ],
                ),
              )
            else if (_testSuccess != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _testSuccess!
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _testSuccess! ? AppColors.success : AppColors.error,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testSuccess! ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                      size: 18,
                      color: _testSuccess! ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _testMessage ?? '',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: _testSuccess! ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ),
                    if (_latencyMs != null)
                      Text(
                        '${_latencyMs}ms',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _testSuccess! ? AppColors.success : AppColors.error,
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                TextButton.icon(
                  onPressed: _handleReset,
                  icon: Icon(Icons.restore_rounded, size: 16, color: AppColors.textMuted),
                  label: Text(
                    'မူလအတိုင်း ပြန်ထားမည်',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _isTesting ? null : _testConnection,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.wifi_tethering_rounded, size: 18),
                  label: const Text('စမ်းသပ်ချိတ်ဆက်မည် (Ping)', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('သိမ်းဆည်းမည်', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
