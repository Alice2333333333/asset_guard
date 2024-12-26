import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:asset_guard/provider/asset_provider.dart';
import 'package:intl/intl.dart';

class Usage extends StatefulWidget {
  const Usage({super.key});

  @override
  State<Usage> createState() => _UsageState();
}

class _UsageState extends State<Usage> {
  late String _assetId;
  String monthYearLabel = '';
  double totalUsage = 0.0;
  List<Map<String, dynamic>> processedData = [];

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
            _processDataForLast7Days(data);

            if (data.isEmpty) {
              return const Center(child: Text('No data available'));
            }

            if (data.isNotEmpty) {
              final firstDate = data.first['date'] ?? '';
              monthYearLabel = _extractMonthYear(firstDate);
              totalUsage = _calculateTotalUsage(data);
            }

            // Prepare bar chart data
            final barGroups = data.map((item) {
              final String date = item['date'] ?? '';
              final double usageHours = item['usage_hours'] ?? 0.0;
              final int day = _dayFromDate(date);

              return BarChartGroupData(
                x: day,
                barRods: [
                  BarChartRodData(
                    toY: double.parse(usageHours.toStringAsFixed(2)),
                    width: 25,
                    color: _getColorForDay(day),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList();

            return Column(
              children: [
                SizedBox(
                  height: 400,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceEvenly,
                        maxY: _getMaxY(processedData),
                        barGroups: barGroups,
                        // backgroundColor:
                        //     const Color.fromARGB(255, 255, 255, 255),
                        gridData: FlGridData(
                          show: true,
                          horizontalInterval: 1,
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
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(fontSize: 12),
                                );
                              },
                              reservedSize: 30,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Usage for $monthYearLabel',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Total Usage: ${totalUsage.toStringAsFixed(2)} hours',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: Text('No data available'));
          }
        },
      ),
    );
  }

  void _processDataForLast7Days(List<Map<String, dynamic>> data) {
    final today = DateTime.now();
    final List<DateTime> last7Days = List.generate(
      7,
      (index) => today.subtract(Duration(days: index)),
    );

    processedData = last7Days.map((date) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final record = data.firstWhere(
        (item) => item['date'] == formattedDate,
        orElse: () => {'date': formattedDate, 'usage_hours': 0.0},
      );
      return record;
    }).toList();

    processedData.sort((a, b) => a['date'].compareTo(b['date']));
  }

// Extract day from date
  int _dayFromDate(String date) {
    return int.tryParse(date.split('-').last) ?? 0;
  }

  String _extractMonthYear(String date) {
    DateTime parsedDate = DateTime.parse(date);
    String month = _monthName(parsedDate.month);
    return '$month ${parsedDate.year}';
  }

  String _monthName(int month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return monthNames[month - 1];
  }

  double _calculateTotalUsage(List<Map<String, dynamic>> data) {
    return data.fold(0.0, (sum, item) => sum + (item['usage_hours'] ?? 0.0));
  }

  double _getMaxY(List<Map<String, dynamic>> data) {
    final double maxTimeInHours = data
        .map((item) => item['usage_hours'] ?? 0.0)
        .reduce((a, b) => a > b ? a : b);
    return (maxTimeInHours + 1).toDouble();
  }

  Color _getColorForDay(int day) {
    const colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.yellow,
    ];
    return colors[day % colors.length];
  }
}
