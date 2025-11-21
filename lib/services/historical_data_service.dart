import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import '../models/historical_data.dart';

class HistoricalDataService {
  final DatabaseReference _historyRef = FirebaseDatabase.instance.ref().child('history');

  // Get historical data as a stream
  Stream<List<HistoricalData>> getHistoryStream() {
    return _historyRef.orderByKey().limitToLast(50).onValue.map((event) {
      final snapshot = event.snapshot;
      if (snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final List<HistoricalData> historyList = [];
        
        data.forEach((key, value) {
          if (value != null) {
            historyList.add(HistoricalData.fromMap(key.toString(), value));
          }
        });
        
        // Sort by timestamp in descending order (newest first)
        historyList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return historyList;
      } else {
        return [];
      }
    });
  }

  // Get a single snapshot of historical data
  Future<List<HistoricalData>> getHistoryData() async {
    final snapshot = await _historyRef.orderByKey().limitToLast(50).get();
    final List<HistoricalData> historyList = [];
    
    if (snapshot.value != null) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        if (value != null) {
          historyList.add(HistoricalData.fromMap(key.toString(), value));
        }
      });
      
      // Sort by timestamp in descending order (newest first)
      historyList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    
    return historyList;
  }

  // Add new historical data entry
  Future<void> addHistoricalData(HistoricalData historyData) async {
    await _historyRef.push().set(historyData.toMap());
  }

  // Add batch of historical data
  Future<void> addBatchHistoricalData(List<HistoricalData> historyList) async {
    for (final historyData in historyList) {
      await addHistoricalData(historyData);
    }
  }

  // Clear all historical data (useful for testing)
  Future<void> clearAllHistory() async {
    await _historyRef.remove();
  }

  // Get historical data within a specific time range
  Stream<List<HistoricalData>> getHistoryStreamByTimeRange(int startTime, int endTime) {
    return _historyRef
        .orderByChild('timestamp')
        .startAt(startTime)
        .endAt(endTime)
        .onValue
        .map((event) {
      final snapshot = event.snapshot;
      if (snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final List<HistoricalData> historyList = [];
        
        data.forEach((key, value) {
          if (value != null) {
            historyList.add(HistoricalData.fromMap(key.toString(), value));
          }
        });
        
        // Sort by timestamp in descending order (newest first)
        historyList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return historyList;
      } else {
        return [];
      }
    });
  }
}