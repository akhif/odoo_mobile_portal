import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/auth_provider.dart';

class ServerSetupScreen extends ConsumerStatefulWidget {
  const ServerSetupScreen({super.key});

  @override
  ConsumerState<ServerSetupScreen> createState() => _ServerSetupScreenState();
}

class _ServerSetupScreenState extends ConsumerState<ServerSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  final _databaseController = TextEditingController();

  bool _isLoading = false;
  bool _isTestingConnection = false;
  bool _connectionTested = false;
  String? _errorMessage;
  String? _serverVersion;
  List<String> _availableDatabases = [];

  @override
  void initState() {
    super.initState();
    _loadStoredConfig();
  }

  Future<void> _loadStoredConfig() async {
    final config = ref.read(authProvider).serverConfig;
    if (config != null) {
      _serverUrlController.text = config.serverUrl;
      _databaseController.text = config.database;
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _databaseController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTestingConnection = true;
      _errorMessage = null;
      _connectionTested = false;
      _availableDatabases = [];
    });

    try {
      final serverUrl = _normalizeUrl(_serverUrlController.text.trim());

      // Test connection
      final config = await ref.read(authProvider.notifier).testConnection(serverUrl);

      // Try to get databases
      final databases = await ref.read(authProvider.notifier).getDatabases(serverUrl);

      setState(() {
        _connectionTested = true;
        _serverVersion = config.serverVersion;
        _availableDatabases = databases;
        _serverUrlController.text = serverUrl;
      });

      if (databases.isNotEmpty && _databaseController.text.isEmpty) {
        _databaseController.text = databases.first;
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  String _normalizeUrl(String url) {
    url = url.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    // Remove trailing slash
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_connectionTested) {
      setState(() {
        _errorMessage = 'Please test the connection first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final serverUrl = _normalizeUrl(_serverUrlController.text.trim());
      final database = _databaseController.text.trim();

      await ref.read(authProvider.notifier).saveServerConfig(
            serverUrl: serverUrl,
            database: database,
          );

      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40.h),
                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80.w,
                        height: 80.w,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Icon(
                          Icons.dns_outlined,
                          size: 40.sp,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        'Server Setup',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Configure your Odoo server connection',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 40.h),

                // Server URL
                Text(
                  'Server URL',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _serverUrlController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'https://erp.company.com',
                    prefixIcon: const Icon(Icons.link),
                    suffixIcon: _connectionTested
                        ? Icon(Icons.check_circle, color: AppColors.success)
                        : null,
                  ),
                  validator: Validators.validateUrl,
                  onChanged: (_) {
                    setState(() {
                      _connectionTested = false;
                    });
                  },
                ),
                SizedBox(height: 16.h),

                // Test Connection Button
                AppButton(
                  text: 'Test Connection',
                  type: AppButtonType.outlined,
                  icon: Icons.wifi_find,
                  isLoading: _isTestingConnection,
                  isFullWidth: true,
                  onPressed: _testConnection,
                ),

                // Connection Status
                if (_connectionTested) ...[
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success, size: 20.sp),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Connected to Odoo $_serverVersion',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 24.h),

                // Database
                Text(
                  'Database',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8.h),
                if (_availableDatabases.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _databaseController.text.isNotEmpty &&
                            _availableDatabases.contains(_databaseController.text)
                        ? _databaseController.text
                        : null,
                    decoration: const InputDecoration(
                      hintText: 'Select database',
                      prefixIcon: Icon(Icons.storage),
                    ),
                    items: _availableDatabases.map((db) {
                      return DropdownMenuItem(
                        value: db,
                        child: Text(db),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _databaseController.text = value;
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a database';
                      }
                      return null;
                    },
                  )
                else
                  TextFormField(
                    controller: _databaseController,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: 'Enter database name',
                      prefixIcon: Icon(Icons.storage),
                    ),
                    validator: Validators.validateDatabase,
                  ),

                // Error Message
                if (_errorMessage != null) ...[
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error, size: 20.sp),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 32.h),

                // Continue Button
                AppButton(
                  text: 'Continue to Login',
                  isLoading: _isLoading,
                  isFullWidth: true,
                  onPressed: _connectionTested ? _saveConfig : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
