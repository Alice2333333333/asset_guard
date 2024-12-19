import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:asset_guard/provider/asset_provider.dart';

class Usage extends StatefulWidget {
  const Usage({super.key});

  @override
  State<Usage> createState() => _UsageState();
}

class _UsageState extends State<Usage> {
  late String _assetId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final Map<String, dynamic>? arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    _assetId = arguments?['id'] ?? '';

    if (_assetId.isNotEmpty) {
      checkFlaskConnectionAndSendAssetId(_assetId);
    }
  }

  Future<void> checkFlaskConnectionAndSendAssetId(String assetId) async {
    try {
      final url = Uri.parse('http://192.168.100.10:5000/monitor-usage');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        await sendAssetIdToFlask(assetId);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> sendAssetIdToFlask(String assetId) async {
    final url = Uri.parse('http://192.168.100.10:5000/send-assetid');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'assetid': assetId}),
      );

      if (response.statusCode == 200) {
        print('Asset ID sent to Flask successfully');
      } else {
        print('Failed to send Asset ID to Flask');
      }
    } catch (e) {
      print('Error sending Asset ID to Flask: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AssetProvider assetProvider = AssetProvider();

    return Scaffold(
      appBar: AppBar(title: const Text('Usage Analysis')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: assetProvider.fetchMonitorData(_assetId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final data = snapshot.data ?? [];

            if (data.isEmpty) {
              return const Center(child: Text('No data available'));
            }

            // Prepare data for the bar chart
            final barGroups = data.map((item) {
              final String status = item['status'] ?? 'Unknown';
              final int countInSeconds = item['count'] ?? 0;
              final double timeInHours = countInSeconds / 3600;
              final int xValue = _statusToXValue(status);
              return BarChartGroupData(
                x: xValue,
                barRods: [
                  BarChartRodData(
                    toY: double.parse(timeInHours.toStringAsFixed(2)),
                    width: 20,
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList();

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(
                    height: 300,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxY(data),
                        barGroups: barGroups,
                        backgroundColor: Colors.grey[200], // Add background color
                        gridData: FlGridData(
                          show: true,
                          horizontalInterval: 1, // Adjust spacing of grid lines
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey[400],
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, _) {
                                return Text(
                                  '${value.toStringAsFixed(1)} h',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                final String label = _xValueToStatus(value.toInt());
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    label.isEmpty ? '' : label,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: const Border(
                            left: BorderSide(width: 1, color: Colors.black),
                            bottom: BorderSide(width: 1, color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: Text('No data available'));
          }
        },
      ),
    );
  }

  int _statusToXValue(String status) {
    switch (status) {
      case 'idle':
        return 1;
      case 'minor_vibration':
        return 2;
      case 'soft_concrete':
        return 3;
      case 'hard_concrete':
        return 4;
      default:
        return 0;
    }
  }

  // Helper function to map x value back to status
  String _xValueToStatus(int x) {
    switch (x) {
      case 1:
        return 'Idle';
      case 2:
        return 'Minor Vib';
      case 3:
        return 'Soft Con';
      case 4:
        return 'Hard Con';
      default:
        return '';
    }
  }

  // Helper function to calculate max Y value
  double _getMaxY(List<Map<String, dynamic>> data) {
    final double maxTimeInHours =
        data.map((item) => (item['count'] ?? 0) / 3600).reduce((a, b) => a > b ? a : b);
    return (maxTimeInHours + 1).toDouble(); // Add some padding
  }
}
