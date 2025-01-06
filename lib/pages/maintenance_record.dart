import 'package:asset_guard/provider/maintenance_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceRecord extends StatelessWidget {
  const MaintenanceRecord({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> asset =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

    final String assetId = asset['id'];

    return FutureBuilder(
        future: Provider.of<MaintenanceProvider>(context, listen: false)
            .fetchMaintenanceRecords(assetId),
        builder: (context, snapshot) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Maintenance Records',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: const Color.fromARGB(255, 144, 181, 212),
            ),
            body: Consumer<MaintenanceProvider>(
              builder: (context, maintenanceProvider, child) {
                final records = maintenanceProvider.records;

                if (records.isEmpty) {
                  return const Center(
                      child: Text(
                    "No maintenance records found",
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];

                    String formattedDate = record['date'] is Timestamp
                        ? DateFormat('yyyy-MM-dd')
                            .format(record['date'].toDate())
                        : record['date'].toString();

                    String formattedCompletedDate =
                        record['date_complete'] is Timestamp
                            ? DateFormat('yyyy-MM-dd')
                                .format(record['date_complete'].toDate())
                            : record['date_complete'].toString();

                    bool isCompleted = record['status'] == 'completed';
                    Color borderColor =
                        isCompleted ? Colors.green : Colors.blue;
                    IconData statusIcon = isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.handyman;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: borderColor.withOpacity(0.6),
                          width: 1.5,
                        ),
                        color: borderColor.withOpacity(0.05),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.home_repair_service_rounded,
                                      color: Colors.blueAccent, size: 30),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        isCompleted ? 'Completed' : 'In Repair',
                                        style: TextStyle(
                                          color: borderColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Icon(
                                statusIcon,
                                color: borderColor,
                                size: 28,
                              ),
                            ],
                          ),
                          const Divider(height: 24, thickness: 1),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                              Icons.person, "Technician", record['technician']),
                          _buildDetailRow(Icons.timelapse, "Duration",
                              "${record['duration']} days"),
                          _buildDetailRow(Icons.date_range,
                              "Expected Completion", formattedCompletedDate),
                          _buildDetailRow(Icons.attach_money, "Cost",
                              "RM ${record['cost']}"),
                          _buildDetailRow(Icons.description, "Description",
                              record['description'] ?? "No description"),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                );
              },
            ),
          );
        });
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey, size: 22),
          const SizedBox(width: 12),
          Text(
            "$label: ",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
