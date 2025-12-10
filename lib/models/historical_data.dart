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

    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return num.tryParse(value)?.toInt() ?? 0;
      return 0;
    }

    return HistoricalData(
      id: id,
      coPpm: parseDouble(stringMap['co_ppm']),
      dustDensity: parseDouble(stringMap['dust_density']),
      temperature: parseDouble(stringMap['temperature']),
      humidity: parseDouble(stringMap['humidity']),
      timestamp: parseInt(stringMap['timestamp']),
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
