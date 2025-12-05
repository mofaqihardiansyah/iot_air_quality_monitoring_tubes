import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iot_air_quality_monitoring/services/historical_data_service.dart';
import 'package:iot_air_quality_monitoring/models/historical_data.dart';
import 'package:iot_air_quality_monitoring/utils/aqi_utils.dart';
import '../screens/dashboard_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoricalDataService _historicalService = HistoricalDataService();

  // Helper function to group historical data by 30-minute intervals
  Map<DateTime, List<HistoricalData>> _groupHistoryByInterval(
      List<HistoricalData> historyList) {
    final Map<DateTime, List<HistoricalData>> groupedData = {};

    for (final history in historyList) {
      final timestamp = DateTime.fromMillisecondsSinceEpoch(history.timestamp * 1000);
      final minute = (timestamp.minute / 30).floor() * 30;
      final intervalStart = DateTime(
          timestamp.year, timestamp.month, timestamp.day, timestamp.hour, minute);

      if (groupedData[intervalStart] == null) {
        groupedData[intervalStart] = [];
      }
      groupedData[intervalStart]!.add(history);
    }

    return groupedData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historical Data'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          },
        ),
      ),
      body: StreamBuilder<List<HistoricalData>>(
        stream: _historicalService.getHistoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Refresh the stream
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No historical data available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Past readings will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final groupedHistory = _groupHistoryByInterval(snapshot.data!);
          final sortedKeys = groupedHistory.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {}); // Refresh the stream
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                final intervalStart = sortedKeys[index];
                final historyInInterval = groupedHistory[intervalStart]!;
                final intervalEnd = intervalStart.add(const Duration(minutes: 30));

                // Calculate average for the interval to determine overall status
                final avgCoPpm = historyInInterval.map((h) => h.coPpm).reduce((a, b) => a + b) / historyInInterval.length;
                final avgDustDensity = historyInInterval.map((h) => h.dustDensity).reduce((a, b) => a + b) / historyInInterval.length;
                final avgTemp = historyInInterval.map((h) => h.temperature).reduce((a, b) => a + b) / historyInInterval.length;
                final avgHumidity = historyInInterval.map((h) => h.humidity).reduce((a, b) => a + b) / historyInInterval.length;

                final avgSensorData = HistoricalData(
                  id: '',
                  coPpm: avgCoPpm,
                  dustDensity: avgDustDensity,
                  temperature: avgTemp,
                  humidity: avgHumidity,
                  timestamp: intervalStart.millisecondsSinceEpoch ~/ 1000,
                );

                final aqiStatus = AQIUtils.getAQIStatus(avgSensorData.toSensorData());
                final statusColor = AQIUtils.getStatusColor(aqiStatus);

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    leading: Icon(
                      aqiStatus == AQIStatus.warning ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                      color: statusColor,
                    ),
                    title: Text(
                      '${DateFormat('MMM dd, HH:mm').format(intervalStart)} - ${DateFormat('HH:mm').format(intervalEnd)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      '${historyInInterval.length} readings - Overall Status: ${AQIUtils.getStatusText(aqiStatus)}',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          children: [
                            _buildHistoryDetailRow('Time', 'CO', 'Dust', 'Temp', 'Hum', isHeader: true),
                            const Divider(),
                            ...historyInInterval.map((history) {
                              final timestamp = DateTime.fromMillisecondsSinceEpoch(history.timestamp * 1000);
                              return _buildHistoryDetailRow(
                                DateFormat('HH:mm:ss').format(timestamp),
                                '${history.coPpm.toStringAsFixed(2)}',
                                '${history.dustDensity.toStringAsFixed(2)}',
                                '${history.temperature.toStringAsFixed(1)}°C',
                                '${history.humidity.toStringAsFixed(1)}%',
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryDetailRow(
      String time, String co, String dust, String temp, String hum,
      {bool isHeader = false}) {
    final style = TextStyle(
      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
      fontSize: 12,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(flex: 2, child: Text(time, style: style)),
          Expanded(flex: 2, child: Text(co, style: style, textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text(dust, style: style, textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text(temp, style: style, textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text(hum, style: style, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}
