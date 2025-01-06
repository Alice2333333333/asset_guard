import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class RepairService {
  static const String technicianName = 'Alex Kim';
  static const String repairEmail = 'alau26275@gmail.com';

  static Future<void> sendRepairEmail(BuildContext context, Map<String, dynamic> notification, String docId) async {
    final String subject = Uri.encodeComponent('Repair Request: ${notification['title']}');
    final String body = Uri.encodeComponent(
      'Hello,\n\nI am requesting repair service for the following asset:\n\n'
      'Asset: ${notification['title']}\n'
      '${notification['body']}\n\n'
      'Please take the necessary action.\n\nThank you.',
    );

    final Uri mailUri = Uri(
      scheme: 'mailto',
      path: repairEmail,
      query: 'subject=$subject&body=$body',
    );

    if (await canLaunchUrl(mailUri)) {
      await launchUrl(mailUri);
      showEmailConfirmationDialog(context, notification, docId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch email client'),
        ),
      );
    }
  }

  static void showEmailConfirmationDialog(BuildContext context, Map<String, dynamic> notification, String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Email Confirmation'),
          content: const Text('Did you send the repair request email?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                markRepairRequested(notification, docId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Repair request marked.'),
                  ),
                );
              },
              child: const Text('Yes, I Sent', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  static Future<void> markRepairRequested(Map<String, dynamic> notification, String docId) async {
    final assetId = notification['assetId'];
    final DateTime now = DateTime.now();
    final String formattedToday = DateFormat('yyyy-MM-dd').format(now);
    final String dateComplete = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 7)));

    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .update({'repairRequested': true});

    await FirebaseFirestore.instance
        .collection('asset')
        .doc(assetId)
        .update({'condition': 'In Repair'});

    await FirebaseFirestore.instance
        .collection('asset')
        .doc(assetId)
        .collection('maintenanceRecords')
        .add({
      'date': formattedToday,
      'date_complete': dateComplete,
      'cost': '0',
      'description': '${notification['title']} - ${notification['body']}',
      'duration': '7',
      'status': 'in_repair',
      'technician': technicianName,
    });
  }
}
