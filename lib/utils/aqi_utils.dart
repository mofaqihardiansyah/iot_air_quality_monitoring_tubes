import 'package:flutter/material.dart';
import '../models/sensor_data.dart';

// Definisi 4 Level Status Kualitas Udara sesuai Teori
enum AQIStatus {
  good,       // Baik
  moderate,   // Sedang
  unhealthy,  // Tidak Sehat
  hazardous,  // Berbahaya
}

class AQIUtils {
  /// Menentukan status AQI berdasarkan nilai tertinggi dari CO atau Debu
  /// Mengacu pada Kalibrasi Sensor GP2Y1010AU0F dan MQ2
  static AQIStatus getAQIStatus(SensorData data) {
    // 1. Cek Kategori Berbahaya (Prioritas Tertinggi)
    if (data.coPpm > 200 || data.dustDensity > 0.30) {
      return AQIStatus.hazardous;
    }
    
    // 2. Cek Kategori Tidak Sehat
    if (data.coPpm > 100 || data.dustDensity > 0.15) {
      return AQIStatus.unhealthy;
    }

    // 3. Cek Kategori Sedang
    if (data.coPpm > 50 || data.dustDensity > 0.08) {
      return AQIStatus.moderate;
    }

    // 4. Jika semua aman
    return AQIStatus.good;
  }

  /// Warna Indikator Dashboard
  static Color getStatusColor(AQIStatus status) {
    switch (status) {
      case AQIStatus.good:
        return Colors.green;        // Aman
      case AQIStatus.moderate:
        return Colors.yellow[700]!; // Kuning gelap agar terbaca di background putih
      case AQIStatus.unhealthy:
        return Colors.orange;       // Waspada
      case AQIStatus.hazardous:
        return Colors.red[900]!;    // Merah Tua/Hitam
    }
  }

  /// Teks Status untuk UI
  static String getStatusText(AQIStatus status) {
    switch (status) {
      case AQIStatus.good:
        return "Good (Baik)";
      case AQIStatus.moderate:
        return "Moderate (Sedang)";
      case AQIStatus.unhealthy:
        return "Unhealthy (Tidak Sehat)";
      case AQIStatus.hazardous:
        return "HAZARDOUS (BERBAHAYA)";
    }
  }

  /// Rekomendasi Kesehatan
  static String getHealthMessage(AQIStatus status) {
    switch (status) {
      case AQIStatus.good:
        return "Udara bersih. Aman untuk beraktivitas.";
      case AQIStatus.moderate:
        return "Kelompok sensitif sebaiknya kurangi aktivitas luar.";
      case AQIStatus.unhealthy:
        return "Gunakan masker! Hindari aktivitas di luar ruangan.";
      case AQIStatus.hazardous:
        return "BAHAYA! Segera menjauh dari area ini.";
    }
  }
}