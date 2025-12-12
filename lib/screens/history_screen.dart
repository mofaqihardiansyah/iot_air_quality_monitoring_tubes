import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iot_air_quality_monitoring/services/historical_data_service.dart';
import 'package:iot_air_quality_monitoring/models/historical_data.dart';
import 'package:iot_air_quality_monitoring/utils/aqi_utils.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoricalDataService _historicalService = HistoricalDataService();
  
  // Filter state
  AQIStatus? _selectedStatus; // null = All
  DateTime _selectedDate = DateTime.now();

  // Filter helper function
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Filter data based on selected filters
  List<HistoricalData> _filterData(List<HistoricalData> allData) {
    return allData.where((item) {
      final itemDateTime = DateTime.fromMillisecondsSinceEpoch(item.timestamp * 1000);
      
      // Date filter
      if (!_isSameDay(itemDateTime, _selectedDate)) {
        return false;
      }
      
      // Status filter
      if (_selectedStatus != null) {
        final itemStatus = AQIUtils.getAQIStatus(item.toSensorData());
        if (itemStatus != _selectedStatus) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  // Show date picker dialog
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historical Data'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Filter
                const Text(
                  'Filter by Status:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusChip('All', null),
                      const SizedBox(width: 8),
                      _buildStatusChip('Good', AQIStatus.good),
                      const SizedBox(width: 8),
                      _buildStatusChip('Moderate', AQIStatus.moderate),
                      const SizedBox(width: 8),
                      _buildStatusChip('Unhealthy', AQIStatus.unhealthy),
                      const SizedBox(width: 8),
                      _buildStatusChip('Hazardous', AQIStatus.hazardous),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Date Filter
                const Text(
                  'Filter by Date:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today, size: 18, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          _isSameDay(_selectedDate, DateTime.now())
                              ? 'Hari Ini'
                              : DateFormat('dd MMM yyyy').format(_selectedDate),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // History List
          Expanded(
            child: StreamBuilder<List<HistoricalData>>(
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
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No historical data available',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Apply filters
                final filteredData = _filterData(snapshot.data!);
                
                // Sort by newest first
                filteredData.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                if (filteredData.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.filter_alt_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No data matches the selected filters',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedStatus = null;
                              _selectedDate = DateTime.now();
                            });
                          },
                          child: const Text('Reset Filters'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final data = filteredData[index];
                      final sensorData = data.toSensorData();
                      final status = AQIUtils.getAQIStatus(sensorData);
                      final statusColor = AQIUtils.getStatusColor(status);
                      final statusText = AQIUtils.getStatusText(status);
                      final timestamp = DateTime.fromMillisecondsSinceEpoch(data.timestamp * 1000);

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: statusColor.withOpacity(0.3), width: 2),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                statusColor.withOpacity(0.05),
                                statusColor.withOpacity(0.15),
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status header
                              Row(
                                children: [
                                  Icon(
                                    (status == AQIStatus.hazardous || status == AQIStatus.unhealthy)
                                        ? Icons.warning_amber_rounded
                                        : Icons.check_circle_rounded,
                                    color: statusColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Timestamp
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('dd MMM yyyy - HH:mm:ss').format(timestamp),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              
                              // Sensor data grid
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDataColumn(
                                      'CO',
                                      '${data.coPpm.toStringAsFixed(2)} PPM',
                                      Icons.cloud,
                                      Colors.blue,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildDataColumn(
                                      'Dust',
                                      '${data.dustDensity.toStringAsFixed(2)} mg/m³',
                                      Icons.grain,
                                      Colors.brown,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDataColumn(
                                      'Temp',
                                      '${data.temperature.toStringAsFixed(1)}°C',
                                      Icons.thermostat,
                                      Colors.orange,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildDataColumn(
                                      'Humidity',
                                      '${data.humidity.toStringAsFixed(1)}%',
                                      Icons.water_drop,
                                      Colors.cyan,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, AQIStatus? status) {
    final isSelected = _selectedStatus == status;
    Color chipColor;
    
    if (status == null) {
      chipColor = Colors.grey;
    } else {
      chipColor = AQIUtils.getStatusColor(status);
    }

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedStatus = selected ? status : null;
        });
      },
      backgroundColor: chipColor.withOpacity(0.1),
      selectedColor: chipColor.withOpacity(0.3),
      checkmarkColor: chipColor,
      labelStyle: TextStyle(
        color: isSelected ? chipColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? chipColor : Colors.grey.shade400,
        width: isSelected ? 2 : 1,
      ),
    );
  }

  Widget _buildDataColumn(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
