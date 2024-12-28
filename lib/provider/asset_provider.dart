import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
}
