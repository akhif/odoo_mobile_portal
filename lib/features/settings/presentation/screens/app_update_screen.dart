import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/update_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';

class AppUpdateScreen extends ConsumerStatefulWidget {
  const AppUpdateScreen({super.key});

  @override
  ConsumerState<AppUpdateScreen> createState() => _AppUpdateScreenState();
}

class _AppUpdateScreenState extends ConsumerState<AppUpdateScreen> {
  @override
  void initState() {
    super.initState();
    // Check for updates when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(updateNotifierProvider.notifier).checkForUpdates();
    });
  }

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(updateNotifierProvider);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Updates'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Version Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.phone_android,
                        color: AppColors.primary,
                        size: 32.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Version',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            updateState.updateInfo?.currentVersion ?? 'Loading...',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Update Status
            if (updateState.isChecking) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        SizedBox(height: 16.h),
                        Text(
                          'Checking for updates...',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else if (updateState.error != null) ...[
              Card(
                color: AppColors.error.withOpacity(0.1),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          updateState.error!,
                          style: TextStyle(color: AppColors.error, fontSize: 14.sp),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              AppButton(
                text: 'Retry',
                onPressed: () => ref.read(updateNotifierProvider.notifier).checkForUpdates(),
                isFullWidth: true,
              ),
            ] else if (updateState.updateInfo != null) ...[
              if (updateState.updateInfo!.updateAvailable) ...[
                // Update Available Card
                Card(
                  color: AppColors.success.withOpacity(0.1),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.system_update, color: AppColors.success, size: 24.sp),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'Update Available!',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        _InfoRow(
                          label: 'Latest Version',
                          value: updateState.updateInfo!.latestVersion,
                        ),
                        if (updateState.updateInfo!.releaseName != null) ...[
                          SizedBox(height: 8.h),
                          _InfoRow(
                            label: 'Release',
                            value: updateState.updateInfo!.releaseName!,
                          ),
                        ],
                        if (updateState.updateInfo!.releaseDate != null) ...[
                          SizedBox(height: 8.h),
                          _InfoRow(
                            label: 'Released',
                            value: dateFormat.format(updateState.updateInfo!.releaseDate!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Release Notes
                if (updateState.updateInfo!.releaseNotes != null &&
                    updateState.updateInfo!.releaseNotes!.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Release Notes',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            updateState.updateInfo!.releaseNotes!,
                            style: TextStyle(fontSize: 13.sp, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                SizedBox(height: 24.h),

                // Download Progress
                if (updateState.isDownloading) ...[
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        children: [
                          Text(
                            'Downloading update...',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                          SizedBox(height: 12.h),
                          LinearProgressIndicator(value: updateState.downloadProgress),
                          SizedBox(height: 8.h),
                          Text(
                            '${(updateState.downloadProgress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (updateState.isInstalling) ...[
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Center(
                        child: Column(
                          children: [
                            const CircularProgressIndicator(),
                            SizedBox(height: 16.h),
                            Text(
                              'Opening installer...',
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  AppButton(
                    text: 'Download & Install Update',
                    icon: Icons.download,
                    onPressed: () => ref.read(updateNotifierProvider.notifier).downloadAndInstall(),
                    isFullWidth: true,
                  ),
                ],
              ] else ...[
                // No Update Available
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 48.sp,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'You\'re up to date!',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Version ${updateState.updateInfo!.currentVersion} is the latest version.',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],

            SizedBox(height: 24.h),

            // Check for Updates Button (when not checking or downloading)
            if (!updateState.isChecking && !updateState.isDownloading && !updateState.isInstalling)
              Center(
                child: TextButton.icon(
                  onPressed: () => ref.read(updateNotifierProvider.notifier).checkForUpdates(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Check Again'),
                ),
              ),

            SizedBox(height: 16.h),

            // GitHub Link
            Center(
              child: TextButton.icon(
                onPressed: () {
                  // Could open browser to releases page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Visit: github.com/akhif/odoo_mobile_portal/releases'),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('View on GitHub'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
