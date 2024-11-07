import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssetProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _assets = [];
  List<Map<String, dynamic>> get assets => _assets;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> fetchAssets() async {
    final CollectionReference assetCollection =
        _firestore.collection('asset');

    final QuerySnapshot assetSnapshot = await assetCollection.get();

    _assets = assetSnapshot.docs.map((doc) {
      return {
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
}