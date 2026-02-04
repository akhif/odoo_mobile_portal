import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/location_utils.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../providers/hr_provider.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _isGettingLocation = false;
  LocationResult? _currentLocation;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _getLocation();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      // Default to front camera if available
      _currentCameraIndex = _cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      if (_currentCameraIndex == -1) _currentCameraIndex = 0;

      await _setupCamera(_cameras[_currentCameraIndex]);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _setupCamera(CameraDescription camera) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    setState(() {
      _isCameraInitialized = false;
    });

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();

    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    await _setupCamera(_cameras[_currentCameraIndex]);
  }

  Future<void> _getLocation() async {
    setState(() {
      _isGettingLocation = true;
      _locationError = null;
    });

    final location = await LocationUtils.getCurrentLocation();

    if (mounted) {
      if (location == null) {
        setState(() {
          _isGettingLocation = false;
          _locationError = 'Unable to get location. Please enable GPS and grant location permission.';
        });
      } else {
        final validation = LocationUtils.validateForAttendance(location);
        setState(() {
          _isGettingLocation = false;
          _currentLocation = location;
          _locationError = validation.isValid ? null : validation.message;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _captureAndSubmit(bool isCheckOut) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera not ready')),
      );
      return;
    }

    if (_currentLocation == null || _locationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_locationError ?? 'Location not available')),
      );
      return;
    }

    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: isCheckOut ? 'Check Out' : 'Check In',
      message: 'Are you sure you want to ${isCheckOut ? 'check out' : 'check in'}?',
      confirmText: isCheckOut ? 'Check Out' : 'Check In',
    );

    if (confirmed != true) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      // Capture photo
      final XFile photo = await _cameraController!.takePicture();
      final Uint8List photoBytes = await photo.readAsBytes();

      // Submit attendance
      final notifier = ref.read(attendanceNotifierProvider.notifier);
      bool success;

      if (isCheckOut) {
        success = await notifier.checkOut(
          latitude: _currentLocation!.latitude,
          longitude: _currentLocation!.longitude,
          accuracy: _currentLocation!.accuracy,
          photo: photoBytes,
          deviceInfo: 'Flutter App',
          isMockLocation: _currentLocation!.isMockLocation,
        );
      } else {
        success = await notifier.checkIn(
          latitude: _currentLocation!.latitude,
          longitude: _currentLocation!.longitude,
          accuracy: _currentLocation!.accuracy,
          photo: photoBytes,
          deviceInfo: 'Flutter App',
          isMockLocation: _currentLocation!.isMockLocation,
        );
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${isCheckOut ? 'Check out' : 'Check in'} successful'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.refresh(currentAttendanceProvider);
        ref.refresh(attendanceHistoryProvider);
      } else if (mounted) {
        final state = ref.read(attendanceNotifierProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error ?? 'Failed to record attendance'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAttendanceAsync = ref.watch(currentAttendanceProvider);
    final attendanceHistoryAsync = ref.watch(attendanceHistoryProvider);
    final attendanceState = ref.watch(attendanceNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote Attendance'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Camera Preview
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    // Camera with switch button
                    Stack(
                      children: [
                        Container(
                          height: 250.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: _isCameraInitialized && _cameraController != null
                                ? CameraPreview(_cameraController!)
                                : const Center(
                                    child: CircularProgressIndicator(color: Colors.white),
                                  ),
                          ),
                        ),
                        // Camera switch button
                        if (_cameras.length > 1)
                          Positioned(
                            top: 8.h,
                            right: 8.w,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.cameraswitch,
                                  color: Colors.white,
                                  size: 24.sp,
                                ),
                                onPressed: _switchCamera,
                                tooltip: 'Switch Camera',
                              ),
                            ),
                          ),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    // Location Status
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: _isGettingLocation
                            ? AppColors.info.withOpacity(0.1)
                            : _locationError != null
                                ? AppColors.error.withOpacity(0.1)
                                : AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          if (_isGettingLocation)
                            SizedBox(
                              width: 20.sp,
                              height: 20.sp,
                              child: const CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Icon(
                              _locationError != null ? Icons.location_off : Icons.location_on,
                              color: _locationError != null ? AppColors.error : AppColors.success,
                              size: 20.sp,
                            ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _isGettingLocation
                                ? Text(
                                    'Getting location...',
                                    style: TextStyle(fontSize: 14.sp),
                                  )
                                : _currentLocation != null && _locationError == null
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Location Verified',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.success,
                                            ),
                                          ),
                                          Text(
                                            'Accuracy: ${_currentLocation!.accuracy.toStringAsFixed(0)}m',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: AppColors.success,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _locationError ?? 'Location unavailable',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              color: AppColors.error,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          GestureDetector(
                                            onTap: () => LocationUtils.openLocationSettings(),
                                            child: Text(
                                              'Tap to open GPS settings',
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: AppColors.primary,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _getLocation,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Timestamp
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm:ss').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // Action Buttons
                    currentAttendanceAsync.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => AppButton(
                        text: 'Check In',
                        icon: Icons.login,
                        isLoading: _isCapturing || attendanceState.isLoading,
                        isFullWidth: true,
                        onPressed: _locationError == null ? () => _captureAndSubmit(false) : null,
                      ),
                      data: (current) {
                        if (current != null && !current.isCheckedOut) {
                          return AppButton(
                            text: 'Check Out',
                            icon: Icons.logout,
                            type: AppButtonType.secondary,
                            isLoading: _isCapturing || attendanceState.isLoading,
                            isFullWidth: true,
                            onPressed: _locationError == null ? () => _captureAndSubmit(true) : null,
                          );
                        }
                        return AppButton(
                          text: 'Check In',
                          icon: Icons.login,
                          isLoading: _isCapturing || attendanceState.isLoading,
                          isFullWidth: true,
                          onPressed: _locationError == null ? () => _captureAndSubmit(false) : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Attendance History
            Text(
              'Recent Attendance',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),

            attendanceHistoryAsync.when(
              loading: () => const ListShimmer(itemCount: 3),
              error: (error, _) => AppErrorWidget(
                message: 'Failed to load history',
                onRetry: () => ref.refresh(attendanceHistoryProvider),
              ),
              data: (history) {
                if (history.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No attendance records'),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length > 5 ? 5 : history.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final record = history[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          record.isCheckedOut ? Icons.check_circle : Icons.schedule,
                          color: record.isCheckedOut ? AppColors.success : AppColors.warning,
                        ),
                        title: Text(record.checkInFormatted),
                        subtitle: Text(
                          record.isCheckedOut
                              ? 'Worked: ${record.workedHoursFormatted}'
                              : 'In progress',
                        ),
                        trailing: record.isCheckedOut
                            ? Text(
                                record.checkOutFormatted,
                                style: TextStyle(fontSize: 12.sp),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
