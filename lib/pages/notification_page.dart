import 'package:asset_guard/provider/maintenance_provider.dart';
import 'package:asset_guard/provider/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    final maintenanceProvider =
        Provider.of<MaintenanceProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 144, 181, 212),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notificationProvider.fetchNotifications(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification =
                  notifications[index].data() as Map<String, dynamic>;
              final docId = notifications[index].id;
              final bool repairRequested =
                  notification['repairRequested'] ?? false;

              return Padding(
                padding: const EdgeInsets.fromLTRB(0, 5, 0, 3),
                child: Card(
                  elevation: 3,
                  child: ListTile(
                    title: Text(
                      notification['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification['body']),
                        const SizedBox(height: 4),
                        Text(
                          "Date: ${notificationProvider.formatNotificationDate(notification['date'])}",
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!repairRequested)
                              ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.build,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Repair',
                                  style: TextStyle(color: Colors.white),
                                ),
                                onPressed: () {
                                  maintenanceProvider.sendRepairEmail(
                                      context, notification, docId);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 25, 58, 94),
                                ),
                              ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                notificationProvider
                                    .markNotificationAsRead(docId);
                              },
                              child: const Text(
                                'Mark as Read',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Icon(
                      notification['status'] == 'unread'
                          ? Icons.mark_email_unread
                          : Icons.mark_email_read,
                      color: notification['status'] == 'unread'
                          ? Colors.orange
                          : Colors.green,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
