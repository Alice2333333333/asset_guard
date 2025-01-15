import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UsageProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Future<DateTime?> fetchStartDate(String assetId) {
    return _firestore
        .collection('asset')
        .doc(assetId)
        .collection('usage_data')
        .orderBy(FieldPath
            .documentId)
        .limit(1)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        final dateString = querySnapshot.docs.first.id;
        return DateTime.tryParse(dateString);
      }
      return null;
    }).catchError((e) {
      debugPrint('Failed to fetch earliest date: $e');
      return null;
    });
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
}
