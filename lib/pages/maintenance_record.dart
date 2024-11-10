import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asset_guard/provider/asset_provider.dart';
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
        future: Provider.of<AssetProvider>(context, listen: false)
            .fetchMaintenanceRecords(assetId),
        builder: (context, snapshot) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Maintenance Records'),
            ),
            body: Consumer<AssetProvider>(
              builder: (context, assetProvider, child) {
                final records = assetProvider.records;

                if (records.isEmpty) {
                  return const Center(
                      child: Text("No maintenance records found"));
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

                    String formattedCompletedDate = record['date_complete'] is Timestamp
                        ? DateFormat('yyyy-MM-dd')
                            .format(record['date_complete'].toDate())
                        : record['date_complete'].toString();
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      elevation: 3,
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child:
                              const Icon(Icons.home_repair_service_rounded, color: Colors.blueAccent),
                        ),
                        title: Text(
                          formattedDate,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Technician: ${record['technician']}"),
                            Text("Duration: ${record['duration']} days"),
                            Text(
                                "Expected Completion: $formattedCompletedDate"),
                            Text("Cost: RM ${record['cost']}"),
                            Text("Description: ${record['description']}"),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                );
              },
            ),
          );
        }
        );
  }
}