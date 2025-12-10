import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'dart:developer' as dev;
import '../models/historical_data.dart';

class HistoricalDataService {
  DatabaseReference get _historyRef => FirebaseDatabase.instance.ref().child('history');

  // Get historical data as a stream
  Stream<List<HistoricalData>> getHistoryStream() {
    // Use onValue without limits first to ensure stream stays alive
    return _historyRef.onValue.map((event) {
      final snapshot = event.snapshot;
      dev.log('📊 History snapshot received - exists: ${snapshot.exists}, value: ${snapshot.value != null}', name: 'HistoricalDataService');
      
      if (snapshot.exists && snapshot.value != null) {
        try {
          final List<HistoricalData> historyList = [];
          
          if (snapshot.value is Map) {
            final data = snapshot.value as Map<dynamic, dynamic>;
            dev.log('✅ Processing Map with ${data.length} keys', name: 'HistoricalDataService');
            data.forEach((key, value) {
              if (value is Map) {
                try {
                  historyList.add(HistoricalData.fromMap(key.toString(), value));
                } catch (e) {
                  dev.log('⚠️ Failed to parse item $key: $e', name: 'HistoricalDataService');
                }
              }
            });
          } else if (snapshot.value is List) {
            final data = snapshot.value as List<dynamic>;
            dev.log('✅ Processing List with ${data.length} items', name: 'HistoricalDataService');
            for (var i = 0; i < data.length; i++) {
              if (data[i] is Map) {
                try {
                  historyList.add(HistoricalData.fromMap(i.toString(), data[i] as Map<dynamic, dynamic>));
                } catch (e) {
                  dev.log('⚠️ Failed to parse item $i: $e', name: 'HistoricalDataService');
                }
              }
            }
          } else {
            dev.log('❌ Unexpected data type: ${snapshot.value.runtimeType}', name: 'HistoricalDataService');
          }

          // Sort and limit
          historyList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          final limitedList = historyList.take(100).toList();
          dev.log('✅ Returning ${limitedList.length} history items', name: 'HistoricalDataService');
          return limitedList;
        } catch (e, stack) {
          dev.log('❌ Error parsing: $e\n$stack', name: 'HistoricalDataService');
          return <HistoricalData>[];
        }
      } else {
        dev.log('⚠️ Snapshot empty or null', name: 'HistoricalDataService');
        return <HistoricalData>[];
      }
    });
  }

  // Get a single snapshot of historical data
  Future<List<HistoricalData>> getHistoryData() async {
    try {
      final snapshot = await _historyRef.orderByKey().limitToLast(50).get();
      final List<HistoricalData> historyList = [];

      if (snapshot.value != null) {
        if (snapshot.value is Map) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          data.forEach((key, value) {
            if (value is Map) {
              historyList.add(HistoricalData.fromMap(key.toString(), value));
            }
          });
        } else if (snapshot.value is List) {
          final data = snapshot.value as List<dynamic>;
          for (var i = 0; i < data.length; i++) {
            if (data[i] is Map) {
              historyList.add(HistoricalData.fromMap(i.toString(), data[i] as Map<dynamic, dynamic>));
            }
          }
        }
        
        // Sort by timestamp in descending order (newest first)
        historyList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }

      return historyList;
    } catch (e) {
      dev.log('Error getting history data: $e', name: 'HistoricalDataService');
      return <HistoricalData>[];
    }
  }

  // Add new historical data entry
  Future<void> addHistoricalData(HistoricalData historyData) async {
    try {
      await _historyRef.push().set(historyData.toMap());
    } catch (e) {
      dev.log('Error adding historical data: $e', name: 'HistoricalDataService');
      rethrow;
    }
  }

  // Add batch of historical data
  Future<void> addBatchHistoricalData(List<HistoricalData> historyList) async {
    for (final historyData in historyList) {
      await addHistoricalData(historyData);
    }
  }

  // Clear all historical data (useful for testing)
  Future<void> clearAllHistory() async {
    try {
      await _historyRef.remove();
    } catch (e) {
      dev.log('Error clearing history: $e', name: 'HistoricalDataService');
      rethrow;
    }
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
        try {
          final List<HistoricalData> historyList = [];

          if (snapshot.value is Map) {
            final data = snapshot.value as Map<dynamic, dynamic>;
            data.forEach((key, value) {
              if (value is Map) {
                historyList.add(HistoricalData.fromMap(key.toString(), value));
              }
            });
          } else if (snapshot.value is List) {
            final data = snapshot.value as List<dynamic>;
            for (var i = 0; i < data.length; i++) {
              if (data[i] is Map) {
                historyList.add(HistoricalData.fromMap(i.toString(), data[i] as Map<dynamic, dynamic>));
              }
            }
          }

          // Sort by timestamp in descending order (newest first)
          historyList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return historyList;
        } catch (e) {
          dev.log('Error parsing time range historical data: $e', name: 'HistoricalDataService');
          return <HistoricalData>[];
        }
      } else {
        return <HistoricalData>[];
      }
    }).handleError((error) {
      dev.log('Error in history stream by time range: $error', name: 'HistoricalDataService');
      return <HistoricalData>[];
    }) as Stream<List<HistoricalData>>;
  }
}