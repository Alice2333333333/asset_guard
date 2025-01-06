import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AssetProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _assets = [];
  List<Map<String, dynamic>> get assets => _assets;

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

  Color getConditionColor(String condition) {
    if (condition == 'Good') {
      return Colors.green;
    } else if (condition == 'Needs Repair') {
      return Colors.red;
    } else {
      return Colors.blueAccent;
    }
  }
}
