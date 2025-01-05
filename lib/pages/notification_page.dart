import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asset_guard/provider/asset_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final assetProvider = Provider.of<AssetProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 144, 181, 212),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: assetProvider.fetchNotifications(),
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

              return Card(
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
                        "Date: ${assetProvider.formatNotificationDate(notification['date'])}",
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
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
                  onTap: () {
                    assetProvider.markNotificationAsRead(docId);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
