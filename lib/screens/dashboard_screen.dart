import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iot_air_quality_monitoring/services/auth_service.dart';
import 'package:iot_air_quality_monitoring/services/monitoring_service.dart';
import 'package:iot_air_quality_monitoring/utils/aqi_utils.dart';
import 'package:iot_air_quality_monitoring/models/sensor_data.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MonitoringService _monitoringService = MonitoringService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Air Quality Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'history',
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('History'),
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'history') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryScreen()),
                );
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              } else if (value == 'logout') {
                _handleLogout();
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<SensorData>(
        stream: _monitoringService.getMonitoringStream(),
        builder: (context, snapshot) {
          // Add a timeout for the initial loading state
          if (snapshot.connectionState == ConnectionState.waiting ||
              (snapshot.connectionState == ConnectionState.active && !snapshot.hasData)) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Loading air quality data...'),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Refresh the page by rebuilding the widget
                      setState(() {});
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.data_usage_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No data available', textAlign: TextAlign.center),
                ],
              ),
            );
          }

          final sensorData = snapshot.data!;
          final aqiStatus = AQIUtils.getAQIStatus(sensorData);
          final statusColor = AQIUtils.getStatusColor(aqiStatus);
          final statusText = AQIUtils.getStatusText(aqiStatus);
          final healthMessage = AQIUtils.getHealthMessage(aqiStatus);

          String lastUpdatedText = '';
          if (sensorData.timestamp != null && sensorData.timestamp! > 0) {
            final dateTime = DateTime.fromMillisecondsSinceEpoch(sensorData.timestamp! * 1000);
            lastUpdatedText = 'Last updated: ${DateFormat('MMM dd, yyyy - HH:mm:ss').format(dateTime)}';
          } else {
            lastUpdatedText = 'Last updated: --:--:--';
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: statusColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          aqiStatus == AQIStatus.warning
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_rounded,
                          color: statusColor,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      healthMessage,
                      style: TextStyle(
                        fontSize: 16,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lastUpdatedText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20.0,
                    mainAxisSpacing: 20.0,
                    children: [
                      _buildSensorCard('CO (PPM)', sensorData.coPpm.toStringAsFixed(2),
                          sensorData.coPpm > 100 ? Colors.red : Colors.blue),
                      _buildSensorCard('Dust (mg/m³)', sensorData.dustDensity.toStringAsFixed(2),
                          sensorData.dustDensity > 75 ? Colors.red : Colors.brown),
                      _buildSensorCard('Temperature (°C)', sensorData.temperature.toStringAsFixed(1), Colors.orange),
                      _buildSensorCard('Humidity (%)', sensorData.humidity.toStringAsFixed(1), Colors.cyan),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSensorCard(String title, String value, Color color) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}