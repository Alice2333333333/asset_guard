import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AssetProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _assets = [];
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get assets => _assets;
  List<Map<String, dynamic>> get records => _records;
  List<Map<String, dynamic>> get notifications => _notifications;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> fetchAssets() async {
    final CollectionReference assetCollection = _firestore.collection('asset');

    final QuerySnapshot assetSnapshot = await assetCollection.get();

    _assets = assetSnapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'name': doc['name'] ?? 'Unknown Asset',
        'serial_number': doc['serial_number'] ?? 'N/A',
        'condition': doc['condition'] ?? 'N/A',
        'description': doc['description'] ?? 'N/A',
        'price': doc['price'] ?? 'N/A',
        'type': doc['type'] ?? 'N/A',
        'next_maintenance': doc['next_maintenance'],
      };
    }).toList();

    _assets.sort((a, b) => a['name'].compareTo(b['name']));

    notifyListeners();
  }

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

  Stream<List<Map<String, dynamic>>> fetchMonitorData(String assetId) {
    return _firestore
        .collection('asset')
        .doc(assetId)
        .collection('usage_data')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return {
                'date': doc.id,
                'usage_hours': doc['usage_hours'],
              };
            }).toList());
  }

  Future<void> updateDailyUsage() async {
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final QuerySnapshot assetSnapshot =
        await _firestore.collection('asset').get();

    for (var doc in assetSnapshot.docs) {
      final asset = doc.data() as Map<String, dynamic>;
      final assetId = doc.id;

      final usageDoc = await _firestore
          .collection('asset')
          .doc(assetId)
          .collection('usage_data')
          .doc(today)
          .get();

      num dailyUsage = usageDoc.exists ? (usageDoc['usage_hours'] ?? 0) : 0;
      DateTime? maintenanceDate = DateTime.tryParse(asset['next_maintenance']);

      checkNotifications(asset, maintenanceDate, dailyUsage, assetId);

      await _firestore.collection('asset').doc(assetId).set({
        'daily_usage': dailyUsage,
      }, SetOptions(merge: true));
    }

    notifyListeners();
  }

  void checkNotifications(Map<String, dynamic> asset, DateTime? maintenanceDate,
      num dailyUsage, String assetId) {
    if (dailyUsage >= 20) {
      _storeNotificationIfNotExists(
        assetId,
        asset['name'],
        "Critical Limit",
        "Daily usage exceeded 20 hours.",
        1,
      );
    }

    if (maintenanceDate != null && _isTodayOrBefore(maintenanceDate)) {
      _storeNotificationIfNotExists(
        assetId,
        asset['name'],
        "Maintenance Due",
        "Maintenance is scheduled for today or overdue.",
        2,
      );
    }

    if (maintenanceDate != null && _isTomorrow(maintenanceDate)) {
      _storeNotificationIfNotExists(
        assetId,
        asset['name'],
        "Upcoming Maintenance",
        "Maintenance is scheduled for tomorrow.",
        3,
      );
    }
  }

  Future<void> checkAndUpdateConditionFromNotifications() async {
    final querySnapshot = await _firestore
        .collection('notifications')
        .where('type', whereIn: [1, 2]).get();

    for (var doc in querySnapshot.docs) {
      final assetId = doc['assetId'];
      await _firestore.collection('asset').doc(assetId).update({
        'condition': false,
      });
      debugPrint('Condition updated to false for asset: $assetId');
    }
  }

  Future<void> _storeNotificationIfNotExists(
      String assetId, String name, String title, String body, int type) async {
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd').format(now);

    final QuerySnapshot existingNotification = await _firestore
        .collection('notifications')
        .where('assetId', isEqualTo: assetId)
        .where('date', isEqualTo: formattedDate)
        .where('type', isEqualTo: type)
        .get();

    if (existingNotification.docs.isEmpty) {
      await _firestore.collection('notifications').add({
        'title': title,
        'body': "Tool: $name - $body",
        'date': formattedDate,
        'assetId': assetId,
        'status': 'unread',
        'type': type,
      });
      debugPrint("Notification (Type $type) stored for Asset: $assetId");
    } else {
      debugPrint(
          "Notification already exists for Asset: $assetId (Type $type)");
    }
  }

  bool _isTodayOrBefore(DateTime date) {
    final now = DateTime.now();
    return date.isBefore(now) ||
        DateFormat('yyyy-MM-dd').format(date) ==
            DateFormat('yyyy-MM-dd').format(now);
  }

  bool _isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(tomorrow);
  }

  Future<void> sendAssetIdToFlask(String assetId) async {
    final url = Uri.parse('http://192.168.100.10:5000/send-assetid');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'assetid': assetId}),
      );

      if (response.statusCode == 200) {
        debugPrint('Asset ID sent to Flask successfully');
      } else {
        debugPrint('Failed to send Asset ID to Flask');
      }
    } catch (e) {
      debugPrint('Error sending Asset ID to Flask: $e');
    }
  }

  Future<void> checkFlaskConnectionAndSendAssetId(String assetId) async {
    try {
      final url = Uri.parse('http://192.168.100.10:5000/monitor-usage');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        await sendAssetIdToFlask(assetId);
      }
    } catch (e) {
      debugPrint('Error is $e');
    }
  }

  double calculateTotalUsage(List<Map<String, dynamic>> data) {
    return data.fold(0.0, (sum, item) => sum + (item['usage_hours'] ?? 0.0));
  }

  double calculateRemainingUsage(double totalUsage) {
    double usageCycle = 730;
    return usageCycle - totalUsage;
  }

  Future<void> storeTotalUsage(String assetId, double totalUsage) async {
    final docRef = FirebaseFirestore.instance.collection('asset').doc(assetId);

    try {
      await docRef.set({
        'total_usage': totalUsage,
      }, SetOptions(merge: true));
      debugPrint('Total Usage stored: $totalUsage');
    } catch (e) {
      debugPrint('Failed to store total usage: $e');
    }
  }

  Future<void> storeRemainingUsage(
      String assetId, double remainingUsage) async {
    final docRef = _firestore.collection('asset').doc(assetId);

    try {
      await docRef.set({
        'remaining_usage': remainingUsage,
      }, SetOptions(merge: true));
      debugPrint('Remaining Usage stored: $remainingUsage');
    } catch (e) {
      debugPrint('Failed to store remaining usage: $e');
    }
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

  Stream<QuerySnapshot> fetchNotifications() {
    return _firestore
        .collection('notifications')
        .orderBy('date', descending: true)
        .snapshots();
  }

  Future<void> markNotificationAsRead(String docId) async {
    await _firestore
        .collection('notifications')
        .doc(docId)
        .update({'status': 'read'});
    notifyListeners();
  }

  String formatNotificationDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd MMM yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }
}
