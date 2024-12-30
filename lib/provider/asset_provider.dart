import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AssetProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _assets = [];
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> get assets => _assets;
  List<Map<String, dynamic>> get records => _records;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> fetchAssets() async {
    final CollectionReference assetCollection = _firestore.collection('asset');

    final QuerySnapshot assetSnapshot = await assetCollection.get();

    _assets = assetSnapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'name': doc['name'] ?? 'Unknown Asset',
        'serialNumber': doc['serial_number'] ?? 'N/A',
        'condition': doc['condition'] ?? 'N/A',
        'price': doc['price'] ?? 'N/A',
        'type': doc['type'] ?? 'N/A',
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

  DateTime calculateNextMaintenance(double remainingUsage) {
    final DateTime today = DateTime.now();
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

    return today.add(Duration(hours: hoursToAdd.toInt()));
  }

  Future<void> storeNextMaintenance(
      String assetId, DateTime maintenanceDate) async {
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
}
