import 'package:iot_air_quality_monitoring/models/sensor_data.dart';

class HistoricalData {
  final String id;
  final double coPpm;
  final double dustDensity;
  final double temperature;
  final double humidity;
  final int timestamp;

  HistoricalData({
    required this.id,
    required this.coPpm,
    required this.dustDensity,
    required this.temperature,
    required this.humidity,
    required this.timestamp,
  });

  factory HistoricalData.fromMap(String id, Map<dynamic, dynamic> map) {
    final stringMap = <String, dynamic>{};
    map.forEach((key, value) {
      stringMap[key.toString()] = value;
    });

    return HistoricalData(
      id: id,
      coPpm: (stringMap['co_ppm'] ?? 0.0).toDouble(),
      dustDensity: (stringMap['dust_density'] ?? 0.0).toDouble(),
      temperature: (stringMap['temperature'] ?? 0.0).toDouble(),
      humidity: (stringMap['humidity'] ?? 0.0).toDouble(),
      timestamp: (stringMap['timestamp'] ?? 0).toInt(),
    );
  }

  // Method to convert HistoricalData to Map for Firebase storage
  Map<String, dynamic> toMap() {
    return {
      'co_ppm': coPpm,
      'dust_density': dustDensity,
      'temperature': temperature,
      'humidity': humidity,
      'timestamp': timestamp,
    };
  }

  // Convert to SensorData for AQI calculations
  SensorData toSensorData() {
    return SensorData(
      coPpm: coPpm,
      dustDensity: dustDensity,
      temperature: temperature,
      humidity: humidity,
    );
  }

  @override
  String toString() {
    return 'HistoricalData(id: $id, coPpm: $coPpm, dustDensity: $dustDensity, temperature: $temperature, humidity: $humidity, timestamp: $timestamp)';
  }
}
