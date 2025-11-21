import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import '../models/sensor_data.dart';

class MonitoringService {
  final DatabaseReference _monitoringRef =
      FirebaseDatabase.instance.ref().child('monitoring');

  // Stream to listen to monitoring data
  Stream<SensorData> getMonitoringStream() {
    return _monitoringRef.onValue.map((event) {
      final snapshot = event.snapshot;
      if (snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        // Convert keys to string to match expected format
        final stringData = <String, dynamic>{};
        data.forEach((key, value) {
          stringData[key.toString()] = value;
        });
        return SensorData.fromMap(stringData);
      } else {
        // Return default values if no data
        return SensorData(
          coPpm: 0.0,
          dustDensity: 0.0,
          temperature: 0.0,
          humidity: 0.0,
          timestamp: null,
        );
      }
    });
  }

  // Get a single data snapshot
  Future<SensorData> getMonitoringData() async {
    final snapshot = await _monitoringRef.get();
    if (snapshot.value != null) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      final stringData = <String, dynamic>{};
      data.forEach((key, value) {
        stringData[key.toString()] = value;
      });
      return SensorData.fromMap(stringData);
    } else {
      return SensorData(
        coPpm: 0.0,
        dustDensity: 0.0,
        temperature: 0.0,
        humidity: 0.0,
        timestamp: null,
      );
    }
  }

  // Update monitoring data with timestamp
  Future<void> updateMonitoringData({
    required double coPpm,
    required double dustDensity,
    required double temperature,
    required double humidity,
  }) async {
    await _monitoringRef.update({
      'co_ppm': coPpm,
      'dust_density': dustDensity,
      'temperature': temperature,
      'humidity': humidity,
      'last_updated': ServerValue.timestamp,
    });
  }
}