import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.now();
    final formattedDate =
        DateFormat('yyyy-MM-dd – kk:mm').format(date); // Format the date

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification'),
      ),
      body: Text('The date is $formattedDate'),
    );
  }
}
