class SensorData {
  final double coPpm; // Carbon Monoxide in PPM
  final double dustDensity; // Dust density in mg/m³
  final double temperature; // Temperature in Celsius
  final double humidity; // Humidity in percentage
  final int?
  timestamp; // Timestamp in seconds (optional for backward compatibility)

  SensorData({
    required this.coPpm,
    required this.dustDensity,
    required this.temperature,
    required this.humidity,
    this.timestamp,
  });

  factory SensorData.fromMap(Map<String, dynamic> map) {
    return SensorData(
      coPpm: (map['co_ppm'] ?? 0.0).toDouble(),
      dustDensity: (map['dust_density'] ?? 0.0).toDouble(),
      temperature: (map['temperature'] ?? 0.0).toDouble(),
      humidity: (map['humidity'] ?? 0.0).toDouble(),
      timestamp: (map['last_updated'] ?? map['timestamp'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'co_ppm': coPpm,
      'dust_density': dustDensity,
      'temperature': temperature,
      'humidity': humidity,
      if (timestamp != null) 'last_updated': timestamp,
    };
  }

  @override
  String toString() {
    return 'SensorData(coPpm: $coPpm, dustDensity: $dustDensity, temperature: $temperature, humidity: $humidity, timestamp: $timestamp)';
  }
}
