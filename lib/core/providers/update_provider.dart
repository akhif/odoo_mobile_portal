import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/app_update_service.dart';

// Service provider
final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService();
});

// Update info provider
final updateInfoProvider = FutureProvider.autoDispose<AppUpdateInfo>((ref) async {
  final service = ref.watch(appUpdateServiceProvider);
  return await service.checkForUpdates();
});

// Update state
class UpdateState {
  final bool isChecking;
  final bool isDownloading;
  final bool isInstalling;
  final double downloadProgress;
  final String? error;
  final AppUpdateInfo? updateInfo;
  final File? downloadedFile;

  const UpdateState({
    this.isChecking = false,
    this.isDownloading = false,
    this.isInstalling = false,
    this.downloadProgress = 0,
    this.error,
    this.updateInfo,
    this.downloadedFile,
  });

  UpdateState copyWith({
    bool? isChecking,
    bool? isDownloading,
    bool? isInstalling,
    double? downloadProgress,
    String? error,
    AppUpdateInfo? updateInfo,
    File? downloadedFile,
  }) {
    return UpdateState(
      isChecking: isChecking ?? this.isChecking,
      isDownloading: isDownloading ?? this.isDownloading,
      isInstalling: isInstalling ?? this.isInstalling,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      error: error,
      updateInfo: updateInfo ?? this.updateInfo,
      downloadedFile: downloadedFile ?? this.downloadedFile,
    );
  }
}

class UpdateNotifier extends StateNotifier<UpdateState> {
  final AppUpdateService _service;

  UpdateNotifier(this._service) : super(const UpdateState());

  Future<void> checkForUpdates() async {
    state = state.copyWith(isChecking: true, error: null);

    try {
      final updateInfo = await _service.checkForUpdates();
      state = state.copyWith(
        isChecking: false,
        updateInfo: updateInfo,
      );
    } catch (e) {
      state = state.copyWith(
        isChecking: false,
        error: e.toString(),
      );
    }
  }

  Future<void> downloadAndInstall() async {
    final updateInfo = state.updateInfo;
    if (updateInfo == null || updateInfo.downloadUrl == null) {
      state = state.copyWith(error: 'No download URL available');
      return;
    }

    state = state.copyWith(isDownloading: true, downloadProgress: 0, error: null);

    try {
      final file = await _service.downloadUpdate(
        updateInfo.downloadUrl!,
        onProgress: (progress) {
          state = state.copyWith(downloadProgress: progress.progress);
        },
      );

      if (file == null) {
        state = state.copyWith(
          isDownloading: false,
          error: 'Failed to download update',
        );
        return;
      }

      state = state.copyWith(
        isDownloading: false,
        isInstalling: true,
        downloadedFile: file,
      );

      final installed = await _service.installUpdate(file);

      state = state.copyWith(
        isInstalling: false,
        error: installed ? null : 'Failed to open installer',
      );
    } catch (e) {
      state = state.copyWith(
        isDownloading: false,
        isInstalling: false,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = const UpdateState();
  }
}

final updateNotifierProvider = StateNotifierProvider<UpdateNotifier, UpdateState>((ref) {
  final service = ref.watch(appUpdateServiceProvider);
  return UpdateNotifier(service);
});
