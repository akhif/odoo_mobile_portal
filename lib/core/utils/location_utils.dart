import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/app_constants.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final double accuracy;
  final bool isMockLocation;
  final DateTime timestamp;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.isMockLocation,
    required this.timestamp,
  });

  bool get isAccurate => accuracy <= AppConstants.minGpsAccuracy;
  bool get isValid => isAccurate && !isMockLocation;
}

class LocationUtils {
  // Check and request location permissions
  static Future<bool> checkAndRequestPermission() async {
    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check permission status
    var status = await Permission.location.status;

    if (status.isDenied) {
      status = await Permission.location.request();
    }

    if (status.isPermanentlyDenied) {
      // Open app settings
      await openAppSettings();
      return false;
    }

    return status.isGranted;
  }

  // Get current location
  static Future<LocationResult?> getCurrentLocation() async {
    final hasPermission = await checkAndRequestPermission();
    if (!hasPermission) {
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        isMockLocation: position.isMocked,
        timestamp: position.timestamp,
      );
    } catch (e) {
      return null;
    }
  }

  // Get last known location (faster but less accurate)
  static Future<LocationResult?> getLastKnownLocation() async {
    final hasPermission = await checkAndRequestPermission();
    if (!hasPermission) {
      return null;
    }

    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        isMockLocation: position.isMocked,
        timestamp: position.timestamp,
      );
    } catch (e) {
      return null;
    }
  }

  // Validate location for attendance
  static LocationValidation validateForAttendance(LocationResult? location) {
    if (location == null) {
      return LocationValidation(
        isValid: false,
        message: 'Unable to get location. Please enable GPS.',
      );
    }

    if (location.isMockLocation) {
      return LocationValidation(
        isValid: false,
        message: 'Mock location detected. Please disable fake GPS apps.',
      );
    }

    if (!location.isAccurate) {
      return LocationValidation(
        isValid: false,
        message: 'GPS accuracy is too low (${location.accuracy.toStringAsFixed(0)}m). Please move to an open area.',
      );
    }

    return LocationValidation(
      isValid: true,
      message: 'Location verified',
      location: location,
    );
  }

  // Calculate distance between two points (in meters)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Check if within radius of a point
  static bool isWithinRadius(
    LocationResult location,
    double targetLat,
    double targetLon,
    double radiusMeters,
  ) {
    final distance = calculateDistance(
      location.latitude,
      location.longitude,
      targetLat,
      targetLon,
    );
    return distance <= radiusMeters;
  }

  // Open location settings
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // Open app settings (for permissions)
  static Future<void> openPermissionSettings() async {
    await openAppSettings();
  }
}

class LocationValidation {
  final bool isValid;
  final String message;
  final LocationResult? location;

  LocationValidation({
    required this.isValid,
    required this.message,
    this.location,
  });
}
