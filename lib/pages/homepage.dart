import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);
    assetProvider.fetchAssets();
    assetProvider.updateDailyUsage();
    assetProvider.checkAndUpdateConditionFromNotifications();
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
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('status', isEqualTo: 'unread')
                .snapshots(),
            builder: (context, snapshot) {
              bool hasUnreadNotifications = false;
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                hasUnreadNotifications = true;
              }
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    color: Colors.black,
                    tooltip: 'Notification',
                    onPressed: () {
                      Navigator.pushNamed(context, '/notification');
                    },
                  ),
                  if (hasUnreadNotifications)
                    Positioned(
                      right: 11,
                      top: 11,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 10,
                          minHeight: 10,
                        ),
                      ),
                    ),
                ],
              );
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('asset').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No assets available.'));
          }

          final assets = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(12.0),
            itemCount: assets.length,
            itemBuilder: (context, index) {
              final asset = assets[index].data() as Map<String, dynamic>;
              final bool isConditionGood = asset['condition'] ?? true;
              final maintenanceDate =
                  DateTime.tryParse(asset['next_maintenance'] ?? '');

              final conditionColor = _getConditionColor(isConditionGood);
              final conditionIcon =
                  isConditionGood ? Icons.check_circle : Icons.cancel;

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
                        child:
                            const Icon(Icons.build, color: Colors.blueAccent),
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
                            "Serial Number: ${asset['serial_number'] ?? 'N/A'}",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Next Maintenance: ${_formatDate(maintenanceDate)}",
                            style: TextStyle(
                              color:
                                  isConditionGood ? Colors.green : Colors.red,
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
            separatorBuilder: (context, index) => const SizedBox(height: 8),
          );
        },
      ),
    );
  }
}

Color _getConditionColor(bool isConditionGood) {
  return isConditionGood ? Colors.green : Colors.red;
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Not Scheduled';
  return DateFormat('dd MMM yyyy').format(date);
}
