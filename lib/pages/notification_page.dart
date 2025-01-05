import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asset_guard/provider/asset_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

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
                          "Date: ${assetProvider.formatNotificationDate(notification['date'])}",
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
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
                                _sendRepairEmail(notification);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 25, 58, 94),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                assetProvider.markNotificationAsRead(docId);
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

void _sendRepairEmail(Map<String, dynamic> notification) async {
  const String email = 'alau26275@gmail.com';
  final String subject =
      Uri.encodeComponent('Repair Request: ${notification['title']}');
  final String body = Uri.encodeComponent(
    'Hello,\n\nI am requesting repair service for the following asset:\n\n'
    'Asset: ${notification['title']}\n'
    '${notification['body']}\n\n'
    'Please take the necessary action.\n\nThank you.',
  );

  final Uri mailUri = Uri(
    scheme: 'mailto',
    path: 'alau26275@gmail.com',
    query: 'subject=$subject&body=$body',
  );

  if (await canLaunchUrl(mailUri)) {
    await launchUrl(mailUri);
  } else {
    throw 'Could not launch email client';
  }
}
