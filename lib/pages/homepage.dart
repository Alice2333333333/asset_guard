import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asset_guard/provider/asset_provider.dart';
import 'package:intl/intl.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  void initState() {
    super.initState();
    Provider.of<AssetProvider>(context, listen: false).fetchAssets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 32,
            ),
            const SizedBox(width: 10),
            const Text(
              'AssetGuard',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 144, 181, 212),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.notifications),
            color: Colors.black,
            tooltip: 'Notification',
            onPressed: () {
              Navigator.pushNamed(context, '/notification');
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_rounded),
            color: Colors.black,
            tooltip: 'Profile',
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: Consumer<AssetProvider>(
        builder: (context, assetProvider, child) {
          final assets = assetProvider.assets;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  'Available Power Tools',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: assets.length,
                  itemBuilder: (context, index) {
                    final asset = assets[index];
                    final bool isConditionGood = asset['condition'] ?? false;
                    // print(isConditionGood);
                    final conditionColor = _getConditionColor(isConditionGood);
                    final conditionIcon =
                        isConditionGood ? Icons.check_circle : Icons.cancel;
                    final maintenanceDate = asset['next_maintenance'];
                    // print(maintenanceDate);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
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
                              child: const Icon(Icons.build,
                                  color: Colors.blueAccent),
                            ),
                            title: Text(
                              asset['name'] ?? 'Unknown Tool',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Serial Number: ${asset['serialNumber'] ?? 'N/A'}",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatMaintenanceDate(maintenanceDate),
                                  style: TextStyle(
                                    color: isConditionGood
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Icon(
                              conditionIcon,
                              color: conditionColor,
                            ),
                            onTap: () {
                              Navigator.pushNamed(context, '/asset',
                                  arguments: asset);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Color _getConditionColor(bool isConditionGood) {
  return isConditionGood ? Colors.green : Colors.red;
}

String _formatMaintenanceDate(String? maintenanceDate) {
  if (maintenanceDate == null ||
      maintenanceDate.isEmpty ||
      maintenanceDate == 'N/A') {
    return "Upcoming Maint.: Not Scheduled";
  }
  try {
    final formattedDate = DateFormat('dd MMM yyyy').format(
      DateTime.parse(maintenanceDate),
    );
    return "Upcoming Maint.: $formattedDate";
  } catch (e) {
    print("Date parsing error: $e for date: $maintenanceDate");
    return "Upcoming Maintenance: Invalid Date";
  }
}
