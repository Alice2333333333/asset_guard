import 'package:asset_guard/provider/maintenance_provider.dart';
import 'package:asset_guard/provider/usage_provider.dart';
import 'package:asset_guard/provider/asset_provider.dart';
import 'package:asset_guard/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
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
  DateTime? startDate;
  DateTime? nextMaintenance;
  final AssetProvider assetProvider = AssetProvider();
  final UsageProvider usageProvider = UsageProvider();
  final MaintenanceProvider maintenanceProvider = MaintenanceProvider();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final Map<String, dynamic>? arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.getUserDetailsFromPreferences();
    });

    _assetId = arguments?['id'] ?? '';

    if (_assetId.isNotEmpty) {
      assetProvider.checkFlaskConnectionAndSendAssetId(_assetId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Usage Analysis',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 144, 181, 212),
      ),
      body: FutureBuilder<DateTime?>(
        future: usageProvider.fetchStartDate(_assetId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            startDate = snapshot.data;
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: usageProvider.fetchMonitorData(_assetId),
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
                    totalUsage = usageProvider.calculateTotalUsage(data);
                    remainingUsage =
                        usageProvider.calculateRemainingUsage(totalUsage);

                    usageProvider.storeTotalUsage(_assetId, totalUsage);
                    usageProvider.storeRemainingUsage(_assetId, remainingUsage);
                    nextMaintenance = maintenanceProvider
                        .calculateNextMaintenance(remainingUsage, firstDate);
                    maintenanceProvider.storeNextMaintenance(
                        _assetId, nextMaintenance);
                  }

                  final barGroups = processedData.asMap().entries.map((entry) {
                    int index = entry.key;
                    final item = entry.value;
                    final num usageHours = item['usage_hours'] ?? 0.0;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: double.parse(usageHours.toStringAsFixed(2)),
                          width: 25,
                          color: _getColorForDay(index),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList();

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal:5.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Tool Usage in the Last 7 Days',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 400,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 5, 0),
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceEvenly,
                                maxY: _getMaxY(processedData),
                                barGroups: barGroups,
                                backgroundColor:
                                    const Color.fromARGB(255, 255, 255, 255),
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
                                      reservedSize: 50,
                                      getTitlesWidget: (value, _) {
                                        int index = value.toInt();
                                        if (index >= 0 &&
                                            index < processedData.length) {
                                          DateTime date = DateTime.parse(
                                              processedData[index]['date']);
                                          String formattedDate =
                                              DateFormat('d MMM yyyy')
                                                  .format(date);
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                top: 20.0),
                                            child: Transform.rotate(
                                              angle: -1,
                                              child: Text(
                                                formattedDate,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          );
                                        } else {
                                          return Container();
                                        }
                                      },
                                      interval: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          'Updated on ${DateFormat('d MMM yyyy, hh:mm a').format(DateTime.now())}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 255, 0, 0),
                          ),
                          textAlign: TextAlign.start,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Total used for ${totalUsage.toStringAsFixed(2)} hours since ${startDate != null ? DateFormat('d MMM yyyy').format(startDate!) : 'N/A'}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 25, 58, 94),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
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
                                  color: Color.fromARGB(255, 25, 58, 94),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (authProvider.userRole != 'Site Manager')
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
                    ),
                  );
                } else {
                  return const Center(child: Text('No data available'));
                }
              },
            );
          }
        },
      ),
    );
  }

  void _processDataForLast7Days(List<Map<String, dynamic>> data) {
    final today = DateTime.now();
    final List<DateTime> last7Days = List.generate(
      7,
      (index) => today.subtract(Duration(days: 6 - index)),
    );

    processedData = last7Days.map((date) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final record = data.firstWhere(
        (item) => item['date'] == formattedDate,
        orElse: () => {'date': formattedDate, 'usage_hours': 0.0},
      );
      return record;
    }).toList();
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
