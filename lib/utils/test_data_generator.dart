// This file contains utilities for testing and development
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'dart:math';

class TestDataGenerator {
  static final DatabaseReference monitoringRef = 
      FirebaseDatabase.instance.ref().child('monitoring');
  
  static Timer? _timer;

  // Start generating test data
  static void startGeneratingData() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _generateAndSendTestData();
    });
  }

  // Stop generating test data
  static void stopGeneratingData() {
    _timer?.cancel();
    _timer = null;
  }

  static void _generateAndSendTestData() {
    final random = Random();
    
    // Generate realistic test values
    final coPpm = (random.nextDouble() * 150).toDouble(); // 0-150 PPM
    final dustDensity = (random.nextDouble() * 100).toDouble(); // 0-100 mg/m³
    final temperature = 20 + (random.nextDouble() * 20); // 20-40 °C
    final humidity = 30 + (random.nextDouble() * 50); // 30-80 %
    
    final testData = {
      'co_ppm': coPpm,
      'dust_density': dustDensity,
      'temperature': temperature,
      'humidity': humidity,
      'last_updated': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };
    
    monitoringRef.set(testData).catchError((error) {
      print('Error sending test data: $error');
    });
  }
}