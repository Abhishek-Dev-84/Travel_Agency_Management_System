import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Shows a dialog to configure and test the TAMS Django backend API URL.
Future<void> showServerConfigDialog(
  BuildContext context, {
  VoidCallback? onSaved,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => ServerConfigDialog(onSaved: onSaved),
  );
}

class ServerConfigDialog extends StatefulWidget {
  final VoidCallback? onSaved;
  const ServerConfigDialog({super.key, this.onSaved});

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  final _api = ApiService();
  late final TextEditingController _urlCtrl;
  bool _isTesting = false;
  bool _isAutoDetecting = false;
  Map<String, dynamic>? _testResult;

  static const List<Map<String, String>> presets = [
    {
      'title': 'USB Cable (ADB Reverse)',
      'url': 'http://127.0.0.1:8000/api/v1',
      'icon': 'usb',
      'hint': 'Run on PC: adb reverse tcp:8000 tcp:8000',
    },
    {
      'title': 'Wi-Fi Network (PC LAN)',
      'url': 'http://10.106.1.72:8000/api/v1',
      'icon': 'wifi',
      'hint': 'Phone & PC on same Wi-Fi with Django on 0.0.0.0:8000',
    },
    {
      'title': 'Android Emulator',
      'url': 'http://10.0.2.2:8000/api/v1',
      'icon': 'emulator',
      'hint': 'For Android Studio virtual AVD',
    },
    {
      'title': 'Localhost (Web / Desktop)',
      'url': 'http://127.0.0.1:8000/api/v1',
      'icon': 'desktop',
      'hint': 'For Chrome web and Windows native app',
    },
  ];

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: _api.baseUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _runTest([String? overrideUrl]) async {
    final target = (overrideUrl != null && overrideUrl.isNotEmpty)
        ? overrideUrl
        : _urlCtrl.text.trim();

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final res = await _api.testConnection(target);

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testResult = res;
      });
    }
  }

  Future<void> _runAutoDetect() async {
    setState(() {
      _isAutoDetecting = true;
      _testResult = null;
    });

    final detected = await _api.autoDetectBaseUrl();

    if (mounted) {
      setState(() {
        _isAutoDetecting = false;
        if (detected != null) {
          _urlCtrl.text = detected;
          _testResult = {
            'success': true,
            'message': 'Auto-detected active backend: $detected',
            'statusCode': 200,
          };
        } else {
          _testResult = {
            'success': false,
            'message':
                'No active backend responded on USB (127.0.0.1), Wi-Fi (10.106.1.72), or Emulator (10.0.2.2). Please verify Django is running on 0.0.0.0:8000.',
          };
        }
      });
    }
  }

  void _saveAndClose() {
    final newUrl = _urlCtrl.text.trim();
    if (newUrl.isEmpty) return;

    _api.baseUrl = newUrl;
    widget.onSaved?.call();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'API Server updated: $newUrl',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPresetIcon(String type) {
    switch (type) {
      case 'usb':
        return Icons.usb;
      case 'wifi':
        return Icons.wifi;
      case 'emulator':
        return Icons.phone_android;
      case 'desktop':
      default:
        return Icons.computer;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.dns, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Backend API Server',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Configure connection to Django REST backend',
                          style: TextStyle(color: Color(0xFFD6E0EA), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Preset Chips
                    const Text(
                      'QUICK SELECT CONNECTION MODE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ...presets.map((preset) {
                      final isSelected = _urlCtrl.text.trim() == preset['url'];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.accentSoft
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.accent
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            setState(() {
                              _urlCtrl.text = preset['url']!;
                              _testResult = null;
                            });
                            _runTest(preset['url']);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getPresetIcon(preset['icon']!),
                                  size: 20,
                                  color: isSelected
                                      ? AppTheme.accentDark
                                      : AppTheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            preset['title']!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                              color: isSelected
                                                  ? AppTheme.accentDark
                                                  : AppTheme.textDark,
                                            ),
                                          ),
                                          if (isSelected) ...[
                                            const SizedBox(width: 6),
                                            const Icon(
                                              Icons.check_circle,
                                              size: 14,
                                              color: AppTheme.accentDark,
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        preset['hint']!,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 12),

                    // Custom URL Field
                    const Text(
                      'API BASE URL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _urlCtrl,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        hintText: 'http://10.106.1.72:8000/api/v1',
                        prefixIcon: const Icon(Icons.link, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => _urlCtrl.clear(),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppTheme.accent,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Auto-Detect & Test Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                (_isTesting || _isAutoDetecting) ? null : _runAutoDetect,
                            icon: _isAutoDetecting
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.search, size: 16),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _isAutoDetecting ? 'Scanning...' : 'Auto-Detect',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: const BorderSide(color: AppTheme.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                (_isTesting || _isAutoDetecting) ? null : () => _runTest(),
                            icon: _isTesting
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.speed, size: 16),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _isTesting ? 'Testing...' : 'Test Connection',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Test Results Banner
                    if (_testResult != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _testResult!['success'] == true
                              ? AppTheme.successSoft
                              : AppTheme.dangerSoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _testResult!['success'] == true
                                ? AppTheme.success.withValues(alpha: 0.4)
                                : AppTheme.danger.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _testResult!['success'] == true
                                  ? Icons.check_circle
                                  : Icons.error_outline,
                              color: _testResult!['success'] == true
                                  ? AppTheme.success
                                  : AppTheme.danger,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _testResult!['message'] ?? '',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: _testResult!['success'] == true
                                      ? AppTheme.success
                                      : AppTheme.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Help instructions box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 14, color: AppTheme.textMuted),
                              SizedBox(width: 6),
                              Text(
                                'CONNECTION CHECKLIST',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            '• USB: Ensure device is plugged in & run:\n  "adb reverse tcp:8000 tcp:8000"\n'
                            '• Wi-Fi: Run server with:\n  "py manage.py runserver 0.0.0.0:8000"',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textDark,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _saveAndClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save & Apply',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
