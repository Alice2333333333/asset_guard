import 'package:asset_guard/provider/asset_provider.dart';
import 'package:asset_guard/provider/notification_provider.dart';
import 'package:asset_guard/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    assetProvider.fetchAssets();
    notificationProvider.updateDailyUsage();
    notificationProvider.checkAndUpdateConditionFromNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.getUserDetailsFromPreferences();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
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
          if (authProvider.userRole != 'Site Manager')
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

          return Padding(
            padding: const EdgeInsets.all(2.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                      final asset =
                          assets[index].data() as Map<String, dynamic>;
                      final condition = asset['condition'];
                      final maintenanceDate =
                          DateTime.tryParse(asset['next_maintenance'] ?? '');
                      final conditionColor =
                          Provider.of<AssetProvider>(context, listen: false)
                              .getConditionColor(condition);

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
                                    "Serial Number: ${asset['serial_number'] ?? 'N/A'}",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (authProvider.userRole != 'Site Manager')
                                    Text(
                                      "Next Maintenance: ${_formatDate(maintenanceDate)}",
                                      style: TextStyle(
                                        color: conditionColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: _getConditionIcon(condition),
                              onTap: () {
                                final assetId = assets[index].id;
                                final asset = assets[index].data()
                                    as Map<String, dynamic>;
                                asset['id'] = assetId;
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
            ),
          );
        },
      ),
    );
  }
}

Icon _getConditionIcon(String condition) {
  switch (condition) {
    case 'Good':
      return const Icon(Icons.check_circle, color: Colors.green);
    case 'Needs Repair':
      return const Icon(Icons.cancel, color: Colors.red);
    case 'In Repair':
      return const Icon(Icons.build, color: Colors.blueAccent);
    default:
      return const Icon(Icons.help_outline, color: Colors.grey);
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Not Scheduled';
  return DateFormat('dd MMM yyyy').format(date);
}
