import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  Future<void> _logout() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      isDestructive: true,
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  Future<void> _resetApp() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Reset App',
      message: 'This will clear all data including server settings. Are you sure?',
      confirmText: 'Reset',
      isDestructive: true,
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).resetApp();
      if (mounted) {
        context.go('/server-setup');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final serverConfig = authState.serverConfig;
    final isDarkMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // User Info Section
          if (user != null) ...[
            Container(
              padding: EdgeInsets.all(16.w),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32.r,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user.displayName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          user.username,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],

          SizedBox(height: 16.h),

          // Server Settings Section
          _SectionHeader(title: 'Server'),
          Card(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dns_outlined),
                  title: const Text('Server URL'),
                  subtitle: Text(
                    serverConfig?.serverUrl ?? 'Not configured',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storage_outlined),
                  title: const Text('Database'),
                  subtitle: Text(
                    serverConfig?.database ?? 'Not configured',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Change Server'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/server-setup'),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // Appearance Section
          _SectionHeader(title: 'Appearance'),
          Card(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            child: SwitchListTile(
              secondary: Icon(
                isDarkMode ? Icons.dark_mode : Icons.light_mode,
              ),
              title: const Text('Dark Mode'),
              subtitle: Text(
                isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
                style: TextStyle(fontSize: 12.sp),
              ),
              value: isDarkMode,
              onChanged: (value) {
                ref.read(themeProvider.notifier).setDarkMode(value);
              },
            ),
          ),

          SizedBox(height: 24.h),

          // About Section
          _SectionHeader(title: 'About'),
          Card(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('App Version'),
                  subtitle: Text(
                    _appVersion.isNotEmpty ? _appVersion : 'Loading...',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.system_update_outlined),
                  title: const Text('Check for Updates'),
                  subtitle: Text(
                    'Get the latest version from GitHub',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/updates'),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // Actions Section
          _SectionHeader(title: 'Account'),
          Card(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.logout, color: AppColors.warning),
                  title: Text(
                    'Logout',
                    style: TextStyle(color: AppColors.warning),
                  ),
                  onTap: _logout,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: AppColors.error),
                  title: Text(
                    'Reset App',
                    style: TextStyle(color: AppColors.error),
                  ),
                  subtitle: Text(
                    'Clear all data and settings',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  onTap: _resetApp,
                ),
              ],
            ),
          ),

          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
