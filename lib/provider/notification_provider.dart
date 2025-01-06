import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        'condition': 'Needs Repair',
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
        'repairRequested': false,
      });
      debugPrint("Notification (Type $type) stored for Asset: $assetId");
    } else {
      debugPrint(
          "Notification already exists for Asset: $assetId (Type $type)");
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

  String formatNotificationDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd MMM yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }
}
