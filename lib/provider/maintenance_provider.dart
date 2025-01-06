import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MaintenanceProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> get records => _records;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String technicianName = 'Alex Kim';
  static const String repairEmail = 'alau26275@gmail.com';

  Future<void> fetchMaintenanceRecords(String assetId) async {
    final CollectionReference maintenanceCollection = _firestore
        .collection('asset')
        .doc(assetId)
        .collection('maintenanceRecords');

    final QuerySnapshot maintenanceSnapshot = await maintenanceCollection.get();

    _records = maintenanceSnapshot.docs.map((doc) {
      return {
        'date': doc['date'],
        'technician': doc['technician'],
        'duration': doc['duration'],
        'date_complete': doc['date_complete'],
        'cost': doc['cost'],
        'description': doc['description'],
        'status': doc['status'],
      };
    }).toList();

    _records.sort((a, b) => b['date'].compareTo(a['date']));

    notifyListeners();
  }

  DateTime calculateNextMaintenance(double remainingUsage, String firstDate) {
    DateTime startDate = DateTime.tryParse(firstDate) ?? DateTime.now();
    double hoursToAdd = 0;

    if (remainingUsage < 182.5) {
      hoursToAdd = 182.5;
    } else if (remainingUsage < 365) {
      hoursToAdd = 365;
    } else if (remainingUsage < 547.5) {
      hoursToAdd = 547.5;
    } else if (remainingUsage <= 730) {
      hoursToAdd = 730;
    }

    return startDate.add(Duration(hours: hoursToAdd.toInt()));
  }

  Future<void> storeNextMaintenance(
      String assetId, DateTime? maintenanceDate) async {
    if (maintenanceDate == null) {
      debugPrint('Maintenance date is null. Skipping storage.');
      return;
    }

    final docRef = FirebaseFirestore.instance.collection('asset').doc(assetId);

    try {
      await docRef.set({
        'next_maintenance': DateFormat('yyyy-MM-dd').format(maintenanceDate),
      }, SetOptions(merge: true));
      debugPrint('Next maintenance date stored: $maintenanceDate');
    } catch (e) {
      debugPrint('Failed to store next maintenance date: $e');
    }
  }


  Future<void> sendRepairEmail(
      BuildContext context, Map<String, dynamic> notification, String docId) async {
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
      _showEmailConfirmationDialog(context, notification, docId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not launch email client'),
        ),
      );
    }
  }

  void _showEmailConfirmationDialog(
      BuildContext context, Map<String, dynamic> notification, String docId) {
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

  Future<void> markRepairRequested(Map<String, dynamic> notification, String docId) async {
    final assetId = notification['assetId'];
    final DateTime now = DateTime.now();
    final String formattedToday = DateFormat('yyyy-MM-dd').format(now);
    final String dateComplete = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 7)));

    await _firestore
        .collection('notifications')
        .doc(docId)
        .update({'repairRequested': true});

    await _firestore
        .collection('asset')
        .doc(assetId)
        .update({'condition': 'In Repair'});

    await _firestore
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

    notifyListeners();
  }
}
