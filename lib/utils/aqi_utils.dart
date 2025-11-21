import 'package:flutter/material.dart';
import '../models/sensor_data.dart';

enum AQIStatus {
  good,
  warning,
}

class AQIUtils {
  /// Determines the AQI status based on sensor readings
  /// Returns [AQIStatus.warning] if CO > 100 PPM OR Dust > 75 mg/m³
  /// Returns [AQIStatus.good] otherwise
  static AQIStatus getAQIStatus(SensorData sensorData) {
    // Condition A: Carbon Monoxide (CO) > 100 PPM
    bool isCOHigh = sensorData.coPpm > 100.0;
    
    // Condition B: Dust Density > 75 mg/m³
    bool isDustHigh = sensorData.dustDensity > 75.0;

    // If either condition is true, return warning status
    if (isCOHigh || isDustHigh) {
      return AQIStatus.warning;
    }

    return AQIStatus.good;
  }

  /// Returns the appropriate color based on AQI status
  static Color getStatusColor(AQIStatus status) {
    switch (status) {
      case AQIStatus.good:
        return Colors.green;
      case AQIStatus.warning:
        return Colors.red;
    }
  }

  /// Returns status text based on AQI status
  static String getStatusText(AQIStatus status) {
    switch (status) {
      case AQIStatus.good:
        return "Good";
      case AQIStatus.warning:
        return "Warning / Unhealthy";
    }
  }

  /// Returns health message based on AQI status
  static String getHealthMessage(AQIStatus status) {
    switch (status) {
      case AQIStatus.good:
        return "Air quality is safe.";
      case AQIStatus.warning:
        return "Wear a mask, Avoid outdoor activities.";
    }
  }
}