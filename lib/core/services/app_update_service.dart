import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class AppUpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final bool updateAvailable;
  final String? downloadUrl;
  final String? releaseNotes;
  final String? releaseName;
  final DateTime? releaseDate;

  AppUpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.updateAvailable,
    this.downloadUrl,
    this.releaseNotes,
    this.releaseName,
    this.releaseDate,
  });
}

class DownloadProgress {
  final int received;
  final int total;
  final double progress;

  DownloadProgress({
    required this.received,
    required this.total,
  }) : progress = total > 0 ? received / total : 0;
}

class AppUpdateService {
  static const String _repoOwner = 'akhif';
  static const String _repoName = 'odoo_mobile_portal';
  static const String _githubApiUrl = 'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  final Dio _dio = Dio();

  Future<AppUpdateInfo> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (kDebugMode) {
        debugPrint('Current app version: $currentVersion');
      }

      final response = await _dio.get(
        _githubApiUrl,
        options: Options(
          headers: {
            'Accept': 'application/vnd.github.v3+json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final tagName = data['tag_name'] as String? ?? '';
        final latestVersion = tagName.replaceAll('v', '');

        if (kDebugMode) {
          debugPrint('Latest GitHub version: $latestVersion');
        }

        // Find APK asset
        String? downloadUrl;
        final assets = data['assets'] as List<dynamic>? ?? [];
        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name.endsWith('.apk')) {
            downloadUrl = asset['browser_download_url'] as String?;
            break;
          }
        }

        final updateAvailable = _isNewerVersion(latestVersion, currentVersion);

        return AppUpdateInfo(
          latestVersion: latestVersion,
          currentVersion: currentVersion,
          updateAvailable: updateAvailable,
          downloadUrl: downloadUrl,
          releaseNotes: data['body'] as String?,
          releaseName: data['name'] as String?,
          releaseDate: data['published_at'] != null
              ? DateTime.tryParse(data['published_at'] as String)
              : null,
        );
      }

      throw Exception('Failed to check for updates');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking for updates: $e');
      }

      final packageInfo = await PackageInfo.fromPlatform();
      return AppUpdateInfo(
        latestVersion: 'Unknown',
        currentVersion: packageInfo.version,
        updateAvailable: false,
      );
    }
  }

  bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      // Pad shorter list with zeros
      while (latestParts.length < 3) latestParts.add(0);
      while (currentParts.length < 3) currentParts.add(0);

      for (int i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<File?> downloadUpdate(
    String url, {
    Function(DownloadProgress)? onProgress,
  }) async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Could not access storage');
      }

      final filePath = '${directory.path}/odoo_portal_update.apk';
      final file = File(filePath);

      // Delete existing file if present
      if (await file.exists()) {
        await file.delete();
      }

      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (onProgress != null) {
            onProgress(DownloadProgress(received: received, total: total));
          }
        },
      );

      return file;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error downloading update: $e');
      }
      return null;
    }
  }

  Future<bool> installUpdate(File apkFile) async {
    try {
      final result = await OpenFilex.open(apkFile.path);
      return result.type == ResultType.done;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error installing update: $e');
      }
      return false;
    }
  }
}
