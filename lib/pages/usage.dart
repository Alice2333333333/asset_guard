import 'package:flutter/material.dart';
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
  double remainingUsage = 0.0;
  List<Map<String, dynamic>> processedData = [];
  DateTime? nextMaintenance;
  final AssetProvider assetProvider = AssetProvider();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final Map<String, dynamic>? arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    _assetId = arguments?['id'] ?? '';

    if (_assetId.isNotEmpty) {
      assetProvider.checkFlaskConnectionAndSendAssetId(_assetId);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              totalUsage = assetProvider.calculateTotalUsage(data);
              remainingUsage =
                  assetProvider.calculateRemainingUsage(totalUsage);

              assetProvider.storeTotalUsage(_assetId, totalUsage);
              assetProvider.storeRemainingUsage(_assetId, remainingUsage);
              nextMaintenance =
                  assetProvider.calculateNextMaintenance(remainingUsage, firstDate);
              assetProvider.storeNextMaintenance(_assetId, nextMaintenance);
            }

            final barGroups = processedData.map((item) {
              final String date = item['date'] ?? '';
              final num usageHours = item['usage_hours'] ?? 0.0;
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
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Remaining Usage: ${remainingUsage.toStringAsFixed(2)} hours',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Next Maintenance: ${nextMaintenance != null ? DateFormat('dd MMM yyyy').format(nextMaintenance!) : 'Not Available'}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
    final last7DaysStart = today.subtract(const Duration(days: 6));

    final filteredData = data.where((item) {
      final recordDate = DateTime.parse(item['date']);
      return recordDate
              .isAfter(last7DaysStart.subtract(const Duration(days: 1))) &&
          recordDate.isBefore(today.add(const Duration(days: 1)));
    }).toList();

    final List<DateTime> last7Days = List.generate(
      7,
      (index) => today.subtract(Duration(days: index)),
    );

    processedData = last7Days.map((date) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final record = filteredData.firstWhere(
        (item) => item['date'] == formattedDate,
        orElse: () => {'date': formattedDate, 'usage_hours': 0.0},
      );
      return record;
    }).toList();

    processedData.sort((a, b) => a['date'].compareTo(b['date']));
  }

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

  double _getMaxY(List<Map<String, dynamic>> data) {
    final num maxTimeInHours = data
        .map((item) => item['usage_hours'] ?? 0.0)
        .reduce((a, b) => a > b ? a : b);
    return (maxTimeInHours + 1).toDouble();
  }

  Color _getColorForDay(int day) {
    const colors = [
      Colors.red,
      Colors.orange,
      Colors.green,
      Colors.lightBlue,
      Colors.lightGreen,
      Colors.grey,
      Colors.black,
    ];
    return colors[day % colors.length];
  }
}
